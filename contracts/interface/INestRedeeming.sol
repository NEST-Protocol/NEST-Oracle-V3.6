// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev The contract is for redeeming nest token and getting ETH in return
interface INestRedeeming {

    /// @dev 配置结构体
    struct Config {
        // // 开通ntoken需要支付的nest数量。10000 ether
        // uint96 openFeeNestAmount;
        // // ntoken管理功能启用状态。0：未启用，1：已启用
        // uint8 state;
        uint _unused;
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
    /// @param amount  The amount of ntoken
    function redeem(address ntokenAddress, uint amount) external payable;

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) external view returns (uint);
}