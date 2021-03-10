// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface INTokenController {
    
    /// @notice when the auction of a token gets started
    /// @param token    The address of the (ERC20) token
    /// @param ntoken   The address of the ntoken w.r.t. token for incentives
    /// @param owner    The address of miner who opened the oracle
    event NTokenOpened(address token, address ntoken, address owner);
    
    event NTokenDisabled(address token);
    
    event NTokenEnabled(address token);

    /// @dev 配置结构体
    struct Config {
        // 开通ntoken需要支付的nest数量。10000 ether
        uint96 openFeeNestAmount;
        // ntoken管理功能启用状态。0：未启用，1：已启用
        uint8 state;
    }

    /// @dev A struct for an ntoken
    ///     size: 2 x 256bit
    struct NTokenTag {
        address owner;          // the owner with the highest bid
        uint128 nestFee;        // NEST amount staked for opening a NToken
        uint64  startTime;      // the start time of service
        uint8   state;          // =0: disabled | =1 normal
        uint56  _reserved;      // padding space
    }

    /* ========== 系统配置 ========== */
    
    /// @dev 设置ntokenCounter
    /// @param ntokenCounter 当前已经创建的ntoken数量
    function setNTokenCounter(uint ntokenCounter) external;

    /// @dev 修改配置
    /// @param config 配置对象
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置对象
    function getConfig() external view returns (Config memory);

    /// @dev 添加ntoken映射
    /// @param tokenAddress token地址
    /// @param ntokenAddress ntoken地址
    function addNTokenMapping(address tokenAddress, address ntokenAddress) external;

    /// @dev 获取ntoken对应的token地址
    /// @param ntokenAddress ntoken地址
    /// @return token地址
    function getTokenAddress(address ntokenAddress) external view returns (address);

    /// @dev 获取token对应的ntoken地址
    /// @param tokenAddress token地址
    /// @return ntoken地址
    function getNTokenAddress(address tokenAddress) external view returns (address);
    
    /// @dev Bad tokens should be banned 
    function disable(address tokenAddress) external;

    /// @dev 启用ntoken
    function enable(address tokenAddress) external;

    function open(address token) external;
    
    function getNTokenTag(address token) external view returns (NTokenTag memory);
}
