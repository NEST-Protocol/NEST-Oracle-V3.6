# NestRedeeming

## 1. Interface Description
    The contract is for redeeming nest token and getting ETH in return

## 2. Method Description

### 2.1. Modify configuration

```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;
```
```javascript
    /// @dev Redeem configuration structure
    struct Config {

        // Redeem activate threshold, when the circulation of token exceeds this threshold, 
        // activate redeem (Unit: 10000 ether). 500 
        uint32 activeThreshold;

        // The number of nest redeem per block. 1000
        uint16 nestPerBlock;

        // The maximum number of nest in a single redeem. 300000
        uint32 nestLimit;

        // The number of ntoken redeem per block. 10
        uint16 ntokenPerBlock;

        // The maximum number of ntoken in a single redeem. 3000
        uint32 ntokenLimit;

        // Price deviation limit, beyond this upper limit stop redeem (10000 based). 500
        uint16 priceDeviationLimit;
    }
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
```

### 2.3. Redeem ntokens for ethers

```javascript
    /// @dev Redeem ntokens for ethers
    /// @notice Ethfee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount The amount of ntoken
    function redeem(address ntokenAddress, uint amount) external payable;
```

### 2.4. Get the current amount available for repurchase

```javascript
    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) external view returns (uint);
```

