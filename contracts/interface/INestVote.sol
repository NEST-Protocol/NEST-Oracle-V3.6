// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev 投票合约
interface INestVote {

    /// @dev 提交投票提案事件
    /// @param proposer 发起者地址
    /// @param contractAddress 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
    /// @param index 提案编号
    event NIPSubmitted(address proposer, address contractAddress, uint index);

    /// @dev 投票事件
    /// @param voter 投票者地址
    /// @param index 提案编号
    /// @param amount 投票数量
    event NIPVote(address voter, uint index, uint amount);
    //event NIPWithdraw(address voter, uint index, uint blnc);
    //event NIPRevoke(address voter, uint index, uint amount);

    /// @dev 提案执行事件
    /// @param executor 执行者地址
    /// @param index 提案编号
    event NIPExecute(address executor, uint index);

    /// @dev 投票合约配置结构体
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

        // nest总流通量
        uint96 nestCirculation;
    }
    
    /// @dev 修改配置
    /// @param config 配置结构体
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() external view returns (Config memory);

    /* ========== VOTE ========== */
    
    /// @dev 发起投票提案
    /// @param contractAddress 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
    /// @param brief 提案简介
    function propose(address contractAddress, string memory brief) external;

    /// @dev 投票
    /// @param index 提案编号
    /// @param value 投票的nest数量
    function vote(uint index, uint value) external;

    /// @dev 取回投票的nest，如果目标投票处于投票中的状态，则会取消相应的得票量
    /// @param index 提案编号
    function withdraw(uint index) external;

    /// @dev 执行投票
    /// @param index 提案编号
    function execute(uint index) external;

    /// @dev 取消投票
    /// @param index 提案编号
    function calcel(uint index) external;

    /// @dev 获取投票信息
    /// @param index 提案编号
    /// @return 投票信息结构体
    function getProposeInfo(uint index) external view returns (ProposalView memory);

    /// @dev 获取累计投票提案数量
    /// @return 累计投票提案数量
    function getProposeCount() external view returns (uint);

    /// @dev 分页列出投票提案
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式。0倒序，非0正序
    /// @return 投票列表
    function list(uint offset, uint count, uint order) external view returns (ProposalView[] memory);

    /// @dev 获取nest流通量
    /// @return nest流通量
    function getNestCirculation() external view returns (uint);
}