# INTokenController

## 1. Interface Description
   This interface defines the methods for ntoken management

## 2. Method Description

### 2.1. Modify configuration

    Governance 
     
```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;
```
```javascript
    /// @dev ntoken configuration structure
    struct Config {

        // The number of nest needed to pay for opening ntoken. 10000 ether
        uint96 openFeeNestAmount;

        // ntoken management is enabled. 0: not enabled, 1: enabled
        uint8 state;
    }
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
```

### 2.3. Set the token mapping

```javascript
    /// @dev Set the token mapping
    /// @param tokenAddress Destination token address
    /// @param ntokenAddress Destination ntoken address
    /// @param state status for this map
    function setNTokenMapping(address tokenAddress, address ntokenAddress, uint state) external;
```

### 2.4. Get token address from ntoken address

```javascript
    /// @dev Get token address from ntoken address
    /// @param ntokenAddress Destination ntoken address
    /// @return token address
    function getTokenAddress(address ntokenAddress) external view returns (address);
```

### 2.5. Get ntoken address from token address

```javascript
    /// @dev Get ntoken address from token address
    /// @param tokenAddress Destination token address
    /// @return ntoken address
    function getNTokenAddress(address tokenAddress) external view returns (address);
```
    ntoken management 

### 2.6. Bad tokens should be banned 

```javascript
    /// @dev Bad tokens should be banned 
    function disable(address tokenAddress) external;
```
    Note: This method will triggers the NTokenDisabled event, See also 3.2.

### 2.7. enable ntoken

```javascript
    /// @dev enable ntoken
    function enable(address tokenAddress) external;
```
    Note: This method will triggers the NTokenEnabled event, See also 3.3.

### 2.8. Open a NToken for a token by anyone

```javascript
     /// @notice Open a NToken for a token by anyone (contracts aren't allowed)
     /// @dev Create and map the (Token, NToken) pair in NestPool
     /// @param tokenAddress The address of token contract
     function open(address tokenAddress) external;
```
   Note: This method will triggers the NTokenOpened event, See also 3.1.
    
    VIEWS 
     
### 2.9. Get ntoken information

```javascript
    /// @dev Get ntoken information
    /// @param tokenAddress Destination token address
    /// @return ntoken information
    function getNTokenTag(address tokenAddress) external view returns (NTokenTag memory);
```
```javascript
    /// @dev A struct for an ntoken
    struct NTokenTag {

        // ntoken address
        address ntokenAddress;

        // How much nest has paid for open this ntoken
        uint96 nestFee;
    
        // token address
        address tokenAddress;

        // Index for this ntoken
        uint40 index;

        // Create time
        uint48 startTime;

        // State of this ntoken. 0: disabled; 1 normal
        uint8 state;
    }
```

### 2.10. Get opened ntoken count

```javascript
    /// @dev Get opened ntoken count
    /// @return ntoken count
    function getNTokenCount() external view returns (uint);
```

### 2.11. List ntoken information by page

```javascript
    /// @dev List ntoken information by page
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return ntoken information by page
    function list(uint offset, uint count, uint order) external view returns (NTokenTag[] memory);
```

## 3. Event Description

### 3.1. NTokenOpened  event

```javascript 
    /// @notice when the auction of a token gets started
    /// @param tokenAddress The address of the (ERC20) token
    /// @param ntokenAddress The address of the ntoken w.r.t. token for incentives
    /// @param owner The address of miner who opened the oracle
    event NTokenOpened(address tokenAddress, address ntokenAddress, address owner);
```

### 3.2. ntoken disable event

```javascript 
    /// @notice ntoken disable event
    /// @param tokenAddress token address
    event NTokenDisabled(address tokenAddress);
```

### 3.3. ntoken enable event

```javascript 
    /// @notice ntoken enable event
    /// @param tokenAddress token address
    event NTokenEnabled(address tokenAddress);
```
