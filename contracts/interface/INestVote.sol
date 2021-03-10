// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev 投票合约
interface INestVote {

    /// @dev 配置结构体
    struct Config {

        // 投票通过需要的比例（万分制）。5100
        uint32 acceptance;

        // 投票时间周期。5 * 86400秒
        uint64 voteDuration;

        // 投票需要抵押的nest数量。100000 nest
        uint96 proposalStaking;
    }

    // 提案
    struct ProposalView {

        uint index;
        
        // 将固定字段和变动字段分开存储，
        /* ========== 固定字段 ========== */

        // 提案简介
        string brief;

        // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
        address contractAddress;

        // 投票开始时间
        uint48 startTime;

        // 投票截止时间
        uint48 stopTime;

        // 提案者
        address proposer;

        // 抵押的nest
        uint96 staked;

        /* ========== 变动字段 ========== */
        // 获得的投票量
        // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
        uint96 gainValue;

        // 提案状态
        uint32 state;  // 0: proposed | 1: accepted | 2: cancelled

        // 提案执行者
        address executor;

        // 执行时间（如果有，例如区块号或者时间戳）放在合约里面，由合约自行限制
    }

    // // 提案
    // struct ProposalView {

    //     // 提案简介
    //     string brief;

    //     // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
    //     address contractAddress;
        
    //     // 提案者
    //     address proposer;

    //     // 投票开始时间
    //     uint48 startTime;

    //     // 投票截止时间
    //     uint48 stopTime;

    //     // 获得的投票量
    //     // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
    //     uint96 gainValue;

    //     // 提案状态
    //     uint32 state;  // 0: proposed | 1: accepted | 2: rejected

    //     // 提案执行者
    //     address executor;
    // }
    
    /// @dev 修改配置
    /// @param config 配置结构体
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() external view returns (Config memory);

    /// @dev 发起投票
    /// @param contractAddress 投票执行合约地址(需要实现IVotePropose接口)
    /// @param brief 提案简介
    function propose(address contractAddress, string memory brief) external;

    /// @dev 进行投票
    /// @param proposeIndex 投票编号
    /// @param value 投票的权重
    function vote(uint proposeIndex, uint value) external;

    // /// @dev 撤销投票
    // /// @param proposeIndex 投票编号
    // /// @param value 投票的权重
    // function revoke(uint proposeIndex, uint value) external;

    /// @dev 执行投票
    /// @param proposeIndex 投票编号
    function execute(uint proposeIndex) external;

    // 取消投票
    function calcel(uint index) external;

    /// @dev 取回投票的nest
    /// @param proposeIndex 投票编号
    function withdraw(uint proposeIndex) external;

    // /// @dev 已经质押的nest数量
    // /// @param proposeIndex 投票编号
    // function stakedNestNum(uint proposeIndex) external view returns (uint);

    /// @dev 获取投票信息
    /// @param proposeIndex 投票编号
    /// @return 投票信息结构体
    function getProposeInfo(uint proposeIndex) external view returns (ProposalView memory);

    /// @dev 获取累计投票提案数量
    /// @return 累计投票提案数量
    function getProposeCount() external view returns (uint);

    // function numberOfVoters(uint id) external view returns (uint) 

    /// @dev 分页列出投票提案
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式. 0倒序, 非0正序
    /// @return 投票列表
    function list(uint offset, uint count, uint order) external view returns (ProposalView[] memory);
}