// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./lib/IERC20.sol";
import "./NestBase.sol";

/// @dev NestNode mining contract
contract NNIncome is NestBase {

    constructor(address nestNodeAddress, address nestTokenAddress, uint nestGenesisBlock) {
        
        NEST_NODE_ADDRESS = nestNodeAddress;
        NEST_TOKEN_ADDRESS = nestTokenAddress;
        NEST_GENESIS_BLOCK = nestGenesisBlock;

        _latestBlock = block.number;
    }

    // Total supply of nest node
    uint constant NEST_NODE_TOTALSUPPLY = 1500;

    // Address of nest node contract
    address immutable NEST_NODE_ADDRESS;

    // Address of nest token contract
    address immutable NEST_TOKEN_ADDRESS;

    // Genesis block number of nest
    uint immutable NEST_GENESIS_BLOCK;// = 6236588;

    // Generated nest
    uint public _generatedNest;
    
    // Latest block number of operationed
    uint public _latestBlock;

    // Personal ledger
    mapping(address=>uint) _infoMapping;

    //---------transaction---------

    /// @dev Nest node transfer settlement. This method is triggered during nest node transfer and must be called by nest node contract
    /// @param from Transfer from address
    /// @param to Transfer to address
    function nodeCount(address from, address to) public  {
        settlement(from, to);
    }

    /// @dev Nest node transfer settlement. This method is triggered during nest node transfer and must be called by nest node contract
    /// @param from Transfer from address
    /// @param to Transfer to address
    function settlement(address from, address to) public {

        require(msg.sender == NEST_NODE_ADDRESS, "NNIncome:!nestNode");
        
        // Check balance
        IERC20 nn = IERC20(NEST_NODE_ADDRESS);
        uint balanceFrom = nn.balanceOf(address(from));
        require(balanceFrom > 0, "NNIncome:!balance");

        // Calculation of ore drawing increment
        uint nestAmount = miningNest();
        uint generatedNest = _generatedNest = _generatedNest + nestAmount;

        mapping(address=>uint) storage infoMapping = _infoMapping;
        // Calculation mining amount for (from)
        uint subAmountFrom = generatedNest - infoMapping[address(from)];
        uint thisAmountFrom = subAmountFrom * balanceFrom / NEST_NODE_TOTALSUPPLY;

        if (thisAmountFrom > 0) {
            require(IERC20(NEST_TOKEN_ADDRESS).transfer(address(from), thisAmountFrom), "NNIncome:!transfer from");
        }
        infoMapping[address(from)] = generatedNest;

        // Calculation mining amount for (to)
        uint balanceTo = nn.balanceOf(address(to));
        if (balanceTo > 0) {
            uint subAmountTo = generatedNest - infoMapping[address(to)];
            uint thisAmountTo = subAmountTo * balanceTo / NEST_NODE_TOTALSUPPLY;
            if (thisAmountTo > 0) {
                require(IERC20(NEST_TOKEN_ADDRESS).transfer(address(to), thisAmountTo), "NNIncome:!transfer to");
            }
        }
        infoMapping[address(to)] = generatedNest;

        // Update latest block number of operationed
        _latestBlock = block.number;
    }

    function getLatestBlock() public view returns (uint) {
        return _latestBlock;
    }

    /// @dev Draw nest
    function claimNest() public noContract {
        
        // Check balance
        IERC20 nn = IERC20(NEST_NODE_ADDRESS);
        uint balance = nn.balanceOf(address(tx.origin));
        require(balance > 0, "NNIncome:!balance");

        // Trigger
        uint nestAmount = miningNest();
        _generatedNest = _generatedNest + nestAmount;

        // Calculation for current mining
        uint subAmount = _generatedNest - _infoMapping[address(tx.origin)];
        uint thisAmount = subAmount * balance / NEST_NODE_TOTALSUPPLY;

        _infoMapping[address(tx.origin)] = _generatedNest;
        // Update latest block number of operationed
        _latestBlock = block.number;

        require(IERC20(NEST_TOKEN_ADDRESS).transfer(address(tx.origin), thisAmount), "NNIncome:!transfer");
    }

    //---------view----------------

    /// @dev Calculation of ore drawing increment
    /// @return Ore drawing increment
    function miningNest() public view returns(uint) {
        return _redution(block.number - NEST_GENESIS_BLOCK) * (block.number - _latestBlock) * 15 ether / 100;
    }

    /// @dev Query the current available nest
    /// @param owner Destination address
    /// @return Number of nest currently available
    function earnedNest(address owner) public view returns(uint) {

        uint totalNest = _generatedNest + miningNest();
        uint balance = IERC20(NEST_NODE_ADDRESS).balanceOf(address(owner));
        return (totalNest - _infoMapping[owner]) * balance / NEST_NODE_TOTALSUPPLY;
    }

    // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 2400000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 24 million blocks, about 10 years
    uint constant NEST_REDUCTION_LIMIT = 24000000; // NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300a300cc010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));

    // Calculation of attenuation gradient
    function _redution(uint delta) private pure returns (uint) {
        
        if (delta < NEST_REDUCTION_LIMIT) {
            return (NEST_REDUCTION_STEPS >> ((delta / NEST_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (NEST_REDUCTION_STEPS >> 160) & 0xFFFF;
    }
}