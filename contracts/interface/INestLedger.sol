// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev NEST 账本合约
interface INestLedger {

    /// @dev 配置结构体
    struct Config {
        // NEST分成（万分制）。2000
        uint32 nestRewardScale;
        // NTOKEN分成（万分制）。8000
        uint32 ntokenRedardScale;
    }
    
    /// @dev 修改配置
    /// @param config 配置结构体
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() external view returns (Config memory);

    /// @dev 设置DAO应用
    /// @param addr DAO应用地址
    /// @param flag 授权标记，1表示授权，0表示取消授权
    function setApplication(address addr, uint flag) external;

    /// @dev ntoken收益
    /// @param ntokenAddress ntoken地址
    function addReward(address ntokenAddress) external payable;

    /// @dev 收益分成
    /// @param ntokenAddress ntoken地址
    function carveReward(address ntokenAddress) external payable;

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The notoken address
    function totalRewards(address ntokenAddress) external view returns (uint);

    /// @dev 支付资金
    /// @param from 指定从哪个ntoken的账本支出
    /// @param tokenAddress 目标token地址（0表示eth）
    /// @param to 转入地址
    /// @param value 转账金额
    function pay(address from, address tokenAddress, address to, uint value) external;
}