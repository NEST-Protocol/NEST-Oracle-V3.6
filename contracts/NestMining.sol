// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/TransferHelper.sol";
import "./interface/INestMining.sol";
import "./interface/INestQuery.sol";
import "./interface/INTokenController.sol";
import "./interface/INestLedger.sol";
import "./interface/INToken.sol";
import "./interface/INest_NToken.sol";
import "./NestBase.sol";

/// @dev This contract implemented the mining logic of nest.
contract NestMining is NestBase, INestMining, INestQuery {

    /// @param nestTokenAddress Address of nest token contract
    /// @param nestGenesisBlock Genesis block number of nest
    constructor(address nestTokenAddress, uint nestGenesisBlock) {
        
        NEST_TOKEN_ADDRESS = nestTokenAddress;
        NEST_GENESIS_BLOCK = nestGenesisBlock;

        // Placeholder in _accounts, the index of a real account must greater than 0
        _accounts.push();
    }

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
        uint32 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Represent price as this way, may lose precision, the error less than 1/10^14
        // Exponent of price。price = priceFraction * 16 ^ priceExponent
        uint8 priceExponent;

        // Fraction of price。price = priceFraction * 16 ^ priceExponent
        uint48 priceFraction;
    }

    /// @dev Definitions for the price information
    struct PriceInfo {

        // Record the index of price sheet, for update price information from price sheet next time.
        uint32 index;

        // The block number of this price
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // Price, represent as float
        uint8 priceExponent;
        uint48 priceFraction;

        // Avg Price, represent as float
        uint8 avgExponent;
        uint48 avgFraction;
        
        // Square of price volatility, need divide by 2^48
        uint48 sigmaSQ;
    }

    /// @dev Price channel
    struct PriceChannel {

        // Array of price sheets
        PriceSheet[] sheets;

        // Price information
        PriceInfo price;

        // The information of mining fee
        // low 128bits represent fee per post
        // high 128bits in the high level indicate the current cumulative number of sheets that do not require 
        // Commission (including bills and settled ones)
        uint feeInfo;
    }

    /// @dev Structure is used to represent a storage location. Storage variable can be used to avoid indexing from mapping many times
    struct UINT {
        uint value;
    }

    /// @dev Account information
    struct Account {
        
        // Address of account
        address addr;

        // Balances of mining account
        // tokenAddress=>balance
        mapping(address=>UINT) balances;
    }

    /// @dev Configuration
    Config _config;

    /// @dev Registered account information
    Account[] _accounts;

    /// @dev Mapping from address to index of account. address=>accountIndex
    mapping(address=>uint) _accountMapping;

    /// @dev Mapping from token address to price channel. tokenAddress=>PriceChannel
    mapping(address=>PriceChannel) _channels;

    /// @dev Mapping from token address to ntoken address. tokenAddress=>ntokenAddress
    mapping(address=>address) _addressCache;

    /// @dev Cache for genesis block number of ntoken. ntokenAddress=>genesisBlockNumber
    mapping(address=>uint) _genesisBlockNumberCache;

    /// @dev INestPriceFacade implemention contract address
    address _nestPriceFacadeAddress;

    /// @dev INTokenController implemention contract address
    address _nTokenControllerAddress;

    /// @dev INestLegder implemention contract address
    address _nestLedgerAddress;

    /// @dev Address of nest token contract
    address immutable NEST_TOKEN_ADDRESS; // = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    
    /// @dev Genesis block number of nest
    uint immutable NEST_GENESIS_BLOCK; // = 6236588;	

    /// @dev Unit of post fee. 0.0001 ether
    uint constant DIMI_ETHER = 1 ether / 10000;

    /// @dev The mask of batch settlement dividend. During the test, it is settled once every 16 sheets and 
    ///      once every 256 sheets of the online version
    uint constant COLLECT_REWARD_MASK = 0xFF;
    
    /// @dev Ethereum average block time interval, 14 seconds
    uint constant ETHEREUM_BLOCK_TIMESPAN = 14;

    /* ========== Governance ========== */

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implemention contract address
    function update(address nestGovernanceAddress) override public {
        
        super.update(nestGovernanceAddress);
        (
            //address nestTokenAddress
            ,
            //address nestNodeAddress
            ,
            //address nestLedgerAddress
            _nestLedgerAddress,   
            //address nestMiningAddress
            , 
            //address nestPriceFacadeAddress
            _nestPriceFacadeAddress, 
            //address nestVoteAddress
            , 
            //address nestQueryAddress
            , 
            //address nnIncomeAddress
            , 
            //address nTokenControllerAddress
            _nTokenControllerAddress  

        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /* ========== Mining ========== */

    // Get ntoken address of from token address
    function _getNTokenAddress(address tokenAddress) private returns (address) {
        
        address ntokenAddress = _addressCache[tokenAddress];
        if (ntokenAddress == address(0)) {
            if ((ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress)) != address(0)) {
                _addressCache[tokenAddress] = ntokenAddress;
            }
        }
        return ntokenAddress;
    }

    // Get genesis block number of ntoken
    function _getNTokenGenesisBlock(address ntokenAddress) private returns (uint) {

        uint genesisBlockNumber = _genesisBlockNumberCache[ntokenAddress];
        if (genesisBlockNumber == 0) {
            (genesisBlockNumber,) = INToken(ntokenAddress).checkBlockInfo();
            _genesisBlockNumberCache[ntokenAddress] = genesisBlockNumber;
        }

        return genesisBlockNumber;
    }

    /// @dev Clear chache of token. while ntoken recreated, this method is need to call
    /// @param tokenAddress Token address
    function resetNTokenCache(address tokenAddress) public {

        // Clear cache
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        _genesisBlockNumberCache[ntokenAddress] = 0;
        _addressCache[tokenAddress] = _addressCache[ntokenAddress] = address(0);

        // Reload
        _getNTokenAddress(tokenAddress);
        _getNTokenAddress(ntokenAddress);
        _getNTokenGenesisBlock(ntokenAddress);
    }

    /// @notice Post a price sheet for TOKEN
    /// @dev It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address tokenAddress, uint ethNum, uint tokenAmountPerEth) override external payable {
        
        Config memory config = _config;

        // 1. Check arguments
        require(ethNum > 0 && ethNum == uint(config.postEthUnit), "NM:!ethNum");
        require(tokenAmountPerEth > 0, "NM:!price");
        
        // 2. Calculate fee
        uint fee = uint(config.postFee) * DIMI_ETHER;
        require(msg.value == fee + ethNum * 1 ether, "NM:!value");

        // 3. Check price channel
        // Check if the token allow post
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");
        // Unit of nest is different, but the total supply already exceeded the number of this issue. No additional judgment will be made
        // ntoken is mint when the price sheet is closed (or retrieved), this may be the problem that the user 
        // intentionally does not close or retrieve, which leads to the inaccurate judgment of the total amount. ignore
        require(IERC20(ntokenAddress).totalSupply() < uint(config.doublePostThreshold) * 10000 ether, "NM:!post2");        

        // 4. Deposit fee
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
        uint length = sheets.length;
        _collect(channel, ntokenAddress, length, fee, fee);

        // 5. Freezing assets
        uint accountIndex = _addressIndex(msg.sender);
        // Freeze token and nest
        // Because of the use of floating-point representation(uint48 fraction, uint8 exponent), it may bring some precision loss
        // After assets are frozen according to tokenAmountPerEth * ethNum, the part with poor accuracy may be lost when the assets are returned
        // It should be frozen according to decodeFloat(fraction, exponent) * ethNum
        // However, considering that the loss is less than 1 / 10 ^ 14, the loss here is ignored, and the part of 
        // precision loss can be transferred out as system income in the future
        _freeze2(_accounts[accountIndex].balances, tokenAddress, tokenAmountPerEth * ethNum, uint(config.pledgeNest) * 1000 ether);

        // 6. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 7. Create price sheet
        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), uint(config.pledgeNest), 0, tokenAmountPerEth);
    }

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(address tokenAddress, uint ethNum, uint tokenAmountPerEth, uint ntokenAmountPerEth) override external payable {

        Config memory config = _config;

        // 1. Check arguments
        require(ethNum > 0 && ethNum == uint(config.postEthUnit), "NM:!ethNum");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "NM:!price");
        
        // 2. Calculate fee
        // ******** 'tmp' is a multi-purpose variable, from which we begin to express 'fee'
        uint tmp = uint(config.postFee) * DIMI_ETHER;
        require(msg.value == tmp + ethNum * 2 ether, "NM:!value");

        // 3. Check price channel
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");

        // 4. Deposit fee
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
        uint length = sheets.length;
        _collect(channel, ntokenAddress, length, tmp, tmp);

        // 5. Freezing assets
        uint accountIndex = _addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        // ******** 'tmp' is a multi-purpose variable, from which we begin to express 'config.pledgeNest'
        tmp = uint(config.pledgeNest);
        _freeze(balances, tokenAddress, ethNum * tokenAmountPerEth);
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _freeze(balances, NEST_TOKEN_ADDRESS, ethNum * ntokenAmountPerEth + tmp * 1000 ether);
        } else {
            _freeze2(balances, ntokenAddress, ethNum * ntokenAmountPerEth, tmp * 2000 ether);
        }
        
        // 6. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 7. Create price sheet
        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), tmp, 0, tokenAmountPerEth);

        channel = _channels[ntokenAddress];
        sheets = channel.sheets;

        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(channel, sheets, uint(config.priceEffectSpan));
        emit Post(ntokenAddress, msg.sender, sheets.length, ethNum, ntokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), tmp, 0, ntokenAmountPerEth);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) override external payable {

        Config memory config = _config;

        // 1. Check arguments
        require(biteNum > 0 && biteNum % uint(config.postEthUnit) == 0, "NM:!biteNum");
        require(newTokenAmountPerEth > 0, "NM:!price");

        // 2. Load price sheet
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        PriceSheet memory sheet = sheets[index];

        // 3. Check state
        require(uint(sheet.remainNum) >= biteNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        // 4. Deposit fee
        {
            // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            if (tokenAddress != ntokenAddress) {
                _collect(channel, ntokenAddress, sheets.length, 0, uint(config.postFee) * DIMI_ETHER);
            }
        }

        // 5. Calculate the number of eth, token and nest needed, and freeze them
        uint needTokenValue;
        uint level = uint(sheet.level);

        // When the level of the sheet is less than 4, both the nest and the scale of the offer are doubled
        if (level < uint(config.maxBiteNestedLevel)) {
            // Double scale sheet + the quantity used to buy token, three times total
            require(msg.value == biteNum * 3 ether, "NM:!value");
            // Double scall sheet
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
            ++level;
        } 
        // When the level of the sheet reaches 4 or more, nest doubles, but the scale does not
        else {
            // Single scale sheet + the quantity used to buy token, two times total
            require(msg.value == biteNum * 2 ether, "NM:!value");
            // Single scale sheet
            needTokenValue = newTokenAmountPerEth * biteNum;
            // It is possible that the length of a single chain exceeds 255. When the length of a chain reaches 4 
            // or more, there is no logical dependence on the specific value of the contract, and the count will 
            // not increase after it is accumulated to 255
            if (level < 255) ++level;
        }

        // Number of nest to be pledged
        uint needNest1k = ((biteNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);

        // Freeze nest
        uint accountIndex = _addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        if (tokenAddress == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1000 ether;
        } else {
            _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether);        
        }

        {
            // Freeze token
            uint backTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum;
            if (needTokenValue > backTokenValue) {
                _freeze(balances, tokenAddress, needTokenValue - backTokenValue);
            } else {
                _unfreeze(balances, tokenAddress, backTokenValue - needTokenValue);
            }
        }

        // 6. Update the biten sheet
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal + biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal - biteNum);
        sheets[index] = sheet;

        // 7. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 8. Create price sheet
        emit Post(tokenAddress, msg.sender, sheets.length, uint32(biteNum << 1), newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(biteNum << 1), needNest1k, level, newTokenAmountPerEth);
    }

    /// @notice Call the function to buy ETH from a posted price sheet
    /// @dev bite ETH by TOKEN(NTOKEN),  (-ethNumBal, +tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) override external payable {

        Config memory config = _config;

        // 1. Check arguments
        require(biteNum > 0 && biteNum % uint(config.postEthUnit) == 0, "NM:!biteNum");
        require(newTokenAmountPerEth > 0, "NM:!price");

        // 2. Load price sheet
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        PriceSheet memory sheet = sheets[index];

        // 3. Check state
        require(uint(sheet.remainNum) >= biteNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        // 4. Deposit fee
        {
            // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            if (tokenAddress != ntokenAddress) {
                _collect(channel, ntokenAddress, sheets.length, 0, uint(config.postFee) * DIMI_ETHER);
            }
        }

        // 5. Calculate the number of eth, token and nest needed, and freeze them
        uint needTokenValue;
        uint level = uint(sheet.level);

        // When the level of the sheet is less than 4, both the nest and the scale of the offer are doubled
        if (level < uint(config.maxBiteNestedLevel)) {
            // Double scale sheet + the quantity used to buy token, three times total
            require(msg.value == biteNum * 1 ether, "NM:!value");
            // Double scale sheet
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
            ++level;
        } 
        // When the level of the sheet reaches 4 or more, nest doubles, but the scale does not
        else {
            // Single scale sheet + the quantity used to buy token, two times total
            require(msg.value == 0, "NM:!value");
            // Single scale sheet
            needTokenValue = newTokenAmountPerEth * biteNum;
            // It is possible that the length of a single chain exceeds 255. When the length of a chain reaches 4 
            // or more, there is no logical dependence on the specific value of the contract, and the count will 
            // not increase after it is accumulated to 255
            if (level < 255) ++level;
        }
        
        // Number of nest to be pledged
        uint needNest1k = ((biteNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);

        // Freeze nest
        uint accountIndex = _addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        if (tokenAddress == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1000 ether;
        } else {
            _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether);        
        }

        // Freeze token
        _freeze(balances, tokenAddress, needTokenValue + decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum);

        // 6. Update the biten sheet
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal - biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal + biteNum);
        sheets[index] = sheet;

        // 7. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 8. Create price sheet
        emit Post(tokenAddress, msg.sender, sheets.length, uint32(biteNum << 1), newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(biteNum << 1), needNest1k, level, newTokenAmountPerEth);
    }

    // Create price sheet
    function _createPriceSheet(
        PriceSheet[] storage sheets, 
        uint accountIndex, 
        uint32 ethNum, 
        uint nestNum1k, 
        uint level, 
        uint tokenAmountPerEth
    ) private {
        
        (uint48 fraction, uint8 exponent) = encodeFloat(tokenAmountPerEth);
        sheets.push(PriceSheet(
            uint32(accountIndex),                       // uint32 miner;
            uint32(block.number),                       // uint32 height;
            ethNum,                                     // uint32 remainNum;
            ethNum,                                     // uint32 ethNumBal;
            ethNum,                                     // uint32 tokenNumBal;
            uint32(nestNum1k),                          // uint32 nestNum1k;
            uint8(level),                               // uint8 level;
            exponent,                                   // uint8 priceExponent;
            fraction                                    // uint48 priceFraction;
        ));
    }
    
    // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 2400000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 24 million blocks, about 10 years
    uint constant NEST_REDUCTION_LIMIT = NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant NEST_REDUCTION_STEPS =
        0
        | (uint(400 / uint(1)) << (16 * 0))
        | (uint(400 * 8 / uint(10)) << (16 * 1))
        | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        | (uint(40) << (16 * 10));

    // Calculation of attenuation gradient
    function _redution(uint delta) private pure returns (uint) {
        
        if (delta < NEST_REDUCTION_LIMIT) {
            return (NEST_REDUCTION_STEPS >> ((delta / NEST_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (NEST_REDUCTION_STEPS >> 160) & 0xFFFF;
    }

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param tokenAddress The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address tokenAddress, uint index) override external {
        
        Config memory config = _config;
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;

        // Load the price channel
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        // Call _close() method to close price sheet
        (uint accountIndex, Tunple memory total) = _close(config, sheets, index, tokenAddress, ntokenAddress);

        if (accountIndex > 0) {
            // Return eth
            if (uint128(total.ethNum) > 0) {
                payable(address(uint160(indexAddress(accountIndex)))).transfer(uint(total.ethNum) * 1 ether);
            }
            // Freeze assets
            _unfreeze3(_accounts[accountIndex].balances, tokenAddress, uint(total.tokenValue), ntokenAddress, uint(total.ntokenValue), uint(total.nestValue));
        }

        // Calculate the price
        _stat(channel, sheets, uint(config.priceEffectSpan));
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint32[] memory indices) override external {
        _closeList(_config, _channels[tokenAddress], tokenAddress, indices);
    }

    /// @notice Close two batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress1 The address of TOKEN1 contract
    /// @param indices1 A list of indices of sheets w.r.t. `token1`
    /// @param tokenAddress2 The address of TOKEN2 contract
    /// @param indices2 A list of indices of sheets w.r.t. `token2`
    function closeList2(address tokenAddress1, uint32[] memory indices1, address tokenAddress2, uint32[] memory indices2) override external {
        
        Config memory config = _config;
        mapping(address=>PriceChannel) storage channels = _channels;
        _closeList(config, channels[tokenAddress1], tokenAddress1, indices1);
        _closeList(config, channels[tokenAddress2], tokenAddress2, indices2);
    }

    // Calculation blocks which mined
    function _calcMinedBlocks(PriceSheet[] storage sheets, uint index, uint height) private view returns (uint minedBlocks, uint count) {

        uint length = sheets.length;
        uint i = index;
        count = 1;
        
        // Backward looking for sheets in the same block
        while (++i < length && uint(sheets[i].height) == height) {
            
            // Multiple sheets in the same block is a small probability event at present, so it can be ignored 
            // to read more than once, if there are always multiple sheets in the same block, it means that the 
            // sheets are very intensive, and the gas consumed here does not have a great impact
            if (uint(sheets[i].level) == 0) {
                ++count;
            }
        }

        i = index;
        // Find sheets in the same block forward
        uint prev = height;
        while (i > 0 && uint(prev = sheets[--i].height) == height) {

            // Multiple sheets in the same block is a small probability event at present, so it can be ignored 
            // to read more than once, if there are always multiple sheets in the same block, it means that the 
            // sheets are very intensive, and the gas consumed here does not have a great impact
            if (uint(sheets[i].level) == 0) {
                ++count;
            }
        }

        if (i == 0 && sheets[i].height == height) {
            // TODO: Consider how to calculate the first sheet
            //minedBlocks = 10;
            return (10, count);
        } else {
            //minedBlocks = height - prev;
            return (height - prev, count);
        }
    }

    // This structure is for the _close() method to return multiple values
    struct Tunple {
        uint128 ethNum;
        uint128 tokenValue;
        uint128 nestValue;
        uint128 ntokenValue;
    }

    // Close price sheet
    function _close(Config memory config, PriceSheet[] storage sheets, uint index, address tokenAddress, address ntokenAddress) private returns (uint accountIndex, Tunple memory value) {
        
        PriceSheet memory sheet = sheets[index];

        // Check the status of the price sheet to see if it has reached the effective block interval or has been finished
        if ((accountIndex = uint(sheet.miner)) > 0 && (uint(sheet.height) + uint(config.priceEffectSpan) < block.number || uint(sheet.remainNum) == 0)) {
            // Set sheet.miner to 0, express the sheet is closed
            sheet.miner = uint32(0);
            // The price which is bite or ntoken dosen't mining
            if (uint(sheet.level) > 0 || tokenAddress == ntokenAddress) {
                value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
                value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
            } 
            // Mining logic
            else {
                
                (uint minedBlocks, uint count) = _calcMinedBlocks(sheets, index, uint(sheet.height));
                // nest mining
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                    value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
                    value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether + minedBlocks * _redution(block.number - NEST_GENESIS_BLOCK) * 1 ether * uint(config.minerNestReward) / 10000 / count);
                } 
                // ntoken mining
                else {
                    // The limit blocks can be mined
                    if (minedBlocks > uint(config.ntokenMinedBlockLimit)) {
                        minedBlocks = uint(config.ntokenMinedBlockLimit);
                    }
                    
                    uint mined = (minedBlocks * _redution(block.number - _getNTokenGenesisBlock(ntokenAddress)) * 0.01 ether) / count;
                    // ntoken bidders
                    address bidder = INToken(ntokenAddress).checkBidder();
                    // New ntoken
                    if (bidder == address(this)) {
                        value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
                        value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
                        value.ntokenValue = uint128(mined);
                        // TODO：Put this logic into widhdran() method to reduce gas consumption
                        // mining
                        INToken(ntokenAddress).mint(mined, address(this));
                    }
                    // Legacy ntoken
                    else {
                        value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
                        value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
                        value.ntokenValue = uint128(mined * uint(config.minerNTokenReward) / 10000);
                        // Considering that multiple sheets in the same block are small probability events, 
                        // we can send token to bidders in each closing operation
                        // 5% for bidder
                        _unfreeze(_accounts[_addressIndex(bidder)].balances, ntokenAddress, mined * (10000 - uint(config.minerNTokenReward)) / 10000);
                        
                        // TODO：Put this logic into widhdran() method to reduce gas consumption
                        // mining
                        INest_NToken(ntokenAddress).increaseTotal(mined);
                    }
                }
            }

            value.ethNum = uint128(sheet.ethNumBal);
            sheet.ethNumBal = uint32(0);
            sheet.tokenNumBal = uint32(0);
            sheets[index] = sheet;
        }
    }

    // Batch close sheets
    function _closeList(Config memory config, PriceChannel storage channel, address tokenAddress, uint32[] memory indices) private {

        PriceSheet[] storage sheets = channel.sheets;
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        uint accountIndex = 0; 
        Tunple memory total;

        // 1. Traverse sheets
        for (uint i = 0; i < indices.length; ++i) {

            // Because too many variables need to be returned, too many variables will be defined, so the structure of tunple is defined
            (uint minerIndex, Tunple memory value) = _close(config, sheets, uint(indices[i]), tokenAddress, ntokenAddress);
            // Batch closing quotation can only close sheet of the same user
            if (accountIndex == 0) {
                // accountIndex == 0 means the first sheet, and the number of this sheet is taken
                accountIndex = minerIndex;
            } else {
                // accountIndex != 0 means that it is a follow-up sheet, and the miner number must be consistent with the previous record
                require(accountIndex == minerIndex, "NM:!miner");
            }

            total.ethNum += value.ethNum;
            total.tokenValue += value.tokenValue;
            total.nestValue += value.nestValue;
            total.ntokenValue += value.ntokenValue;
        }

        // Return eth
        if (uint128(total.ethNum) > 0) {
            payable(address(uint160(indexAddress(accountIndex)))).transfer(uint(total.ethNum) * 1 ether);
        }
        // Unfreeze assets
        _unfreeze3(_accounts[accountIndex].balances, tokenAddress, uint(total.tokenValue), ntokenAddress, uint(total.ntokenValue), uint(total.nestValue));

        _stat(channel, sheets, uint(config.priceEffectSpan));
    }

    function _stat(PriceChannel storage channel, PriceSheet[] storage sheets, uint priceEffectSpan) private {

        // Load token price information
        PriceInfo memory p0 = channel.price;
        
        // Length of sheets
        uint length = sheets.length;
        // The index of the sheet to be processed in the sheet array
        uint index = uint(p0.index);
        // The latest block number for which the price has been calculated
        uint prev = uint(p0.height);
        // Eth count variable used to calculate price
        uint totalEth = 0; 
        // Token count variable for price calculation
        uint totalTokenValue = 0; 
        // Block number of current sheet
        uint height;
        // Current price
        uint price;

        // Traverse the sheets to find the effective price
        PriceSheet memory sheet;
        for (; ; ) {
            
            // Traverse the sheets that has reached the effective interval from the current position
            bool flag = index < length && (height = uint((sheet = sheets[index]).height)) + priceEffectSpan < block.number;

            // The same block, and the flag is true, the cumulative count
            if (prev == height && flag) {
                totalEth += uint(sheet.remainNum);
                totalTokenValue += decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
            }
            // Not the same block (or flag is false), calculate the price and update it
            else {
                // totalEth > 0 Can calculate the price
                if (totalEth > 0) {

                    // New price
                    price = totalTokenValue / totalEth;

                    // Calculate average price and Volatility
                    // Calculation method of volatility of follow-up price
                    if (prev > 0) {
                        // Calculate average price
                        // avgPrice[i + 1] = avgPrice[i] * 95% + price[i] * 5%
                        (p0.avgFraction, p0.avgExponent) = encodeFloat((decodeFloat(p0.avgFraction, p0.avgExponent) * 19 + price) / 20);

                        //if (height > uint(p0.height)) 
                        {
                            uint tmp = (price << 24) / decodeFloat(p0.priceFraction, p0.priceExponent);
                            if (tmp > 0x1000000) {
                                tmp = tmp - 0x1000000;
                            } else {
                                tmp = 0x1000000 - tmp;
                            }

                            // earn = price[i] / price[i - 1] - 1;
                            // seconds = time[i] - time[i - 1];
                            // sigmaSQ[i + 1] = sigmaSQ[i] * 95% + (earn ^ 2 / seconds) * 5%
                            tmp = (uint(p0.sigmaSQ) * 19 + tmp * tmp / ETHEREUM_BLOCK_TIMESPAN / (height - uint(p0.height))) / 20;

                            // The current implementation assumes that the volatility cannot exceed 1, and 
                            // corresponding to this, when the calculated value exceeds 1, expressed as 0xFFFFFFFFFFFF
                            if (tmp > 0xFFFFFFFFFFFF) {
                                tmp = 0xFFFFFFFFFFFF;
                            }
                            p0.sigmaSQ = uint48(tmp);
                        }
                    } 
                    // The calculation methods of average price and volatility are different for first price
                    else {
                        // The average price is equal to the price
                        //p0.avgTokenAmount = uint64(price);
                        (p0.avgFraction, p0.avgExponent) = encodeFloat(price);

                        // The volatility is 0
                        p0.sigmaSQ = uint48(0);
                    }

                    // Update price block number
                    p0.height = uint32(prev);
                    // Update price
                    p0.remainNum = uint32(totalEth);
                    //p0.tokenAmount = uint64(totalTokenValue);
                    (p0.priceFraction, p0.priceExponent) = encodeFloat(totalTokenValue / totalEth);

                    // Move to new block number
                    prev = height;
                }

                // Clear cumulative values
                totalEth = uint(sheet.remainNum);
                totalTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
            }

            if (!flag) {
                break;
            }
            ++index;
        }

        // Update price infomation
        if (index > uint(p0.index)) {
            p0.index = uint32(index);
            p0.height = uint32(prev);
            channel.price = p0;
        }
    }

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function stat(address tokenAddress) override external {
        PriceChannel storage channel = _channels[tokenAddress];
        _stat(channel, channel.sheets, uint(_config.priceEffectSpan));
    }

    // Deposit the accumulated dividends into nest ledger
    function _collect(PriceChannel storage channel, address ntokenAddress, uint length, uint currentFee, uint newFee) private {

        uint feeInfo = channel.feeInfo;
        uint oldFee = feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        
        if (currentFee == 0) {
            channel.feeInfo = newFee | (((feeInfo >> 128) + 1) << 128);
        } else if (length & COLLECT_REWARD_MASK == COLLECT_REWARD_MASK || newFee != oldFee) {
            INestLedger(_nestLedgerAddress).carveReward { 
                value: currentFee + oldFee * (COLLECT_REWARD_MASK - (feeInfo >> 128)) 
            } (ntokenAddress);
            // Update fee information
            if (newFee == oldFee) {
                // The current accumulated sheet quantity that does not require Commission is cleared, so there is no need to assign a value to the upper 128 bits
                channel.feeInfo = newFee;
            } else {
                // Update fee information
                // The current accumulated sheet quantity that does not require Commission is cleared, so there is no need to assign a value to the upper 128 bits
                channel.feeInfo = newFee | (((length & COLLECT_REWARD_MASK) + 1) << 128);
            }
        }
    }

    /// @dev Settlement Commission
    /// @param tokenAddress The token address
    function settle(address tokenAddress) override external {
        
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        if (tokenAddress != ntokenAddress) {

            PriceChannel storage channel = _channels[tokenAddress];
            uint count = channel.sheets.length & COLLECT_REWARD_MASK;
            uint feeInfo = channel.feeInfo;

            INestLedger(_nestLedgerAddress).carveReward { 
                value: (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) * (count - (feeInfo >> 128)) 
            } (ntokenAddress);

            // Manual settlement does not need to update Commission variables
            channel.feeInfo = (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | (count << 128);
        }
    }

    // Convert PriceSheet to PriceSheetView
    function _toPriceSheetView(PriceSheet memory sheet, uint index) private view returns (PriceSheetView memory) {

        return PriceSheetView(
            // Index number
            uint32(index),
            // Miner address
            indexAddress(sheet.miner),
            // The block number of this price sheet packaged
            uint32(sheet.height),
            // The remain number of this price sheet
            uint32(sheet.remainNum),
            // The eth number which miner will got
            uint32(sheet.ethNumBal),
            // The eth number which equivalent to token's value which miner will got
            uint32(sheet.tokenNumBal),
            // The pledged number of nest in this sheet. (unit: 1000nest)
            uint32(sheet.nestNum1k),
            // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
            uint8(sheet.level),
            // Price
            uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent))
        );
    }

    /// @dev List sheets by page
    /// @param tokenAddress Destination token address
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(address tokenAddress, uint offset, uint count, uint order) override external view returns (PriceSheetView[] memory) {
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheetView[] memory result = new PriceSheetView[](count);
        uint i = 0;

        // Reverse order
        if (order == 0) {

            uint index = sheets.length - offset;
            uint end = index - count;
            while (index-- > end) {
                result[i++] = _toPriceSheetView(sheets[index], index);
            }
        } 
        // positive order
        else {
            
            uint index = offset;
            uint end = index + count;
            while (index < end) {
                result[i++] = _toPriceSheetView(sheets[index], index);
                ++index;
            }
        }
        return result;
    }

    /// @dev Estimated ore yield
    /// @param tokenAddress Destination token address
    /// @return Estimated ore yield
    function estimate(address tokenAddress) override external view returns (uint) {

        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        uint index = sheets.length;
        while (index > 0) {

            PriceSheet memory sheet = sheets[--index];
            if (uint(sheet.level) == 0) {
                
                uint blocks = (block.number - uint(sheet.height));
                if (tokenAddress == NEST_TOKEN_ADDRESS) {
                    return blocks * _redution(block.number - NEST_GENESIS_BLOCK) * 1 ether;
                }
                
                (uint blockNumber,) = INToken(INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress)).checkBlockInfo();
                return blocks * _redution(block.number - blockNumber) * 0.01 ether;
            }
        }

        return 0;
    }

    /// @dev Query the quantity of the target quotation
    /// @param tokenAddress Token address. The token can't mine. Please make sure you don't use the token address when calling
    /// @param index The index of the sheet
    function getMinedBlocks(address tokenAddress, uint index) override external view returns (uint minedBlocks, uint count) {
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet = sheets[index];
        
        // The bite sheet or ntoken sheet dosen't mining
        if (sheet.level > 0 /*|| INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress) == tokenAddress*/) {
            return (0, 0);
        }

        return _calcMinedBlocks(sheets, index, uint(sheet.height));
    }

    /* ========== Accounts ========== */

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    /// @return Actually withdrawn
    function withdraw(address tokenAddress, uint value) override external returns (uint) {

        // TODO: The user's locked nest and the mining pool's nest are stored together. When the nest is dug up, 
        // the problem of taking the locked nest as the ore drawing will appear
        // As it will take a long time for nest to finish mining, this problem will not be considered for the time being
        Account storage account = _accounts[_accountMapping[msg.sender]];
        uint balance = account.balances[tokenAddress].value;
        require(balance >= value, "NM:!balance");
        account.balances[tokenAddress].value = balance - value;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);

        return value;
    }

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) override external view returns (uint) {
        return _accounts[_accountMapping[addr]].balances[tokenAddress].value;
    }

    /// @dev Gets the index number of the specified address. If it does not exist, register
    /// @param addr Destination address
    /// @return The index number of the specified address
    function _addressIndex(address addr) private returns (uint) {

        uint index = _accountMapping[addr];
        if (index == 0) {
            // If it exceeds the maximum number that 32 bits can store, you can't continue to register a new account. 
            // If you need to support a new account, you need to update the contract
            require((_accountMapping[addr] = index = _accounts.length) < 0x100000000, "NM:!accounts");
            _accounts.push().addr = addr;
        }

        return index;
    }

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) override public view returns (address) {
        return _accounts[index].addr;
    }

    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) override external view returns (uint) {
        return _accountMapping[addr];
    }

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() override external view returns (uint) {
        return _accounts.length;
    }

    /* ========== Asset management ========== */

    /// @dev Freeze token
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param value token amount
    function _freeze(mapping(address=>UINT) storage balances, address tokenAddress, uint value) private {

        UINT storage balance = balances[tokenAddress];
        uint balanceValue = balance.value;
        if (balanceValue < value) {
            TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), value - balanceValue);
            balance.value = 0;
        } else {
            balance.value = (balanceValue - value);
        }
    }

    /// @dev Unfreeze token
    /// @param balances Balances ledgerBalances ledger
    /// @param tokenAddress Destination token address
    /// @param value token amount
    function _unfreeze(mapping(address=>UINT) storage balances, address tokenAddress, uint value) private {
        UINT storage balance = balances[tokenAddress];
        balance.value = balance.value + value;
    }

    /// @dev freeze token and nest
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount 
    /// @param nestValue nest amount
    function _freeze2(mapping(address=>UINT) storage balances, address tokenAddress, uint tokenValue, uint nestValue) private {

        UINT storage balance = balances[tokenAddress];
        uint balanceValue = balance.value;
        if (balanceValue < tokenValue) {
            TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenValue - balanceValue);
            balance.value = 0;
        } else {
            balance.value = balanceValue - tokenValue;
        }

        balance = balances[NEST_TOKEN_ADDRESS];
        balanceValue = balance.value;
        if (balanceValue < nestValue) {
            TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestValue - balanceValue);
            balance.value = 0;
        } else {
            balance.value = balanceValue - nestValue;
        }
    }

    // /// @dev Unfreeze token and nest
    // /// @param balances Balances ledger
    // /// @param tokenAddress Destination token address
    // /// @param tokenValue token amount
    // /// @param nestValue nest amount
    // function _unfreeze2(mapping(address=>UINT) storage balances, address tokenAddress, uint tokenValue, uint nestValue) private {

    //     UINT storage balance = balances[tokenAddress];
    //     balance.value = balance.value + tokenValue;

    //     balance = balances[NEST_TOKEN_ADDRESS];
    //     balance.value = balance.value + nestValue;
    // }

    // /// @dev Freeze token, ntoken and nest
    // /// @param balances Balances ledger
    // /// @param tokenAddress Destination token address
    // /// @param tokenValue token amount
    // /// @param ntokenAddress Destination ntoken address
    // /// @param ntokenValue ntoken amount
    // /// @param nestValue nest amount
    // function _freeze3(mapping(address=>UINT) storage balances, address tokenAddress, uint tokenValue, address ntokenAddress, uint ntokenValue, uint nestValue) private {

    //     UINT storage balance = balances[tokenAddress];
    //     uint balanceValue = balance.value;
    //     if (balanceValue < tokenValue) {
    //         TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenValue - balanceValue);
    //         balance.value = 0;
    //     } else {
    //         balance.value = balanceValue - tokenValue;
    //     }

    //     balance = balances[ntokenAddress];
    //     balanceValue = balance.value;
    //     if (balanceValue < ntokenValue) {
    //         TransferHelper.safeTransferFrom(ntokenAddress, msg.sender, address(this), ntokenValue - balanceValue);
    //         balance.value = 0;
    //     } else {
    //         balance.value = balanceValue - ntokenValue;
    //     }

    //     balance = balances[NEST_TOKEN_ADDRESS];
    //     balanceValue = balance.value;
    //     if (balanceValue < nestValue) {
    //         TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestValue - balanceValue);
    //         balance.value = 0;
    //     } else {
    //         balance.value = balanceValue - nestValue;
    //     }
    // }

    /// @dev Unfreeze token, ntoken and nest
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount 
    /// @param ntokenAddress Destination ntoken address
    /// @param ntokenValue ntoken amount
    /// @param nestValue nest amount
    function _unfreeze3(mapping(address=>UINT) storage balances, address tokenAddress, uint tokenValue, address ntokenAddress, uint ntokenValue, uint nestValue) private {

        //mapping(address=>UINT) storage balances = accounts[addressIndex(msg.sender)].balances;
        UINT storage balance = balances[tokenAddress];
        balance.value = balance.value + tokenValue;

        balance = balances[ntokenAddress];
        balance.value = balance.value + ntokenValue;

        balance = balances[NEST_TOKEN_ADDRESS];
        balance.value = balance.value + nestValue;
    }

    /* ========== INestQuery ========== */
    
    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(address tokenAddress) override public view returns (uint blockNumber, uint price) {

        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);
        PriceInfo memory priceInfo = _channels[tokenAddress].price;
        if (uint(priceInfo.remainNum) > 0) {
            return (uint(priceInfo.height), decodeFloat(priceInfo.priceFraction, priceInfo.priceExponent));
        }
        return (0, 0);
    }

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    //          the volatility cannot exceed 1. Correspondingly, when the return value is equal to 9999999999996447, 
    //          it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(address tokenAddress) override public view returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ) {
        
        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);
        PriceInfo memory priceInfo = _channels[tokenAddress].price;

        return (
            uint(priceInfo.height), 
            decodeFloat(priceInfo.priceFraction, priceInfo.priceExponent),
            decodeFloat(priceInfo.avgFraction, priceInfo.avgExponent),
            (uint(priceInfo.sigmaSQ) * 1 ether) >> 48 // 波动率的平方
        );
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(address tokenAddress) override public view returns (uint blockNumber, uint price) {

        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);

        Config memory config = _config;
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        uint index = sheets.length;

        // Find the effective sheet index
        while (index > 0) { 
            PriceSheet memory sheet = sheets[--index];
            if (uint(sheet.height) + uint(config.priceEffectSpan) < block.number && uint(sheet.remainNum) > 0) {
                
                // Calculate the price according to the sheet in the block
                // Destination block number
                uint height = uint(sheet.height);
                uint totalEth = uint(sheet.remainNum);
                uint totalTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
                
                // Traverse the sheet in the block
                while (index > 0 && uint(sheets[--index].height) == height) {
                    
                    // Find the sheet
                    sheet = sheets[index];

                    // Cumulative eth quantity
                    totalEth += uint(sheet.remainNum);

                    // Cumulative number of tokens
                    totalTokenValue += decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
                }

                // totalEth Must be greater than 0
                return (height, totalTokenValue / totalEth);
            }
        }

        return (0, 0);
    }

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param tokenAddress Destination token address
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places)
    function latestPriceAndTriggeredPriceInfo(address tokenAddress) override external view 
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        (latestPriceBlockNumber, latestPriceValue) = latestPrice(tokenAddress);
        (triggeredPriceBlockNumber, triggeredPriceValue, triggeredAvgPrice, triggeredSigmaSQ) = triggeredPriceInfo(tokenAddress);
    }

    /// @dev Get the latest trigger price. (token and ntoken）
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function triggeredPrice2(address tokenAddress) override external returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice) {
        (blockNumber, price) = triggeredPrice(tokenAddress);
        (ntokenBlockNumber, ntokenPrice) = triggeredPrice(_getNTokenAddress(tokenAddress));
    }

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
    function triggeredPriceInfo2(address tokenAddress) override external returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ, uint ntokenBlockNumber, uint ntokenPrice, uint ntokenAvgPrice, uint ntokenSigmaSQ) {
        (blockNumber, price, avgPrice, sigmaSQ) = triggeredPriceInfo(tokenAddress);
        (ntokenBlockNumber, ntokenPrice, ntokenAvgPrice, ntokenSigmaSQ) = triggeredPriceInfo(_getNTokenAddress(tokenAddress));
    }

    /// @dev Get the latest effective price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function latestPrice2(address tokenAddress) override external returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice) {
        (blockNumber, price) = latestPrice(tokenAddress);
        (ntokenBlockNumber, ntokenPrice) = latestPrice(_getNTokenAddress(tokenAddress));
    }

    /* ========== Tools and methods ========== */

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return fraction fraction value
    /// @return exponent exponent value
    function encodeFloat(uint value) public pure returns (uint48 fraction, uint8 exponent) {
        
        uint decimals = 0; 
        while (value > 0xFFFFFFFFFFFF /* 281474976710655 */) {
            value >>= 4;
            ++decimals;
        }

        return (uint48(value), uint8(decimals));
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param fraction fraction value
    /// @param exponent exponent value
    function decodeFloat(uint fraction, uint exponent) public pure returns (uint) {
        return fraction << (exponent << 2);
    }
}