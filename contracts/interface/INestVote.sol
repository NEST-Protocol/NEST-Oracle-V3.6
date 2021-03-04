// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/// @dev 投票合约
interface INestVote {

    // 提案
    struct Proposal {
        // 提案描述
        string description;
        uint32 state;  // 0: proposed | 1: accepted | 2: rejected
        uint32 startTime;
        uint32 endTime;
        uint64 voters;
        uint128 stakedNestAmount;
        address contractAddr;
        address proposer;
        address executor;
    }

    /// @dev 发起投票
    /// @param contractAddress 投票执行合约地址(需要实现IVotePropose接口)
    /// @param brief 投票内容描述
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

    /// @dev 已经质押的nest数量
    /// @param proposeIndex 投票编号
    function stakedNestNum(uint proposeIndex) external view returns (uint);

    /// @dev 获取投票信息
    /// @param proposeIndex 投票编号
    /// @return 投票信息结构体
    function getProposeInfo(uint proposeIndex) external view returns (Proposal memory);

    /// @dev 获取累计投票提案数量
    /// @return 累计投票提案数量
    function getProposeCount() external view returns (uint);

    // function numberOfVoters(uint id) external view returns (uint) 
}