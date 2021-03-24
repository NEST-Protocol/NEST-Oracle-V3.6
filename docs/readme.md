# NEST V3.6 Contract Specification

## 1. Background
NEST V3.6 has made certain functional adjustments and non-functional modifications based on NEST V3.5.

### 1.1. Functional Class
1. Cancel dividends
2. Add voting-governance module (see product document for details), system maintained accounts can be deleted by voting after V3.6 releases
3. The quotation scale of nest is 30eth, the quotation scale of ntoken is 10eth, the commission is changed from the original calculation based on the scale ratio to a fixed value, and the commissions of nest and ntoken are both set to 0.1eth
4. The verification block is proposed to adjust to 20 blocks
5. NestNode mining independently, the mining speed is 15% of the total mining speed of nest

### 1.2. Non-functional Class
1. Adjust the contract structure, redefine contracts which allowing changes and need to be fixed this time and in the future, and the DAO is divided into the ledger and the application (currently there is only one application: repurchase, there might be more DAO application in the future)
2. Adjust the contract data structure. The main goal is to save gas consumption. After the adjustment, some calculations will have a loss of accuracy, but the accuracy loss will be controlled within one trillionth

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
    ///@dev Definitions for the price sheet, include the full information. (use 256bits, a storage unit in ethereum evm)
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

        // The pledged number of nest in this sheet. (unit: 1000nest)
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

2. 2)	Change the original 128-bit price field to a representation of fraction * 16 ^ exponent. Because the decimal places of different tokens are quite different, the price of the currency is also different, and the fixed decimal place is difficult to meet. Therefore, using this floating-point-like representation method can theoretically provide 14 significant digits, with loss of precision Keep it within one part per trillion. Below is the code for encoding and decoding of this representation.

```javascript
    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function encodeFloat(uint value) public pure returns (uint56) {
        
        uint decimals = 0; 
        while (value > 0x3FFFFFFFFFFFF) {
            value >>= 4;
            ++decimals;
        }
        return uint56((value << 6) | decimals);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function decodeFloat(uint56 floatValue) public pure returns (uint) {
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

## 5. Deployment method

## 6. Application scenarios

