# NEST的DAO合约

## 1. 合约说明
    NEST的DAO合约。

## 2. 接口说明

### 2.1. 添加ntoken收益
    
    /// @dev 添加ntoken收益
    /// @param ntokenAddress ntoken地址
    function addReward(address ntokenAddress) external payable;

### 2.2. 回购

    /// @dev Redeem ntokens for ethers
    /// @notice Ethfee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount  The amount of ntoken
    function redeem(address ntokenAddress, uint amount) external payable;

### 2.3. 查看ntoken的收益

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The notoken address
    function totalRewards(address ntokenAddress) external view returns (uint);

### 2.4. 查看当前的回购额度

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) external view returns (uint quota);