# INestPriceFacade

## 1. Interface Description
    This interface defines the methods for price call entry

## 2. Method Description

### 2.1. Modify configuration
```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;
```
```javascript
    /// @dev Price call entry configuration structure
    struct Config {

        // Single query fee（0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;

        // Double query fee（0.0001 ether, DIMI_ETHER). 100
        uint16 doubleFee;

        // The normal state flag of the call address. 0
        uint8 normalFlag;
    }
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
```

### 2.3. Set the address flag

```javascript
    /// @dev Set the address flag. Only the address flag equals to config.normalFlag can the price be called
    /// @param addr Destination address
    /// @param flag Address flag
    function setAddressFlag(address addr, uint flag) external;
```

### 2.4. Get the flag

```javascript
    /// @dev Get the flag. Only the address flag equals to config.normalFlag can the price be called
    /// @param addr Destination address
    /// @return Address flag
    function getAddressFlag(address addr) external view returns(uint);
```

### 2.5. Set INestQuery implemention contract address for token

```javascript
    /// @dev Set INestQuery implemention contract address for token
    /// @param tokenAddress Destination token address
    /// @param nestQueryAddress INestQuery implemention contract address, 0 means delete
    function setNestQuery(address tokenAddress, address nestQueryAddress) external;
```

### 2.6. Get INestQuery implemention contract address for token

```javascript
    /// @dev Get INestQuery implemention contract address for token
    /// @param tokenAddress Destination token address
    /// @return INestQuery implemention contract address, 0 means use default
    function getNestQuery(address tokenAddress) external view returns (address);
```

### 2.7. Get the latest trigger price

```javascript
    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(address tokenAddress) external payable returns (uint blockNumber, uint price);
```

### 2.8. Get the full information of latest trigger price

```javascript
    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    //          the volatility cannot exceed 1. Correspondingly, when the return value is equal to 9999999999996447, 
    //          it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(address tokenAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ);
```

### 2.9. Find the price at block number
   
```javascript
   /// @dev Find the price at block number
   /// @param tokenAddress Destination token address
   /// @param height Destination block number
   /// @return blockNumber The block number of price
   /// @return price The token price. (1eth equivalent to (price) token)
   function findPrice(address tokenAddress, uint height) external payable returns (uint blockNumber, uint price);
```

### 2.10. Get the latest effective price
   
```javascript
    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(address tokenAddress) external payable returns (uint blockNumber, uint price);
```

### 2.11. Get the last (num) effective price
   
```javascript
    /// @dev Get the last (num) effective price
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(address tokenAddress, uint count) external payable returns (uint[] memory);
```

### 2.12. Returns the results of latestPrice() and triggeredPriceInfo()
   
```javascript
    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param tokenAddress Destination token address
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places)
    function latestPriceAndTriggeredPriceInfo(address tokenAddress) 
    external 
    payable 
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    );
```

### 2.13. Get the latest trigger price. (token and ntoken）
   
```javascript
    /// @dev Get the latest trigger price. (token and ntoken）
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function triggeredPrice2(address tokenAddress) external payable returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice);
```

### 2.14. Get the full information of latest trigger price. (token and ntoken)
   
```javascript
    /// @dev Get the full information of latest trigger price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 9999999999996447, it means that the volatility has exceeded the range that can be expressed
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    /// @return ntokenAvgPrice Average price of ntoken
    /// @return ntokenSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    //          the volatility cannot exceed 1. Correspondingly, when the return value is equal to 9999999999996447, 
    //          it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo2(address tokenAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ, uint ntokenBlockNumber, uint ntokenPrice, uint ntokenAvgPrice, uint ntokenSigmaSQ);
```

### 2.15. Get the latest effective price. (token and ntoken)
   
```javascript
    /// @dev Get the latest effective price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function latestPrice2(address tokenAddress) external payable returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice);
```