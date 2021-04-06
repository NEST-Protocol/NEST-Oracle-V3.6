# INNIncome

## 1. Interface Description
   This interface defines the methods for NNIncome

## 2. Method Description

### 2.1. Nest node transfer settlement

```javascript
    /// @dev Nest node transfer settlement. This method is triggered during nest node transfer and must be called by nest node contract
    /// @param from Transfer from address
    /// @param to Transfer to address
    function settle(address from, address to) external;
```

### 2.2. Claim nest

```javascript
    /// @dev Claim nest
    function claim() external;
```

### 2.3. Calculation of ore drawing increment

```javascript
    /// @dev Calculation of ore drawing increment
    /// @return Ore drawing increment
    function increment() external view returns (uint);
```

### 2.4. Query the current available nest

```javascript
    /// @dev Query the current available nest
    /// @param owner Destination address
    /// @return Number of nest currently available
    function earned(address owner) external view returns (uint);
```
    
### 2.5. Get generatedNest value

```javascript
    /// @dev Get generatedNest value
    /// @return GeneratedNest value
    function getGeneratedNest() external view returns (uint);
```

### 2.6. Get blockCursor value

```javascript
    /// @dev Get blockCursor value
    /// @return blockCursor value
    function getBlockCursor() external view returns (uint);
```