// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev The contract is for redeeming nest token and getting ETH in return
interface INestRedeeming {

    /// @dev 回购配置结构体
    struct Config {

        // 单轨询价费用。0.01ether
        // 调用价格改为在NestPriceFacade里面确定。需要考虑退回的情况
        //uint96 fee;

        // 激活回购阈值，当ntoken的发行量超过此阈值时，激活回购（单位：10000 ether）。500
        uint32 activeThreshold;

        // 每区块回购nest数量。1000
        uint16 nestPerBlock;

        // 单次回购nest数量上限。300000
        uint32 nestLimit;

        // 每区块回购ntoken数量。10
        uint16 ntokenPerBlock;

        // 单次回购ntoken数量上限。3000
        uint32 ntokenLimit;

        // 价格偏差上限，超过此上限停止回购（万分制）。500
        uint16 priceDeviationLimit;
    }

    /// @dev 修改配置
    /// @param config 配置结构体
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() external view returns (Config memory);

    /// @dev Redeem ntokens for ethers
    /// @notice Ethfee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount The amount of ntoken
    function redeem(address ntokenAddress, uint amount) external payable;

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) external view returns (uint);
}