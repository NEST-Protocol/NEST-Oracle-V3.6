# NEST V3.6 Contract Specification

## 1. Background
NEST V3.6 has made certain functional adjustments and non-functional modifications based on NEST V3.5.

### 1.1. Functional Class
1. Add a voting governance module which will remove system maintenance accounts by voting after v3.6 launches. Decentralize developer rights to the community and require 51% votes for any changes of the protocol.

2. Completely elimination of dividends with all income used for repurchase.

3. Quotation scale adjustment: NEST Token dual-track quotation scale 30 ETH unchanged, nToken quotation scale adjusted to 10 ETH.

4. Both quotation fees are adjusted from 0.33% of the scale to positive integer multiples of a fixed unit fee and up to 255 times. The unit fee of NEST is 0.1ETH and the unit fee of nToken is 0.05ETH.

5. The rate of NEST ming by launching enters the next damping period when 204 NEST will be mined in each block.

6. The upper limit of the block interval of nToken mining is adjusted to 300.

7. Charges for opening nToken oracle are adjusted to 1000 NEST.

8. The quantity of verification blocks is adjusted from 25 to 20.

9. NestNode Token independent mining separates from NEST miner mining and gets NEST Token by block with the 15% speed of all NEST Token mining.

### 1.2. Non-functional Class
1. Adjust the contract structure and redefine the contracts that are allowed to change and need to be fixed this time and in the future.

2. Split DAO into ledger and application (currently there is only one application: repurchase and in the future there may be more DAO applications) which is equivalent to reinventing a Snapshot governed functional contract within NEST Protocol that fully executes on-chain.

3. Adjust the contract data structure mainly to save Gas consumption and part of the calculation will have accuracy loss which is controlled within one part per trillion after the adjustment.

## 2. Contract Structure

![avatar](nest36-contracts.svg)

The contract relationship is shown in the figure above. The green contract is the contract that needs to be actually deployed, and the others are interface definitions or abstract contracts. The main points are as follows:

1. The contracts of the nest system all inherit the NestBase contract. The NestBase contract mainly implements the logic that the contracts belonging to the nest governance system which need to cooperate with the governance.

2. NestGovernance is a nest governance contract, which includes governance-related functions and realizes the mapping management of the built-in contract address in the nest system.

3. The NestVote contract is a voting governance contract for the nest system. It needs to be given management authority in NestGovernance during deployment. The working principle of NestVote is to achieve the purpose of voting governance by granting governance authority to execute the target contract when the voting rate reaches the set threshold.

4. The NTokenController contract is responsible for the creation and management of nToken.

5. The NestMining contract is a mining contract. It implements INestMining (mining interface) and INestQuery (price query interface). The basic logic is that NestMining implements a price generation mechanism through quotation mining. NestMining will deploy two online, one is the nest mining contract and the other is the ntoken mining contract.

6. NestPriceFacade is the price query portal of NestPrice. Responsible for providing the price calling interface for DeFi, and completing the charging logic at the same time. When searching for the price query interface contract in NestPriceFacade, a two-level query mechanism is used. First, it finds whether the target token has a separate INestQuery contract in a mapping. If it is not found, it uses the built-in contract address for query to realize nest. And ntoken can be divided into different contract quotation functions.

7. NNIncome is the NestNode mining contract. Starting from 3.6, NestNode mining and quotation mining are separated. NestNode determines the amount of ore based on the block, and the rate of mine output is 15% of the total rate of nest.

8. NestLedger is the ledger contract of the NestDAO contract. Starting from 3.6, DAO no longer corresponds to a specific contract, but is split into a ledger contract and multiple DAO application contracts. The ledger contract is used to receive and record the funds of nest and ntoken, and the DAO application contract is authorized by the ledger contract. Currently, there is only one repurchase for DAO application contracts, and more DAO application contracts may be launched in the future.

9. NestRedeeming is a repurchase contract. It is an implementation of DAO application contract.

## 3. Interface Description

### 3.1. INestMapping
INestMapping defines the mapping management of the built-in contract address in the nest system, which mainly includes querying the contract address and modifying the contract address.

### 3.2. INestGovernance
INestGovernance defines nest governance-related functions, inherited from INestMapping. In addition to the functional interface of INestMapping, it also includes checking governance permissions and setting governance permissions.

### 3.3. INestVote
INestVote defines functions related to nest voting governance, mainly including initiating voting, voting, and executing voting.

### 3.4. INTokenController
INTokenController defines the functions related to ntoken activation and management, including opening ntoken and querying ntoken information.

### 3.5. INestMining
INestMining defines the functions related to nest mining, mainly including quotation, taking orders, and querying quotations.

### 3.6. INestQuery
INestQuery defines functions related to nest price query, which mainly includes query price and query the latest price.

### 3.7. INestPriceFacade
INestPriceFacade defines the functions related to nest price call, which corresponds to INestQuery one-to-one, but has more charging logic.

### 3.8. INestLedger
INestLedger defines the functions related to the nest ledger, which mainly includes depositing income, payment, and settlement.

### 3.9. INestRedeeming
INestRedeeming defines functions related to repurchase. It mainly includes checking the repurchase quota and repurchase.

## 4. Data Structure
The V3.6 has made some adjustments to the data structure. The main goal is to save gas consumption. Some calculations will have a loss of accuracy, but the loss is controlled within one trillion. The important data structures are listed below.

### 4.1. PriceSheet

```javascript
    /// @dev Definitions for the price sheet, include the full information. (use 256bits, a storage unit in ethereum evm)
    struct PriceSheet {
        
        // Index of miner account in _accounts. for this way, mapping an address(which need 160bits) to a 32bits 
        // integer, support 4billion accounts
        uint32 miner;

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

        // Represent price as this way, may lose precision, the error less than 1/10^14
        // price = priceFraction * 16 ^ priceExponent
        uint56 priceFloat;
    }
```

The data structure of the quotation sheet processes the two fields of the miner's address and the price, so that the space occupied by the entire quotation sheet can be compressed to 256 bits.

1. Change the address to the registration number. Each miner (verifier) address will have a unique corresponding registered account information in the mining contract, including the miner address, token balance and other information. At the same time, a number is used to mark the miner, so Mapping the original 160-bit address information into 32-bit plastic data, theoretically about 4 billion addresses can be registered. If the registered address is full, it needs to be resolved by updating the mining contract.

2. Change the original 128-bit price field to a representation of fraction * 16 ^ exponent. Because the decimal places of different tokens are quite different, the price of the currency is also different, and the fixed decimal place is difficult to meet. Therefore, using this floating-point-like representation method can theoretically provide 14 significant digits, with loss of precision Keep it within one part per trillion. Below is the code for encoding and decoding of this representation.

```javascript
    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function encodeFloat(uint value) private pure returns (uint56) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint56((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function decodeFloat(uint56 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }
```

### 4.2. PriceInfo

```javascript
    /// @dev Definitions for the price information
    struct PriceInfo {

        // Record the index of price sheet, for update price information from price sheet next time.
        uint32 index;

        // The block number of this price
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 priceFloat;

        // Avg Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 avgFloat;
        
        // Square of price volatility, need divide by 2^48
        uint48 sigmaSQ;
    }
```

1. In the price information, the price and average price are changed to the floating point notation mentioned above.

2. The square of the volatility is changed to a 48-bit integer representation. The actual value needs to be divided by 2^48. In the implementation, it is assumed that the volatility will not reach 1. If this extreme situation occurs, the value of this field is 0xFFFFFFFFFFFF.

## 5. Application scenarios

It mainly includes quotation, voting, buy back, price call and other scenarios.

### 5.1 Post price sheet and bite - NestMining
1. The verification period is changed to 20 blocks. Only when the height of the block where the quotation is located and the current block height is greater than 20 can it be closed. Only when the height of the block where the quotation is located and the current block height is less than 20 can it be verified.
2. Only when the quotation is closed will the ore drawing calculation be carried out, and the verification sheet will not be mined.
3. Eth assets (quotation + commission) required for quotation mining and sheet quotation must be entered into the quotation contract each time. When closing, the remaining eth of the quotation will be returned.
4. After 256 price sheets are settled, the quotation Commission is transferred to the corresponding Dao to save gas consumption. Parameter adjustment or contract upgrade will automatically trigger Commission settlement.
    
#### 5.1.1 Single post
    
**Function：** `post(token, ethNum, tokenAmountPerEth)`
  + `token`  The quoted token address can be the USDT address or the token address of any other enabled predictor.
  + `ethNum` The ETH size of the quotation must be equal to `postEthUnit` and greater than 0. The current ETHUSDT quotation is 30ETH and the other quoted trading pairs are 10ETH.
  + `tokenAmountPerEth` The price quoted by the bidder, i.e. how many tokens can be exchanged for 1 ETH, must be greater than 0. Note that the token unit is the smallest.

**Quoted Assets:**
  + Quotation fee = at least 0.1ETH
  + The number of ETH required for a single quote = ethnum + the listing fee
  + The number of tokens required for a single quote = ethnum * tokenAmountPereth
  + The number of NEST that needs to be secured for a single quotation is 100,000
  
**Note:**
  + The corresponding n-token issuance must be less than 5 million
  
#### 5.1.2 Dual-track price
    
**Function：** `post2(address tokenAddress, uint ethNum, uint tokenAmountPerEth, uint ntokenAmountPerEth) `
  + `token`  The quoted token address can be the USDT address or the token address of any other enabled predictor.
  + `ethNum` The ETH size of the quotation must be equal to `postEthUnit` and greater than 0. The current ETHUSDT quotation is 30ETH and the other quoted trading pairs are 10ETH.
  + `tokenAmountPerEth` The price quoted by the bidder, i.e. how many tokens can be exchanged for 1 ETH, must be greater than 0. Note that the token unit is the smallest.
  + `ntokenAmountPerEth` The quoted price, i.e. how many NTokens can be exchanged for 1 ETH, must be greater than 0. Note that the unit of the token is the smallest unit.

**Quoted Assets:**
  + Quotation fee = at least 0.1ETH
  + The number of ETH required for a single quote = ethnum * 2+ the listing fee
  + The number of tokens required for a single quote = ethnum * tokenAmountPereth
  + The number of NTokens required for a single quote = ethnum * nTokenAmountPereth
  + The number of NEST that needs to be secured for a single quotation is 200,000

#### 5.1.3 Get a quotation
    
**Function：** `list(address tokenAddress, uint offset, uint count, uint order) `
  + `tokenAddress`  The token address can be the USDT address or the token address of any other enabled predictor.
  + `offset` Skip the previous offset bar record.
  + `count` Returns the count entry.
  + `order` Sort way. 0 reverse order, non-0 positive order.
  + Returns a list of PriceSheetView quotations

**PriceSheetView structure:**

```
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

#### 5.1.4 ETH eats single verification
    
**Function：** `takeEth(address tokenAddress, uint index, uint takeNum, uint newTokenAmountPerEth) `
  + `tokenAddress`  A single token address can be the USDT address or the corresponding token address of the enabled predictor.
  + `index` Index of quotation sheet.
  + `takeNum` The ETH size of the order must be greater than 0 and `postEthUnit` (currently ETHUSDT quote is 30ETH, other quote trading pairs are 10ETH). The integer times of.
  + `newTokenAmountPerEth` The re-quoted price after the purchase order, i.e. how many tokens can be exchanged for 1 ETH, must be greater than 0. Note that the unit of token is the smallest unit.

**ETH to eat a single quote assets:**
  
1. This quotation for single depth value `level` less than  ` config. maxBiteNestedLevel `, quotation need the ETH, token and mortgage NEST will be doubled:
  + the number of ETH required to eat the quotation = BITENUM
  + the number of NEST = ((takeNum << 1)/uint(config.postethUnit)) * uint(config.nestledGenest)
  + the number of tokens required to quote the order = (bitEnum * newTokenAamountPereth * 2) + the verified quotation price * BitEnum
  + If the TokenAddress is the NEST address, the number of NEST required for the mortgage also needs to be counted

2. This quotation for single depth value ` level ` greater than or equal to ` config. maxBiteNestedLevel `, quotation need the ETH, token does not need to be doubled, double mortgage NEST requires:
  + the number of ETH required to eat a single quote = 0
  + the number of NEST = ((takeNum << 1)/uint(config.postethUnit)) * uint(config.nestledGenest)
  + the number of tokens required to quote the order = (bitEnum * newTokenAamountPereth) + the price of the verified quotation * BitEnum
  + If the TokenAddress is the NEST address, the number of NEST required for the mortgage also needs to be counted
        
**Note:**
  + Disallow contract calls
  + The quotation must be in the verification period, that is, the interval between the height of the quotation block and the height of the latest block is less than 20
  + The `remainNum` of the offer must be greater than 0
  + `takeNum` must be less than or equal to `remainNum`.
   
#### 5.1.5 Token eating bill verification
    
**Function：** `takeToken(address tokenAddress, uint index, uint takeNum, uint newTokenAmountPerEth)`
  + `tokenAddress`  A single token address can be the USDT address or the corresponding token address of the enabled predictor.
  + `index` Index of quotation sheet.
  + `takeNum` The ETH size of the order must be greater than 0 and `postethUnit` (currently ETHUSDT quote is 30ETH, other quote trading pairs are 10ETH). Integer multiples of PI.
  + `newTokenAmountPerEth` The re-quoted price after the purchase order, i.e. how many tokens can be exchanged for 1 ETH, must be greater than 0. Note that the unit of token is the smallest unit.

**Token eating order quoted assets:**
  
1. This quotation for single depth value `level` less than  `config. maxBiteNestedLevel`, quotation need the ETH, double token and mortgage of the NEST：
  + the number of ETH required to eat a single quote = takeNum * 3
  + the number of NEST = ((takeNum << 1)/uint(config.postethUnit)) * uint(config.nestledGenest)
  + The number of tokens required to quote the order = (bitEnum * newTokenAamountPereth * 2) - the verified quotation price * BitEnum
  + If the TokenAddress is the NEST address, the number of NEST required for the mortgage also needs to be counted
  + If the number of tokens needed is greater than 0, the tokens will be frozen; if the number of tokens needed is less than 0, the tokens will be returned as available assets
    
2. This quotation for single depth value ` level ` greater than or equal to `config.maxBiteNestedLevel` , quotation need the ETH, token does not need to be doubled, double mortgage NEST requires:
  + the number of ETH required to eat a single quote = takeNum * 2
  + the number of NEST = ((takeNum << 1)/uint(config.postethUnit)) * uint(config.nestledGenest)
  + The number of tokens required to quote the order = (bitEnum * newTokenAamountPereth) - the verified quotation price * BitEnum
  + If the TokenAddress is the NEST address, the number of NEST required for the mortgage also needs to be counted
  + If the number of tokens needed is greater than 0, the tokens will be frozen; if the number of tokens needed is less than 0, the tokens will be returned as available assets
  
**Note:**
  + Disallow contract calls
  + The quotation must be in the verification period, that is, the interval between the height of the quotation block and the height of the latest block is less than 20
  + The `remainNum` of the offer must be greater than 0
  + `takeNum` must be less than or equal to `remainNum`.
 
#### 5.1.6 Close quotation sheet
    
**Function：** `close(address tokenAddress, uint index)`
  + `tokenAddress` It can be a token address or a Ntoken address.
  + `index` The index index of the quotation to be closed.

**Assets Settlement:**
  
  + The number of ETH remaining in the quotation (the value of `ethNumBal`) will be transferred to the miner's address.
  + The number of tokens/Ntokens remaining in the quotation (`tokenNumBal` * `price`) will not be transferred to the miner's address. The assets will be unfrozen and stored in the contract as usable assets, which can be directly used by the miner in the next quotation.
  + If it is a token quotation, mining calculation will be carried out at this time, and the mined Ntoken will be directly stored into the contract as the miner's available assets.
  + NEST with mortgage will not transfer the address of the miner. Assets will be unfrozen and stored in the contract as usable assets.
     
**Note:**
  + The quotation must exceed the verification period before closing, that is, the interval between the height of the block where the quotation is located and the height of the latest block is greater than 20

#### 5.1.7 Close quotations in bulk
    
**Function：** `closeList(address tokenAddress, uint32[] memory indices)`
  + `tokenAddress` It can be a token address or a Ntoken address.
  + `indices` The index collection of quotations to close.

**Assets Settlement:**
  
  + The number of ETH remaining in the quotation (the value of `ethNumBal`) will be transferred to the miner's address.
  + The number of tokens/Ntokens remaining in the quotation (`tokenNumBal` * `price`) will not be transferred to the miner's address. The assets will be unfrozen and stored in the contract as usable assets, which can be directly used by the miner in the next quotation.
  + If it is a token quotation, mining calculation will be carried out at this time, and the mined Ntoken will be directly stored into the contract as the miner's available assets.
  + NEST with mortgage will not transfer the address of the miner. Assets will be unfrozen and stored in the contract as usable assets.
     
**Note:**
  + The quotation must exceed the verification period before closing, that is, the interval between the height of the block where the quotation is located and the height of the latest block is greater than 20

#### 5.1.8 Take out the assets
    
**Function：** `withdraw(address tokenAddress, uint value)`
  + `tokenAddress` The token address from which the asset needs to be withdrawn.
  + `value` For the amount of assets to be withdrawn, the value must be less than or equal to the miner's available assets in the contract.
     
#### 5.1.9 Bulk shutdown of tokens and Ntoken quotations
    
**Function：** `closeList2(address tokenAddress, uint32[] memory tokenIndices, uint32[] memory ntokenIndices)`
  + `tokenAddress` The token address to close.
  + `tokenIndices` The index set of Token quotations to close.
  + `ntokenIndices` The index set of NToken quotations to close.


**Assets Settlement:**
  
  + The number of ETH remaining in the quotation (the value of `ethNumBal`) will be transferred to the miner's address.
  + The number of tokens/Ntokens remaining in the quotation (`tokenNumBal` * `price`) will not be transferred to the miner's address. The assets will be unfrozen and stored in the contract as usable assets, which can be directly used by the miner in the next quotation.
  + If it is a token quotation, mining calculation will be carried out at this time, and the mined Ntoken will be directly stored into the contract as the miner's available assets.
  + NEST with mortgage will not transfer the address of the miner. Assets will be unfrozen and stored in the contract as usable assets.
    
**Note:**
  + The quotation must exceed the verification period before closing, that is, the interval between the height of the block where the quotation is located and the height of the latest block is greater than 20


### 5.2 vote--NestVote
Anyone can create an execution contract by implementing the IvotePropose interface and initiate a vote, after which the execution contract will be executed.
        
1. Modify the scope
    What remains unchanged: Nest Token Contract, NToken Token Contract, Mapping Contract, Ledger Contract
    Can be modified: the logical implementation part, can be modified, including mining contract, DAO contract, NN mining contract, NToken opening contract
            
2. The vote
    Voting method: voting by NEST mortgage contract, the number of votes reached the circulation (deducting DAO, mine pool, destruction) 51% can take effect, after reaching 51% can be triggered by anyone can take effect
    Voting period: the voting period is 5 days. The voting period will be valid if 51% of the votes are reached at any time within the 5 days
    Effective period: takes effect immediately after triggering

     
#### 5.2.1 Initiate a ballot proposal
    
**Function：** `propose(address contractAddress, string memory brief)`
  + `contractAddress` The address of the contract to be executed after the proposal is approved (need to implement the `IVotePropose` interface).
  + `brief` Brief introduction to the proposal.

**Note:**
  + contractAddress The destination address cannot already have governance permissions to prevent governance permissions from being overwritten.
  + Disallow contract invocation
  
#### 5.2.2 Paging lists of ballot proposals
    
**Function：** `list(uint offset, uint count, uint order)`
  + `offset` Skip the previous offset bar record.
  + `count` Returns the count entry.
  + `order` Sort way. 0 reverse order, non-0 positive order.
  + Returns a list of proposals for a proposalView

**ProposalView structure**
```     
   struct ProposalView {
        // Index of proposal
        uint index;
        
        // The immutable field and the variable field are stored separately
        /* ========== Immutable field ========== */

        // Brief of this proposal
        string brief;

        // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
        address contractAddress;

        // Voting start time
        uint48 startTime;

        // Voting stop time
        uint48 stopTime;

        // Proposer
        address proposer;

        // Staked nest amount
        uint96 staked;

        /* ========== Mutable field ========== */

        // Gained value
        // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the total 
        // number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of votes
        uint96 gainValue;

        // The state of this proposal
        uint32 state;  // 0: proposed | 1: accepted | 2: cancelled

        // The executor of this proposal
        address executor;

        // The execution time (if any, such as block number or time stamp) is placed in the contract and is limited by the contract itself

        // Circulation of nest
        uint96 nestCirculation;
    }
```

#### 5.2.3 Get the voting information based on the poll subscript
    
**Function：** `getProposeInfo(uint index)`
  + `index` Specify the proposal subscript number

#### 5.2.4 Cancel the ballot proposal
    
**Function：** `calcel(uint index)`
  + `index` Specify the proposal subscript number.

**Note:**
  + After the cancellation of the proposal, it will not be able to participate in the voting and implementation, and the NEST pledged by the sponsor will be returned.

#### 5.2.5 Vote on the proposal
    
**Function：** `vote(uint index, uint value)`
  + `index` Specify the proposal subscript number.
  + `value` Number of NEST votes.

**Note:**
  + Disallow contract calls.
  + The voting period for each proposal is 5 days. The proposal must be within the voting deadline. Note that the closing time does not include `stopTime`.
  + Voting will transfer the NEST of the voter's account into the contract according to the number of values voted, so the NEST balance of the voter's account is required to be greater than or equal to value.
  + The proposal's status`state`must be 0 to be voted on.

#### 5.2.6 Perform proposal
    
**Function：** `execute(uint index)`
  + `index` The proposals that are voted on are numbered.

**Note:**
  + Disallow contract calls.
  + The status` state `of this proposal must be 0 to be executed.
  + The proposal has exceeded the voting cycle, i.e. the current time must be greater than or equal to `stopTime`.
  + The target contract address to be executed by this proposal cannot already have governance rights.
  + The proposal must be approved by a vote of more than 51 percent.
#### 5.2.6 Fetch the voting NEST
    
**Function：** `withdraw(uint index)`
  + `index` Specify the proposal subscript number.

**Note:**
  + Disallow contract calls.
  + If the proposal is currently in the voting period, fetching at this time is equivalent to canceling the previous affirmative votes, and the vote percentage of the proposal after fetching will be reduced accordingly.


### 5.3 Calling Price
```
    Price invocation is free: NestMining, contract invocation is prohibited.
    Price call fee: NestPriceFacade, which supports contract calls, currently costs 0.01ETH per call.
```
#### 5.3.1 Get the latest trigger price
**Function：** `triggeredPrice(address tokenAddress)`
  + `tokenAddress` To query the token address for the specified token price.

**The return value:** 
  + `blockNumber` Block number of the price.
  + `price` Price (how many tokens can be exchanged for 1ETH).

#### 5.3.2 Get the latest trigger price complete information
**Function：** `triggeredPriceInfo(address tokenAddress)`
  + `tokenAddress` To query the token address for the specified token price.

**The return value:** 
  + `blockNumber` Block number of the price.
  + `price` Price (how many tokens can be exchanged for 1ETH).
  + `avgPrice` Average price.
  + `sigmaSQ` Volatility squared.
  
#### 5.3.3 Get the latest effective price
**Function：** `latestPrice(address tokenAddress)`
  + `tokenAddress` To query the token address for the specified token price.

**The return value:** 
  + `blockNumber` Block number of the price.
  + `price` Price (how many tokens can be exchanged for 1ETH).
  
#### 5.3.4 Returns the results of the latestPrice() and triggeredPriceInfo() methods
**Function：** `latestPriceAndTriggeredPriceInfo(address tokenAddress)`
  + `tokenAddress` To query the token address for the specified token price.
 
**The return value:** 
  + `latestPriceBlockNumber` Block number of the latest effective price.
  + `latestPriceValue` The latest effective price (how many tokens can be exchanged for 1ETH). 
  + `triggeredPriceBlockNumber` Block number of the latest trigger price.
  + `triggeredPriceValue` Latest trigger price (how many tokens can be exchanged for 1ETH).
  + `triggeredAvgPrice` Average price.
  + `triggeredSigmaSQ` Volatility squared.

#### 5.3.5 Gets the effective price for the specified block height
**Function：** `findPrice(address tokenAddress, uint height)`
  + `tokenAddress` To query the token address for the specified token price.
  + `height` The block number to query.

**The return value:** 
  + `blockNumber` Block number of the price.
  + `price` Price (how many tokens can be exchanged for 1ETH).
 
 
#### 5.3.6 Get the latest set of effective prices
**Function：** `lastPriceList(address tokenAddress, uint count)`
  + `tokenAddress` To query the token address for the specified token price.
  + `count` Number of queries to be made.
 
**The return value:** 
  + Returns an array size of count*2, each of which represents the blockNumber `blockNumber` and the `price` (how many tokens can be exchanged for one eth).
 
 
#### 5.3.7 Gets the latest trigger price, including token and Ntoken prices
**Function：** `triggeredPrice2(address tokenAddress)`
  + `tokenAddress` To query the token address for the specified price.

**The return value:** 
  + `blockNumber` Block number of the token price.
  + `price` Price (how many tokens can be exchanged for 1ETH).
  + `ntokenBlockNumber` Block number of the ntoken price.
  + `ntokenPrice` Price (how many Ntokens can be exchanged for 1ETH).

#### 5.3.8 Get the latest trigger price complete information, including token and Ntoken prices
**Function：** `triggeredPriceInfo2(address tokenAddress)`
  + `tokenAddress` To query the token address for the specified price.

**The return value:** 
  + `BlockNumber` token price blockNumber.
  + `price` (how many tokens can be exchanged for 1eth).
  + `avgPrice` token average price.
  + `sigmaSQ` token volatility squared.
  + `ntokenBlockNumber` Ntoken price block number.
  + `ntokenPrice` (how many Ntokens can be exchanged for 1eth).
  + `ntokenAvgPrice` ntoken average price.
  + `ntokenSigmaSQ` ntoken volatility squared.

#### 5.3.9 Gets the latest effective price, including token and Ntoken prices
**Function：** `latestPrice2(address tokenAddress)`
  + `tokenAddress` To query the token address for the specified price.

**The return value:** 
  + `blockNumber` Block number of the token price.
  + `price` Price (how many tokens can be exchanged for 1ETH).
  + `ntokenBlockNumber` Block number of the Ntoken price.
  + `ntokenPrice` Price (how many Ntokens can be exchanged for 1ETH).
  
   
### 5.4 redeem--NestRedeeming
```
1. Eliminate dividends
  All revenue generated by the NEST system (quote commission + price call fee) will be transferred to the DAO, and the use of revenue will be determined by voting +DAO governance.

2. NEST DAO
  Nest mining commission 100% into the Nest DAO
  By calling USDT/ETH, 100% of the commission fee of Nest /ETH goes into the Nest DAO
  N-Token Prophet machine commission 20% into Nest DAO
  Repurchase: Anyone can sell Nest to Nest DAO for ETH at the price of the Prophet
    
3. N-Token DAO
  80% of the N-token mining commission goes into the N-token DAO
  The N-Token Prophecer invocation fee is 100% into the N-Token DAO
  Repurchase: Anyone can sell an Ntoken to an N-token DAO in exchange for ETH at the price quoted by the Prophetor

4. Buy back

  NEST3.5 has opened NEST repurchase, and 3.6 will open other N-token repurchase.
```
   
#### 5.4.1 View the current amount available for repurchase
    
**Function：** `quotaOf(address ntokenAddress)`
  + `ntokenAddress` The address of the NToken to be repurchased.

#### 5.4.2 redeem
    
**Function：** `redeem(address ntokenAddress, uint amount)`
  + `ntokenAddress` The address of the NToken to be repurchased。
  + `amount` The number of NToken tokens to be repurchased。

**Note:**
  + Repurchase will call the corresponding price of Nest Prophet, so there will be a price call fee, currently 0.01ETH.
  + The issuance of NToken tokens must be greater than 5 million in order to be repurchased.
  + The current price of the NEST predictor cannot deviate from the rolling average price by more than 5%, otherwise the buyback transaction fails.
