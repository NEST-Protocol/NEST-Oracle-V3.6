// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev 投票合约需要实现的接口
interface INNRewardPool {

    /// @dev Claim rewards by Nest-Nodes
    /// @dev The rewards need to pull from NestPool
    function claimNNReward() external;

    /// @dev The callback function called by NNToken.transfer()
    /// @param fromAdd The address of 'from' to transfer
    /// @param toAdd The address of 'to' to transfer
    function nodeCount(address fromAdd, address toAdd) external;

    /// @dev Show the amount of rewards unclaimed
    /// @return reward The reward of a NN holder
    function unclaimedNNReward() external view returns (uint reward);
}