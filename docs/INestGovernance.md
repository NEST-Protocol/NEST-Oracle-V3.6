# INestGovernance

## 1. Interface Description
    This interface defines the governance methods

## 2. Method Description

### 2.1. Set governance authority

```javascript
    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;
```

### 2.2. Get governance rights

```javascript
    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);
```

### 2.3. Check whether the target address has governance rights for the given target

```javascript
    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
```

### 2.4. Set the built-in contract address of the system

```javascript
    /// @dev Set the built-in contract address of the system
    /// @param nestTokenAddress Address of nest token contract
    /// @param nestNodeAddress Address of nest node contract
    /// @param nestLedgerAddress INestLedger implemention contract address
    /// @param nestMiningAddress INestMining implemention contract address for nest
    /// @param ntokenMiningAddress INestMining implemention contract address for ntoken
    /// @param nestPriceFacadeAddress INestPriceFacade implemention contract address
    /// @param nestVoteAddress INestVote implemention contract address
    /// @param nestQueryAddress INestQuery implemention contract address
    /// @param nnIncomeAddress NNIncome contract address
    /// @param nTokenControllerAddress INTokenController implemention contract address
    function setBuiltinAddress(
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) external;
```

### 2.5. Get the built-in contract address of the system

```javascript
    /// @dev Get the built-in contract address of the system
    /// @return nestTokenAddress Address of nest token contract
    /// @return nestNodeAddress Address of nest node contract
    /// @return nestLedgerAddress INestLedger implemention contract address
    /// @return nestMiningAddress INestMining implemention contract address
    /// @return ntokenMiningAddress INestMining implemention contract address for ntoken
    /// @return nestPriceFacadeAddress INestPriceFacade implemention contract address
    /// @return nestVoteAddress INestVote implemention contract address
    /// @return nestQueryAddress INestQuery implemention contract address
    /// @return nnIncomeAddress NNIncome contract address
    /// @return nTokenControllerAddress INTokenController implemention contract address
    function getBuiltinAddress() external view returns (
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    );
```

### 2.6. Get address of nest token contract

```javascript
    /// @dev Get address of nest token contract
    /// @return Address of nest token contract
    function getNestTokenAddress() external view returns (address);
```

### 2.7. Get address of nest node contract

```javascript
    /// @dev Get address of nest node contract
    /// @return Address of nest node contract
    function getNestNodeAddress() external view returns (address);
```

### 2.8. Get INestLedger implemention contract address

```javascript
    /// @dev Get INestLedger implemention contract address
    /// @return INestLedger implemention contract address
    function getNestLedgerAddress() external view returns (address);
```

### 2.9. Get INestMining implemention contract address

```javascript
     /// @dev Get INestMining implemention contract address for nest
     /// @return INestMining implemention contract address for nest
     function getNestMiningAddress() external view returns (address);
```

### 2.10. Get INestMining implemention contract address

```javascript
    /// @dev Get INestMining implemention contract address for ntoken
    /// @return INestMining implemention contract address for ntoken
    function getNTokenMiningAddress() external view returns (address);
```

### 2.11. Get INestPriceFacade implemention contract address

```javascript
    /// @dev Get INestPriceFacade implemention contract address
    /// @return INestPriceFacade implemention contract address
    function getNestPriceFacadeAddress() external view returns (address);
```

### 2.12. Get INestVote implemention contract address

```javascript
    /// @dev Get INestVote implemention contract address
    /// @return INestVote implemention contract address
    function getNestVoteAddress() external view returns (address);
```

### 2.13. Get INestQuery implemention contract address

```javascript
    /// @dev Get INestQuery implemention contract address
    /// @return INestQuery implemention contract address
    function getNestQueryAddress() external view returns (address);
```

### 2.14. Get NNIncome contract address

```javascript
    /// @dev Get NNIncome contract address
    /// @return NNIncome contract address
    function getNnIncomeAddress() external view returns (address);
```

### 2.15. Get INTokenController implemention contract address

```javascript
    /// @dev Get INTokenController implemention contract address
    /// @return INTokenController implemention contract address
    function getNTokenControllerAddress() external view returns (address);
```

### 2.16. Registered address

```javascript
    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external;
```

### 2.17. Get registered address

```javascript
    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view returns (address);
```
