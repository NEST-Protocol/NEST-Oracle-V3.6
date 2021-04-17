// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "./lib/TransferHelper.sol";
import "./interface/INestGovernance.sol";
import "./interface/INestLedger.sol";

/// @dev Base contract of nest
contract NestBase {

    // TODO: Define NEST_TOKEN_ADDRESS as variable is for testing, it should be constant for mainnet 
    // Address of nest token contract
    //address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    address NEST_TOKEN_ADDRESS;

    // TODO: Define NEST_GENESIS_BLOCK 0 is for testing, it should be 6236588 for mainnet 
    // Genesis block number of nest
    //uint constant NEST_GENESIS_BLOCK = 6236588;
    uint constant NEST_GENESIS_BLOCK = 0;

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    // TODO: This method is for testing, it should be deleted for mainnet
    /// @return adm The admin slot.
    function getAdmin() external view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    /// @dev To support open-zeppelin/upgrades
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function initialize(address nestGovernanceAddress) virtual public {
        require(_governance == address(0), 'NEST:!initialize');
        _governance = nestGovernanceAddress;
    }

    /// @dev INestGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function update(address nestGovernanceAddress) virtual public {

        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _governance = nestGovernanceAddress;
    
        // TODO: This is for testing, it should be deleted for mainnet
        NEST_TOKEN_ADDRESS = INestGovernance(nestGovernanceAddress).getNestTokenAddress();
    }

    /// @dev Migrate funds from current contract to NestLedger
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = INestGovernance(_governance).getNestLedgerAddress();
        if (tokenAddress == address(0)) {
            INestLedger(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(INestGovernance(_governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "NEST:!contract");
        _;
    }
}