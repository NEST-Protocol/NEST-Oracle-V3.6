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

        /// @dev 获取系统内置的合约地址
        /// @return nestTokenAddress nest代币合约地址
        /// @return nestNodeAddress nest node合约地址
        /// @return nestLedgerAddress nest账本合约
        /// @return nestMiningAddress 挖矿合约地址
        /// @return nestPriceFacadeAddress 价格调用入口合约地址
        /// @return nestVoteAddress 投票合约地址
        /// @return nestQueryAddress 提供价格的合约地址
        /// @return nnIncomeAddress NN挖矿合约
        /// @return nTokenControllerAddress nToken管理合约地址
        (
            , //address nestTokenAddress,
            , //address nestNodeAddress,
            , //address nestLedgerAddress,
            , //address nestMiningAddress,
            address nestPriceFacadeAddress,
            , //address nestVoteAddress,
            , //address nestQueryAddress,
            , //address nnIncomeAddress,
              //address nTokenControllerAddress
        ) = INestMapping(_nestMappingAddress).getBuiltinAddress();

        INestPriceFacade(nestPriceFacadeAddress).setConfig(INestPriceFacade.Config(
            // 单轨询价费用。0.01ether
            uint96(0.02 ether),
            // 双轨询价费用。0.01ether
            uint96(0.04 ether),
            // 调用地址的正常状态标记。0
            uint8(0)
        ));
    }
}