// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../lib/TransferHelper.sol";
import "../interface/IVotePropose.sol";
import "../interface/INestMapping.sol";
import "../interface/INestPriceFacade.sol";

/// @dev 测试通过投票修改价格调用参数配置
contract SetQueryPrice is IVotePropose {

    address _nestMappingAddress;

    constructor(address nestMappingAddress) {
        _nestMappingAddress = nestMappingAddress;
    }

    /// @dev 投票通过后需要执行的代码
    function run() override external {

        // /// @dev Set the built-in contract address of the system
        // /// @return nestTokenAddress Address of nest token contract
        // /// @return nestNodeAddress Address of nest node contract
        // /// @return nestLedgerAddress INestLedger implemention contract address
        // /// @return nestMiningAddress INestMining implemention contract address for nest
        // /// @return ntokenMiningAddress INestMining implemention contract address for ntoken
        // /// @return nestPriceFacadeAddress INestPriceFacade implemention contract address
        // /// @return nestVoteAddress INestVote implemention contract address
        // /// @return nestQueryAddress INestQuery implemention contract address
        // /// @return nnIncomeAddress NNIncome contract address
        // /// @return nTokenControllerAddress INTokenController implemention contract address
        // (
        //     , //address nestTokenAddress,
        //     , //address nestNodeAddress,
        //     , //address nestLedgerAddress,
        //     , //address nestMiningAddress,
        //     , //address ntokenMiningAddress,
        //     address nestPriceFacadeAddress,
        //     , //address nestVoteAddress,
        //     , //address nestQueryAddress,
        //     , //address nnIncomeAddress,
        //       //address nTokenControllerAddress
        // ) = INestMapping(_nestMappingAddress).getBuiltinAddress();

        address nestPriceFacadeAddress = INestMapping(_nestMappingAddress).getNestPriceFacadeAddress();

        INestPriceFacade(nestPriceFacadeAddress).setConfig(INestPriceFacade.Config(
            // 单轨询价费用。0.01ether
            uint16(200),
            // 双轨询价费用。0.01ether
            uint16(400),
            // 调用地址的正常状态标记。0
            uint8(0)
        ));
    }
}