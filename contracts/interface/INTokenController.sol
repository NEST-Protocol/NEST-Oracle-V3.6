// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface INTokenController {
    
    /// @notice when the auction of a token gets started
    /// @param tokenAddress The address of the (ERC20) token
    /// @param ntokenAddress The address of the ntoken w.r.t. token for incentives
    /// @param owner The address of miner who opened the oracle
    event NTokenOpened(address tokenAddress, address ntokenAddress, address owner);
    
    /// @notice ntoken禁用事件
    /// @param tokenAddress token地址
    event NTokenDisabled(address tokenAddress);
    
    /// @notice ntoken启用事件
    /// @param tokenAddress token地址
    event NTokenEnabled(address tokenAddress);

    /// @dev ntoken控制器配置结构体
    struct Config {

        // 开通ntoken需要支付的nest数量。10000 ether
        uint96 openFeeNestAmount;

        // ntoken管理功能启用状态。0：未启用，1：已启用
        uint8 state;
    }

    /// @dev A struct for an ntoken
    struct NTokenTag {

        address ntokenAddress;
        uint96 nestFee;
        address tokenAddress;
        uint40 index;
        uint48 startTime;
        uint8 state;                // =0: disabled | =1 normal
    }

    /* ========== 治理相关 ========== */

    /// @dev 修改配置。
    /// @param config 配置对象
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置对象
    function getConfig() external view returns (Config memory);

    /// @dev 设置ntoken映射（对应的ntoken必须已经存在）
    /// @param tokenAddress token地址
    /// @param ntokenAddress ntoken地址
    /// @param state 状态
    function setNTokenMapping(address tokenAddress, address ntokenAddress, uint state) external;

    /// @dev 获取ntoken对应的token地址
    /// @param ntokenAddress ntoken地址
    /// @return token地址
    function getTokenAddress(address ntokenAddress) external view returns (address);

    /// @dev 获取token对应的ntoken地址
    /// @param tokenAddress token地址
    /// @return ntoken地址
    function getNTokenAddress(address tokenAddress) external view returns (address);

    /* ========== ntoken管理 ========== */
    
    /// @dev Bad tokens should be banned 
    function disable(address tokenAddress) external;

    /// @dev 启用ntoken
    function enable(address tokenAddress) external;

    /// @notice Open a NToken for a token by anyone (contracts aren't allowed)
    /// @dev Create and map the (Token, NToken) pair in NestPool
    /// @param tokenAddress The address of token contract
    function open(address tokenAddress) external;

    /* ========== VIEWS ========== */

    /// @dev 获取ntoken信息
    /// @param tokenAddress token地址
    /// @return ntoken信息结构体
    function getNTokenTag(address tokenAddress) external view returns (NTokenTag memory);

    /// @dev 获取ntoken数量
    /// @return ntoken数量
    function getNTokenCount() external view returns (uint);

    /// @dev 分页列出ntoken列表
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式。0倒序，非0正序
    /// @return ntoken列表
    function list(uint offset, uint count, uint order) external view returns (NTokenTag[] memory);
}
