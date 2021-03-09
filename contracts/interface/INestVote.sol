// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev 投票合约
interface INestVote {

    // 提案
    struct ProposalView {

        // 提案简介
        string brief;

        // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
        address contractAddress;
        
        // 提案者
        address proposer;

        // 投票开始时间
        uint64 startTime;

        // 投票截止时间
        uint64 stopTime;

        // 获得的投票量
        // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
        uint96 gainValue;

        // 提案状态
        uint32 state;  // 0: proposed | 1: accepted | 2: rejected

        // 提案执行者
        address executor;
    }

    /// @dev 发起投票
    /// @param contractAddress 投票执行合约地址(需要实现IVotePropose接口)
    /// @param brief 提案简介
    function propose(address contractAddress, string memory brief) external;

    /// @dev 进行投票
    /// @param proposeIndex 投票编号
    /// @param value 投票的权重
    function vote(uint proposeIndex, uint value) external;

    /// @dev 撤销投票
    /// @param proposeIndex 投票编号
    /// @param value 投票的权重
    function revoke(uint proposeIndex, uint value) external;

    /// @dev 执行投票
    /// @param proposeIndex 投票编号
    function execute(uint proposeIndex) external;

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
}