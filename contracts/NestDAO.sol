// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "./interface/INestDAO.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev The contract is for redeeming nest token and getting ETH in return
contract NestDAO is INestDAO {

    using SafeMath for uint;
    
    struct Ledger {
        uint128 rewardedAmount;
        uint128 redeemedAmount;
        uint128 quotaAmount;
        uint32  lastBlock;
        uint96  _reserved;
    }

    address immutable C_NestToken;

    /// @dev Mapping from ntoken => amount (of ntokens owned by DAO)
    mapping(address => Ledger) public ntokenLedger;

    /// @dev Mapping from ntoken => amount (of ethers owned by DAO)
    mapping(address => uint256) public ethLedger;

    constructor(address NestToken) public {
        C_NestToken = NestToken;
    }

    /// @notice Pump eth rewards to NestDAO for repurchasing `ntoken`
    /// @param ntoken The address of ntoken in the ether Ledger
    function addETHReward(address ntoken) 
        override
        external
        payable
    {
        // 给ntoken的分红池增加eth
        ethLedger[ntoken] = ethLedger[ntoken].add(msg.value);
    }

    /// @dev Called by NestMining
    function addNestReward(uint256 amount) 
        override 
        external 
    {
        // nest的出矿量分5%给nestdao

        // 找到nest的账本
        Ledger storage it = ntokenLedger[C_NestToken];
        // nest的账本增加
        it.rewardedAmount = uint128(uint256(it.rewardedAmount).add(amount));
    }
}