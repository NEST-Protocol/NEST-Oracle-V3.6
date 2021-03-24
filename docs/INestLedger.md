# INestLedger

## 1. Interface Description
    This interface defines the nest ledger methods

## 2. Method Description

### 2.1. Modify configuration

```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;
```
```javascript
    /// @dev Configuration structure of nest ledger contract
    struct Config {
        
        // nest reward scale(10000 based). 2000
        uint32 nestRewardScale;

        // ntoken reward scale(10000 based). 8000
        uint32 ntokenRedardScale;
    }
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
```

### 2.3. Set DAO application

```javascript
    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;
```

### 2.4. Carve reward

```javascript
    /// @dev Carve reward
    /// @param ntokenAddress Destination ntoken address
    function carveReward(address ntokenAddress) external payable;
```

### 2.5. Add reward

```javascript
    /// @dev Add reward
    /// @param ntokenAddress Destination ntoken address
    function addReward(address ntokenAddress) external payable;
```

### 2.6. The function returns eth rewards of specified ntoken

```javascript
    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The ntoken address
    function totalRewards(address ntokenAddress) external view returns (uint);
```

### 2.7. Pay

```javascript
    /// @dev Pay
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(address ntokenAddress, address tokenAddress, address to, uint value) external;
```

### 2.8. Settlement

```javascript
    /// @dev Settlement
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to settle with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address ntokenAddress, address tokenAddress, address to, uint value) external payable;
```
