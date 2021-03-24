# INestMining

## 1. Interface Description
    This interface defines the mining methods for nest.

## 2. Method Description

    Configuration

### 2.1. Modify configuration

```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;
```
```javascript
    /// @dev Nest mining configuration structure
    struct Config {

        // Eth number of each post. 30
        // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
        uint32 postEthUnit;

        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;

        // Proportion of miners digging(10000 based). 8000
        uint16 minerNestReward;

        // The proportion of token dug by miners is only valid for the token created in version 3.0
        // (10000 based). 9500
        uint16 minerNTokenReward;

        // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
        uint32 doublePostThreshold;

        // The limit of ntoken mined blocks. 100
        uint16 ntokenMinedBlockLimit;

        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        uint16 maxBiteNestedLevel;

        // Price effective block interval. 20
        uint16 priceEffectSpan;

        // The amount of nest to pledge for each post（Unit: 1000). 100
        uint16 pledgeNest;
    }
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
```

    Mining

### 2.3. Post a price sheet for TOKEN

```javascript
    /// @notice Post a price sheet for TOKEN
    /// @dev It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address tokenAddress, uint ethNum, uint tokenAmountPerEth) external payable;
```
    Note: This method will triggers the Post event, See also 3.1.

### 2.4. Post two price sheets for a token and its ntoken simultaneously

```javascript
    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(address tokenAddress, uint ethNum, uint tokenAmountPerEth, uint ntokenAmountPerEth) external payable;
```
    Note: This method will triggers the Post event, See also 3.1.
    
### 2.5. Call the function to buy TOKEN/NTOKEN from a posted price sheet

```javascript
    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) external payable;
```

### 2.6. Call the function to buy ETH from a posted price sheet
   
```javascript   
    /// @notice Call the function to buy ETH from a posted price sheet
    /// @dev bite ETH by TOKEN(NTOKEN),  (-ethNumBal, +tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) external payable;
``` 

### 2.7. Close a price sheet of (ETH, USDT) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    
```javascript    
    /// @notice Close a price sheet of (ETH, USDT) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param tokenAddress The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address tokenAddress, uint index) external;
``` 

### 2.8. Close a batch of price sheets passed VERIFICATION-PHASE

```javascript   
    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint[] memory indices) external;
``` 

### 2.9. Close two batch of price sheets passed VERIFICATION-PHASE

```javascript  
    /// @notice Close two batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress1 The address of TOKEN1 contract
    /// @param indices1 A list of indices of sheets w.r.t. `token1`
    /// @param tokenAddress2 The address of TOKEN2 contract
    /// @param indices2 A list of indices of sheets w.r.t. `token2`
    function closeList2(address tokenAddress1, uint[] memory indices1, address tokenAddress2, uint[] memory indices2) external;
``` 
### 2.10. The function updates the statistics of price sheets

```javascript 
    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function stat(address tokenAddress) external;
``` 

### 2.11. Settlement Commission

```javascript 
    /// @dev Settlement Commission
    /// @param tokenAddress The token address
    function settle(address tokenAddress) external;
``` 

### 2.12. List sheets by page

```javascript 
    /// @dev List sheets by page
    /// @param tokenAddress Destination token address
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(address tokenAddress, uint offset, uint count, uint order) external view returns (PriceSheetView[] memory);
``` 
```javascript
    /// @dev PriceSheetView structure
    struct PriceSheetView {

        // Index of the price sheeet
        uint32 index;

        // Address of miner
        address miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // The eth number which miner will got
        uint32 ethNumBal;

        // The eth number which equivalent to token's value which miner will got
        uint32 tokenNumBal;

        // The pledged number of nest in this sheet. (Unit: 1000nest)
        uint24 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Post fee shares, if there are many sheets in one block, this value is used to divide up mining value
        uint8 shares;

        // The token price. (1eth equivalent to (price) token)
        uint152 price;
    }
```

### 2.13. Estimated ore yield

```javascript 
    /// @dev Estimated ore yield
    /// @param tokenAddress Destination token address
    /// @return Estimated ore yield
    function estimate(address tokenAddress) external view returns (uint);
``` 

### 2.14. Query the quantity of the target quotation

```javascript 
    /// @dev Query the quantity of the target quotation
    /// @param tokenAddress Token address. The token can't mine. Please make sure you don't use the token address when calling
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(address tokenAddress, uint index) external view returns (uint minedBlocks, uint totalShares);
``` 

    Accounts 

### 2.15. Withdraw assets

```javascript 
    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    /// @return Actually withdrawn
    function withdraw(address tokenAddress, uint value) external returns (uint);
``` 

### 2.16. View the number of assets specified by the user

```javascript 
    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view returns (uint);
``` 

### 2.17. Gets the address corresponding to the given index number

```javascript 
    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) external view returns (address);
```  

### 2.18. Gets the registration index number of the specified address

```javascript 
    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) external view returns (uint);
```

### 2.19. Get the length of registered account array

```javascript 
    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view returns (uint);
```

## 3. Event Description

### 3.1. Post event

```javascript 
    /// @dev Post event
    /// @param tokenAddress The address of TOKEN contract
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param ethNum The numbers of ethers to post sheets
    event Post(address tokenAddress, address miner, uint index, uint ethNum, uint price);
```
