# NN挖矿合约

## 1. 合约说明
    NN挖矿合约。

## 2. 接口说明

### 2.1. Claim rewards by Nest-Nodes

    /// @dev Claim rewards by Nest-Nodes
    /// @dev The rewards need to pull from NestPool
    function claimNNReward() external;

### 2.2. The callback function called by NNToken.transfer()

    /// @dev The callback function called by NNToken.transfer()
    /// @param fromAdd The address of 'from' to transfer
    /// @param toAdd The address of 'to' to transfer
    function nodeCount(address fromAdd, address toAdd) external;

### 2.3. Show the amount of rewards unclaimed

    /// @dev Show the amount of rewards unclaimed
    /// @return reward The reward of a NN holder
    function unclaimedNNReward() external view returns (uint reward);