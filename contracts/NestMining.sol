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

/// @dev This contract implemented the mining logic of nest
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
    uint constant DIMI_ETHER = 0.0001 ether; // 1 ether / 10000;

    /// @dev The mask of batch settlement dividend. During the test, it is settled once every 16 sheets and 
    ///      once every 256 sheets of the online version
    uint constant COLLECT_REWARD_MASK = 0xF;
    
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
            //address ntokenMiningAddress
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

    // /// @dev Clear chache of token. while ntoken recreated, this method is need to call
    // /// @param tokenAddress Token address
    // function resetNTokenCache(address tokenAddress) external onlyGovernance {

    //     // Clear cache
    //     address ntokenAddress = _getNTokenAddress(tokenAddress);
    //     _genesisBlockNumberCache[ntokenAddress] = 0;
    //     _addressCache[tokenAddress] = _addressCache[ntokenAddress] = address(0);

    //     // Reload
    //     _getNTokenAddress(tokenAddress);
    //     _getNTokenAddress(ntokenAddress);
    //     _getNTokenGenesisBlock(ntokenAddress);
    // }

    /// @dev Set the ntokenAddress from tokenAddress, if ntokenAddress is equals to tokenAddress, means the token is disabled
    /// @param tokenAddress Destination token address
    /// @param ntokenAddress The ntoken address
    function setNTokenAddress(address tokenAddress, address ntokenAddress) override external onlyGovernance {
        _addressCache[tokenAddress] = ntokenAddress;
    }

    /// @dev Get the ntokenAddress from tokenAddress, if ntokenAddress is equals to tokenAddress, means the token is disabled
    /// @param tokenAddress Destination token address
    /// @return The ntoken address
    function getNTokenAddress(address tokenAddress) override external view returns (address) {
        return _addressCache[tokenAddress];
    }

    /* ========== Mining ========== */

    // Get ntoken address of from token address
    function _getNTokenAddress(address tokenAddress) private returns (address) {
        
        address ntokenAddress = _addressCache[tokenAddress];
        if (ntokenAddress == address(0)) {
            if (
                (ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress)) 
                    != address(0)
            ) {
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
        
        // 2. Check price channel
        // Check if the token allow post()
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");
        // Unit of nest is different, but the total supply already exceeded the number of this issue. No additional judgment will be made
        // ntoken is mint when the price sheet is closed (or retrieved), this may be the problem that the user 
        // intentionally does not close or retrieve, which leads to the inaccurate judgment of the total amount. ignore
        require(IERC20(ntokenAddress).totalSupply() < uint(config.doublePostThreshold) * 10000 ether, "NM:!post2");        

        // 3. Load token channel and sheets
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;

        // 4. Freeze assets
        uint accountIndex = _addressIndex(msg.sender);
        // Freeze token and nest
        // Because of the use of floating-point representation(uint48 fraction, uint8 exponent), it may bring some precision loss
        // After assets are frozen according to tokenAmountPerEth * ethNum, the part with poor accuracy may be lost when the assets are returned
        // It should be frozen according to decodeFloat(fraction, exponent) * ethNum
        // However, considering that the loss is less than 1 / 10 ^ 14, the loss here is ignored, and the part of 
        // precision loss can be transferred out as system income in the future
        _freeze2(
            _accounts[accountIndex].balances, 
            tokenAddress, 
            tokenAmountPerEth * ethNum, 
            uint(config.pledgeNest) * 1000 ether
        );

        // 5. Deposit fee
        // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
        uint length = sheets.length;
        uint shares = _collect(config, channel, ntokenAddress, length, msg.value - ethNum * 1 ether);
        require(shares > 0 && shares < 256, "NM:!fee");

        // Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 6. Create token price sheet
        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), uint(config.pledgeNest), shares, tokenAmountPerEth);
    }

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(
        address tokenAddress, 
        uint ethNum, 
        uint tokenAmountPerEth, 
        uint ntokenAmountPerEth
    ) override external payable {

        Config memory config = _config;

        // 1. Check arguments
        require(ethNum > 0 && ethNum == uint(config.postEthUnit), "NM:!ethNum");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "NM:!price");
        
        // 2. Check price channel
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");

        // 3. Load token channel and sheets
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;

        // 4. Freeze assets
        uint pledgeNest = uint(config.pledgeNest);
        uint accountIndex = _addressIndex(msg.sender);
        {
            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
            _freeze(balances, tokenAddress, ethNum * tokenAmountPerEth);
            // if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            //     _freeze(balances, NEST_TOKEN_ADDRESS, ethNum * ntokenAmountPerEth + pledgeNest * 2000 ether);
            // } else {
            //     _freeze2(balances, ntokenAddress, ethNum * ntokenAmountPerEth, pledgeNest * 2000 ether);
            // }
            _freeze2(balances, ntokenAddress, ethNum * ntokenAmountPerEth, pledgeNest * 2000 ether);
        }
        
        // 5. Deposit fee
        // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
        uint length = sheets.length;
        uint shares = _collect(config, channel, ntokenAddress, length, msg.value - ethNum * 2 ether);
        require(shares > 0 && shares < 256, "NM:!fee");

        // Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 6. Create token price sheet
        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), pledgeNest, shares, tokenAmountPerEth);

        // 7. Load ntoken channel and sheets
        channel = _channels[ntokenAddress];
        sheets = channel.sheets;
        
        // Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);
        
        // 8. Create token price sheet
        emit Post(ntokenAddress, msg.sender, sheets.length, ethNum, ntokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), pledgeNest, 0, ntokenAmountPerEth);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(
        address tokenAddress, 
        uint index, 
        uint biteNum, 
        uint newTokenAmountPerEth
    ) override external payable {

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
                _collect(config, channel, ntokenAddress, sheets.length, 0);
            }
        }

        // 5. Calculate the number of eth, token and nest needed, and freeze them
        uint needEthNum;
        uint level = uint(sheet.level);

        // When the level of the sheet is less than 4, both the nest and the scale of the offer are doubled
        if (level < uint(config.maxBiteNestedLevel)) {
            // Double scall sheet
            needEthNum = biteNum << 1;
            ++level;
        } 
        // When the level of the sheet reaches 4 or more, nest doubles, but the scale does not
        else {
            // Single scale sheet
            needEthNum = biteNum;
            // It is possible that the length of a single chain exceeds 255. When the length of a chain reaches 4 
            // or more, there is no logical dependence on the specific value of the contract, and the count will 
            // not increase after it is accumulated to 255
            if (level < 255) ++level;
        }
        require(msg.value == (needEthNum + biteNum) * 1 ether, "NM:!value");

        // Number of nest to be pledged
        uint needNest1k = ((biteNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);
        // Freeze nest and token
        uint accountIndex = _addressIndex(msg.sender);
        {
            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
            uint backTokenValue = decodeFloat(sheet.priceFloat) * biteNum;
            if (needEthNum * newTokenAmountPerEth > backTokenValue) {
                _freeze2(
                    balances, 
                    tokenAddress, 
                    needEthNum * newTokenAmountPerEth - backTokenValue, 
                    needNest1k * 1000 ether
                );
            } else {
                _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether);
                _unfreeze(balances, tokenAddress, backTokenValue - needEthNum * newTokenAmountPerEth);
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
        _stat(config, channel, sheets);

        // 8. Create price sheet
        emit Post(tokenAddress, msg.sender, sheets.length, needEthNum, newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(needEthNum), needNest1k, level << 8, newTokenAmountPerEth);
    }

    /// @notice Call the function to buy ETH from a posted price sheet
    /// @dev bite ETH by TOKEN(NTOKEN),  (-ethNumBal, +tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(
        address tokenAddress, 
        uint index, 
        uint biteNum, 
        uint newTokenAmountPerEth
    ) override external payable {

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
                _collect(config, channel, ntokenAddress, sheets.length, 0);
            }
        }

        // 5. Calculate the number of eth, token and nest needed, and freeze them
        uint needEthNum;
        uint level = uint(sheet.level);

        // When the level of the sheet is less than 4, both the nest and the scale of the offer are doubled
        if (level < uint(config.maxBiteNestedLevel)) {
            // Double scale sheet
            needEthNum = biteNum << 1;
            ++level;
        } 
        // When the level of the sheet reaches 4 or more, nest doubles, but the scale does not
        else {
            // Single scale sheet
            needEthNum = biteNum;
            // It is possible that the length of a single chain exceeds 255. When the length of a chain reaches 4 
            // or more, there is no logical dependence on the specific value of the contract, and the count will 
            // not increase after it is accumulated to 255
            if (level < 255) ++level;
        }
        require(msg.value == (needEthNum - biteNum) * 1 ether, "NM:!value");

        // Number of nest to be pledged
        uint needNest1k = ((biteNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);
        // Freeze nest and token
        uint accountIndex = _addressIndex(msg.sender);
        _freeze2(
            _accounts[accountIndex].balances, 
            tokenAddress, 
            needEthNum * newTokenAmountPerEth + decodeFloat(sheet.priceFloat) * biteNum, 
            needNest1k * 1000 ether
        );
            
        // 6. Update the biten sheet
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal - biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal + biteNum);
        sheets[index] = sheet;

        // 7. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price 
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 8. Create price sheet
        emit Post(tokenAddress, msg.sender, sheets.length, needEthNum, newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(needEthNum), needNest1k, level << 8, newTokenAmountPerEth);
    }

    // Create price sheet
    function _createPriceSheet(
        PriceSheet[] storage sheets, 
        uint accountIndex, 
        uint32 ethNum, 
        uint nestNum1k, 
        uint level_shares,
        uint tokenAmountPerEth
    ) private {
        
        sheets.push(PriceSheet(
            uint32(accountIndex),                       // uint32 miner;
            uint32(block.number),                       // uint32 height;
            ethNum,                                     // uint32 remainNum;
            ethNum,                                     // uint32 ethNumBal;
            ethNum,                                     // uint32 tokenNumBal;
            uint24(nestNum1k),                          // uint32 nestNum1k;
            uint8(level_shares >> 8),                   // uint8 level;
            uint8(level_shares & 0xFF),
            encodeFloat(tokenAmountPerEth)
        ));
    }
    
    // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 2400000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 24 million blocks, about 10 years
    uint constant NEST_REDUCTION_LIMIT = 24000000; //NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300a300cc010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));

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
        (uint accountIndex, Tunple memory total) = _close(config, sheets, index, ntokenAddress);

        if (accountIndex > 0) {
            // Return eth
            if (uint(total.ethNum) > 0) {
                payable(indexAddress(accountIndex)).transfer(uint(total.ethNum) * 1 ether);
            }
            // Unfreeze assets
            _unfreeze3(
                _accounts[accountIndex].balances, 
                tokenAddress, 
                total.tokenValue, 
                ntokenAddress, 
                uint(total.ntokenValue), 
                uint(total.nestValue)
            );
        }

        // Calculate the price
        _stat(config, channel, sheets);
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint[] memory indices) override external {
        
        // Call _closeList() method to close price sheets
        (
            uint accountIndex, 
            Tunple memory total, 
            address ntokenAddress
        ) = _closeList(_config, _channels[tokenAddress], tokenAddress, indices);

        // Return eth
        if (uint(total.ethNum) > 0) {
            payable(indexAddress(accountIndex)).transfer(uint(total.ethNum) * 1 ether);
        }
        // Unfreeze assets
        _unfreeze3(
            _accounts[accountIndex].balances, 
            tokenAddress, 
            uint(total.tokenValue), 
            ntokenAddress, 
            uint(total.ntokenValue), 
            uint(total.nestValue)
        );
    }

    /// @notice Close two batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress1 The address of TOKEN1 contract
    /// @param indices1 A list of indices of sheets w.r.t. `token1`
    /// @param tokenAddress2 The address of TOKEN2 contract
    /// @param indices2 A list of indices of sheets w.r.t. `token2`
    function closeList2(
        address tokenAddress1, 
        uint[] memory indices1, 
        address tokenAddress2, 
        uint[] memory indices2
    ) override external {
        
        Config memory config = _config;
        mapping(address=>PriceChannel) storage channels = _channels;
        
        // Call _closeList() method to close price sheets
        (
            uint accountIndex1, 
            Tunple memory value1,
            address ntokenAddress1 
        ) = _closeList(config, channels[tokenAddress1], tokenAddress1, indices1);

        (
            uint accountIndex2, 
            Tunple memory value2,
            //address ntokenAddress2, 
        ) = _closeList(config, channels[tokenAddress2], tokenAddress2, indices2);

        require(accountIndex1 == accountIndex2, "NM:!miner");
        require(ntokenAddress1 == tokenAddress2, "NM:!tokenAddress");
        require(uint(value2.ntokenValue) == 0, "NM!ntokenValue");

        // Return eth
        // if (uint(value1.ethNum) > 0) {
        //     payable(indexAddress(accountIndex1)).transfer(uint(value1.ethNum + value2.ethNum) * 1 ether);
        // }
        payable(indexAddress(accountIndex1)).transfer((uint(value1.ethNum) + uint(value2.ethNum)) * 1 ether);
        // Unfreeze assets
        _unfreeze3(
            _accounts[accountIndex1].balances, 
            tokenAddress1, 
            uint(value1.tokenValue), 
            ntokenAddress1, 
            uint(value1.ntokenValue) + uint(value2.tokenValue) /* + uint(value2.ntokenValue) */, 
            uint(value1.nestValue) + uint(value2.nestValue)
        );
    }

    // Calculation blocks which mined
    function _calcMinedBlocks(
        PriceSheet[] storage sheets, 
        uint index, 
        PriceSheet memory sheet
    ) private view returns (uint minedBlocks, uint totalShares) {

        uint height = uint(sheet.height);
        uint length = sheets.length;
        uint i = index;
        totalShares = uint(sheet.shares);
        
        // Backward looking for sheets in the same block
        while (++i < length && uint(sheets[i].height) == height) {
            
            // Multiple sheets in the same block is a small probability event at present, so it can be ignored 
            // to read more than once, if there are always multiple sheets in the same block, it means that the 
            // sheets are very intensive, and the gas consumed here does not have a great impact
            totalShares += uint(sheets[i].shares);
        }

        //i = index;
        // Find sheets in the same block forward
        uint prev = height;
        while (index > 0 && uint(prev = sheets[--index].height) == height) {

            // Multiple sheets in the same block is a small probability event at present, so it can be ignored 
            // to read more than once, if there are always multiple sheets in the same block, it means that the 
            // sheets are very intensive, and the gas consumed here does not have a great impact
            totalShares += uint(sheets[index].shares);
        }

        if (index > 0 || height > prev) {
            minedBlocks = height - prev;
        } else {
            minedBlocks = 10;
        }
    }

    // This structure is for the _close() method to return multiple values
    struct Tunple {
        uint tokenValue;
        uint64 ethNum;
        uint96 nestValue;
        uint96 ntokenValue;
    }

    // Close price sheet
    function _close(
        Config memory config, 
        PriceSheet[] storage sheets, 
        uint index, 
        address ntokenAddress
    ) private returns (uint accountIndex, Tunple memory value) {
        
        PriceSheet memory sheet = sheets[index];
        uint height = uint(sheet.height);
        
        // Check the status of the price sheet to see if it has reached the effective block interval or has been finished
        if ((accountIndex = uint(sheet.miner)) > 0 && (
            height + uint(config.priceEffectSpan) < block.number 
                || uint(sheet.remainNum) == 0
        )) {

            value.nestValue = uint96(uint(sheet.nestNum1k) * 1000 ether);
            // The price which is bite or ntoken dosen't mining
            // if (uint(sheet.shares) == 0) {
            //     //value.tokenValue = uint128(decodeFloat(sheet.priceFloat) * uint(sheet.tokenNumBal));
            // } 
            // // Mining logic
            // else {
            if (uint(sheet.shares) > 0) {
                (uint minedBlocks, uint totalShares) = _calcMinedBlocks(sheets, index, sheet);

                // nest mining
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {

                    // value.ntokenValue = uint96(
                    //     minedBlocks 
                    //     * uint(sheet.shares) 
                    //     * _redution(height - NEST_GENESIS_BLOCK) 
                    //     * 1 ether 
                    //     * uint(config.minerNestReward) 
                    //     / 10000 
                    //     / totalShares
                    // );
                    // 原来的表达式如上所示，为了节省gas，把可以预先计算的部分先计算掉

                    value.ntokenValue = uint96(
                        minedBlocks 
                        * uint(sheet.shares) 
                        * _redution(height - NEST_GENESIS_BLOCK) 
                        * uint(config.minerNestReward) 
                        * 0.0001 ether 
                        / totalShares
                    );
                } 
                // ntoken mining
                else {

                    // The limit blocks can be mined
                    if (minedBlocks > uint(config.ntokenMinedBlockLimit)) {
                        minedBlocks = uint(config.ntokenMinedBlockLimit);
                    }
                    
                    uint mined = (
                        minedBlocks 
                        * uint(sheet.shares) 
                        * _redution(height - _getNTokenGenesisBlock(ntokenAddress)) 
                        * 0.01 ether
                    ) / totalShares;

                    // ntoken bidders
                    address bidder = INToken(ntokenAddress).checkBidder();
                    // New ntoken
                    if (bidder == address(this)) {
                        value.ntokenValue = uint96(mined);
                        // TODO：Put this logic into widhdran() method to reduce gas consumption
                        // mining
                        INToken(ntokenAddress).mint(mined, address(this));
                    }
                    // Legacy ntoken
                    else {
                        value.ntokenValue = uint96(mined * uint(config.minerNTokenReward) / 10000);
                        // Considering that multiple sheets in the same block are small probability events, 
                        // we can send token to bidders in each closing operation
                        // 5% for bidder
                        _unfreeze(
                            _accounts[_addressIndex(bidder)].balances, 
                            ntokenAddress, 
                            mined * (10000 - uint(config.minerNTokenReward)) / 10000
                        );
                        
                        // TODO：Put this logic into widhdran() method to reduce gas consumption
                        // mining
                        INest_NToken(ntokenAddress).increaseTotal(mined);
                    }
                    //value.nestValue = uint96(uint(sheet.nestNum1k) * 1000 ether);
                }
            }

            value.tokenValue = decodeFloat(sheet.priceFloat) * uint(sheet.tokenNumBal);
            value.ethNum = uint64(sheet.ethNumBal);
            
            // Set sheet.miner to 0, express the sheet is closed
            sheet.miner = uint32(0);
            sheet.ethNumBal = uint32(0);
            sheet.tokenNumBal = uint32(0);
            sheets[index] = sheet;
        }
    }

    // Batch close sheets
    function _closeList(
        Config memory config, 
        PriceChannel storage channel, 
        address tokenAddress, 
        uint[] memory indices
    ) private returns (uint accountIndex, Tunple memory total, address ntokenAddress) {

        ntokenAddress = _getNTokenAddress(tokenAddress);
        PriceSheet[] storage sheets = channel.sheets;
        accountIndex = 0; 

        // 1. Traverse sheets
        for (uint i = indices.length; i > 0;) {

            // Because too many variables need to be returned, too many variables will be defined, so the structure of tunple is defined
            (uint minerIndex, Tunple memory value) = _close(config, sheets, indices[--i], ntokenAddress);
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
            total.ntokenValue += value.ntokenValue;
            total.nestValue += value.nestValue;
        }

        _stat(config, channel, sheets);
    }

    function _stat(Config memory config, PriceChannel storage channel, PriceSheet[] storage sheets) private {

        uint priceEffectSpan = config.priceEffectSpan;
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
            bool flag = index < length;
            if (flag) {
                sheet = sheets[index];
                height = uint(sheet.height);
                totalEth += uint(sheet.remainNum);
                totalTokenValue += decodeFloat(sheet.priceFloat) * uint(sheet.remainNum);
                flag = height + priceEffectSpan < block.number;
            }
            
            // Not the same block (or flag is false), calculate the price and update it
            if (!flag || prev != height) {
                // totalEth > 0 Can calculate the price
                if (totalEth > 0) {

                    // New price
                    price = totalTokenValue / totalEth;

                    // Calculate average price and Volatility
                    // Calculation method of volatility of follow-up price
                    if (prev > 0) {
                        // Calculate average price
                        // avgPrice[i + 1] = avgPrice[i] * 95% + price[i] * 5%
                        p0.avgFloat = encodeFloat((decodeFloat(p0.avgFloat) * 19 + price) / 20);

                        //if (height > uint(p0.height)) 
                        {
                            // 可能存在溢出问题
                            uint tmp = (price << 48) / decodeFloat(p0.priceFloat);
                            if (tmp > 0x1000000000000) {
                                tmp = tmp - 0x1000000000000;
                            } else {
                                tmp = 0x1000000000000 - tmp;
                            }

                            // earn = price[i] / price[i - 1] - 1;
                            // seconds = time[i] - time[i - 1];
                            // sigmaSQ[i + 1] = sigmaSQ[i] * 95% + (earn ^ 2 / seconds) * 5%
                            tmp = (
                                uint(p0.sigmaSQ) * 19 + 
                                ((tmp * tmp / ETHEREUM_BLOCK_TIMESPAN / (height - uint(p0.height))) >> 48)
                            ) / 20;

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
                        p0.avgFloat = encodeFloat(price);

                        // The volatility is 0
                        p0.sigmaSQ = uint48(0);
                    }

                    // Update price block number
                    p0.height = uint32(prev);
                    // Update price
                    p0.remainNum = uint32(totalEth);
                    p0.priceFloat = encodeFloat(totalTokenValue / totalEth);

                    // // TODO: 移动到外面
                    // // by chenf 2021-03027
                    // // Move to new block number
                    // prev = height;
                }

                // Clear cumulative values
                totalEth = 0;
                totalTokenValue = 0;
                    // TODO: 移动到外面
                    // by chenf 2021-03027
                    // Move to new block number
                    prev = height;
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
        _stat(_config, channel, channel.sheets);
    }

    // Deposit the accumulated dividends into nest ledger
    function _collect(
        Config memory config, 
        PriceChannel storage channel, 
        address ntokenAddress, 
        uint length, 
        uint currentFee
    ) private returns (uint) {

        uint newFeeUnit = uint(config.postFeeUnit) * DIMI_ETHER;
        require(currentFee % newFeeUnit == 0, "NM:!fee");
        uint feeInfo = channel.feeInfo;
        uint oldFeeUnit = feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        
        // currentFee is 0, increase no fee counter
        if (currentFee == 0) {
            channel.feeInfo = newFeeUnit | (((feeInfo >> 128) + 1) << 128);
        }
        // length == 255 means is time to save reward
        // newFeeUnit != oldFeeUnit means the fee is changed, need to settle
        else if (length & COLLECT_REWARD_MASK == COLLECT_REWARD_MASK || newFeeUnit != oldFeeUnit) {
            // Save reward
            INestLedger(_nestLedgerAddress).carveReward { 
                value: currentFee + oldFeeUnit * (COLLECT_REWARD_MASK - (feeInfo >> 128)) 
            } (ntokenAddress);
            // Update fee information
            channel.feeInfo = newFeeUnit | (((length + 1) & COLLECT_REWARD_MASK) << 128);
        }

        // Calculate share count
        return currentFee / newFeeUnit;
    }

    /// @dev Settlement Commission
    /// @param tokenAddress The token address
    function settle(address tokenAddress) override external {
        
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        // ntoken is no reward
        if (tokenAddress != ntokenAddress) {

            PriceChannel storage channel = _channels[tokenAddress];
            uint count = channel.sheets.length & COLLECT_REWARD_MASK;
            uint feeInfo = channel.feeInfo;

            // Save reward
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
            sheet.height,
            // The remain number of this price sheet
            sheet.remainNum,
            // The eth number which miner will got
            sheet.ethNumBal,
            // The eth number which equivalent to token's value which miner will got
            sheet.tokenNumBal,
            // The pledged number of nest in this sheet. (unit: 1000nest)
            sheet.nestNum1k,
            // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
            sheet.level,
            // Post fee shares
            sheet.shares,
            // Price
            uint152(decodeFloat(sheet.priceFloat))
        );
    }

    /// @dev List sheets by page
    /// @param tokenAddress Destination token address
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        address tokenAddress, 
        uint offset, 
        uint count, 
        uint order
    ) override external view returns (PriceSheetView[] memory) {
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheetView[] memory result = new PriceSheetView[](count);
        uint i = 0;

        // Reverse order
        if (order == 0) {

            uint index = sheets.length - offset;
            uint end = index - count;
            while (index > end) {
                --index;
                result[i++] = _toPriceSheetView(sheets[index], index);
            }
        } 
        // Positive order
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

        address ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress);
        if (tokenAddress == ntokenAddress) {
            return 0;
        }
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        uint index = sheets.length;
        while (index > 0) {

            PriceSheet memory sheet = sheets[--index];
            if (uint(sheet.shares) > 0) {
                
                uint blocks = block.number - uint(sheet.height);
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                    return blocks * _redution(block.number - NEST_GENESIS_BLOCK) * 1 ether;
                }
                
                (uint blockNumber,) = INToken(ntokenAddress).checkBlockInfo();
                return blocks * _redution(block.number - blockNumber) * 0.01 ether;
            }
        }

        return 0;
    }

    /// @dev Query the quantity of the target quotation
    /// @param tokenAddress Token address. The token can't mine. Please make sure you don't use the token address when calling
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        address tokenAddress, 
        uint index
    ) override external view returns (uint minedBlocks, uint totalShares) {
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet = sheets[index];
        
        // The bite sheet or ntoken sheet dosen't mining
        if (uint(sheet.shares) == 0 /*|| INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress) == tokenAddress*/) {
            return (0, 0);
        }

        return _calcMinedBlocks(sheets, index, sheet);
    }

    // function getMined(address tokenAddress, uint index) external view returns (uint) {
    //     PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
    //     PriceSheet memory sheet = sheets[index];
        
    //     address ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress);
    //     // The bite sheet or ntoken sheet dosen't mining
    //     if (uint(sheet.shares) == 0 || tokenAddress == ntokenAddress) {
    //         return 0;
    //     }

    //     (uint minedBlocks, uint totalShares) = _calcMinedBlocks(sheets, index, sheet);
    //     if (ntokenAddress == NEST_TOKEN_ADDRESS) {
    //         return minedBlocks * uint(sheet.shares) * _redution(uint(sheet.height) - NEST_GENESIS_BLOCK) * 1 ether / totalShares;
    //     }

    //     (uint blockNumber,) = INToken(INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress)).checkBlockInfo();
    //     return minedBlocks * uint(sheet.shares) * _redution(uint(sheet.height) - blockNumber) * 0.01 ether / totalShares;
    // }

    /* ========== Accounts ========== */

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    /// @return Actually withdrawn
    function withdraw(address tokenAddress, uint value) override external returns (uint) {

        // TODO: The user's locked nest and the mining pool's nest are stored together. When the nest is dug up, 
        // the problem of taking the locked nest as the ore drawing will appear
        // As it will take a long time for nest to finish mining, this problem will not be considered for the time being
        UINT storage balance = _accounts[_accountMapping[msg.sender]].balances[tokenAddress];
        //uint balanceValue = balance.value;
        //require(balanceValue >= value, "NM:!balance");
        balance.value -= value;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);

        return value;
    }

    // /// @dev Withdraw assets
    // /// @param tokenAddress Destination token address
    // /// @param value The value to withdraw
    // /// @return Actually withdrawn
    // function withdrawNToken(address ntokenAddress, uint value) external returns (uint) {
    //     return 0;
    // }

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
            balance.value = balanceValue - value;
        }
    }

    /// @dev Unfreeze token
    /// @param balances Balances ledgerBalances ledger
    /// @param tokenAddress Destination token address
    /// @param value token amount
    function _unfreeze(mapping(address=>UINT) storage balances, address tokenAddress, uint value) private {
        UINT storage balance = balances[tokenAddress];
        balance.value += value;
    }

    /// @dev freeze token and nest
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount 
    /// @param nestValue nest amount
    function _freeze2(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue, 
        uint nestValue
    ) private {

        UINT storage balance;
        uint balanceValue;

        // If tokenAddress is NEST_TOKEN_ADDRESS, add it to nestValue
        if (NEST_TOKEN_ADDRESS == tokenAddress) {
            nestValue += tokenValue;
        }
        // tokenAddress is not NEST_TOKEN_ADDRESS, unfreeze it 
        else {
            balance = balances[tokenAddress];
            balanceValue = balance.value;
            if (balanceValue < tokenValue) {
                TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenValue - balanceValue);
                balance.value = 0;
            } else {
                balance.value = balanceValue - tokenValue;
            }
        }

        // Unfreeze nest
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
    function _unfreeze3(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue, 
        address ntokenAddress, 
        uint ntokenValue, 
        uint nestValue
    ) private {

        UINT storage balance;
        
        // If tokenAddress is ntokenAddress, add it to ntokenValue
        if (ntokenAddress == tokenAddress) {
            ntokenValue += tokenValue;
        }
        // tokenAddress is not ntokenAddress, unfreeze it
        else {
            balance = balances[tokenAddress];
            balance.value += tokenValue;
        }

        // If ntokenAddress is NEST_TOKEN_ADDRESS, add it to nestValue
        if (NEST_TOKEN_ADDRESS == ntokenAddress) {
            nestValue += ntokenValue;
        }
        // ntokenAddress is NEST_TOKEN_ADDRESS, unfreeze it
        else {
            balance = balances[ntokenAddress];
            balance.value += ntokenValue;
        }

        // Unfreeze nest
        balance = balances[NEST_TOKEN_ADDRESS];
        balance.value += nestValue;
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
            return (uint(priceInfo.height), decodeFloat(priceInfo.priceFloat));
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
    function triggeredPriceInfo(address tokenAddress) override public view returns (
        uint blockNumber, 
        uint price, 
        uint avgPrice, 
        uint sigmaSQ
    ) {
        
        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);
        PriceInfo memory priceInfo = _channels[tokenAddress].price;

        return (
            uint(priceInfo.height), 
            decodeFloat(priceInfo.priceFloat),
            decodeFloat(priceInfo.avgFloat),
            (uint(priceInfo.sigmaSQ) * 1 ether) >> 48
        );
    }

    /// @dev Find the price at block number
    /// @param tokenAddress Destination token address
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        address tokenAddress, 
        uint height
    ) override external view returns (uint blockNumber, uint price) {

        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);

        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet;

        uint length = sheets.length;
        uint left = 0;
        uint right = length - 1;
        uint index = 0;

        // If height is greater than max effect block number, use max effect block number
        uint h = block.number - uint(_config.priceEffectSpan);
        if (height > h) {
            height = h;
        }

        // Find the index use Binary Search
        while (left < right) {

            index = (left + right) >> 1;
            h = uint((sheet = sheets[index]).height);
            if (height > h) {
                left = ++index;
            } else if (height < h) {
                // 当index=0时，此语句会出现下溢异常，这通常说明调用时传递的有效区块高度比第一笔报价的区块高度还要低
                right = --index;
            } else {
                break;
            }
        }

        // Calculate price
        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint remainNum;
        h = 0;

        // Find sheets forward
        for (uint i = index; i < length;) {
            
            sheet = sheets[i++];
            if (height < uint(sheet.height)) {
                break;
            }
            if ((remainNum = uint(sheet.remainNum)) > 0) {
                if (h == 0) {
                    h = uint(sheet.height);
                } else if (h != uint(sheet.height)) {
                    break;
                }
                totalEthNum += remainNum;
                totalTokenValue += decodeFloat(sheet.priceFloat) * remainNum;
            }
        }

        // Find sheets backward
        while (index > 0) {
            
            sheet = sheets[--index];
            if ((remainNum = uint(sheet.remainNum)) > 0) {
                if (h == 0) {
                    h = uint(sheet.height);
                } else if (h != uint(sheet.height)) {
                    break;
                }
                totalEthNum += remainNum;
                totalTokenValue += decodeFloat(sheet.priceFloat) * remainNum;
            }
        }

        if (totalEthNum > 0) {
            return (h, totalTokenValue / totalEthNum);
        }
        return (0, 0);
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(address tokenAddress) override public view returns (uint blockNumber, uint price) {

        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);

        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint height = 0;
        uint h = block.number - uint(_config.priceEffectSpan);
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet;

        uint index = sheets.length;
        while (index >= 0) {

            if (index == 0 || height != uint((sheet = sheets[--index]).height)) {
                if (totalEthNum > 0 && height < h) {
                    return (height, totalTokenValue / totalEthNum);
                }
                totalEthNum = 0;
                totalTokenValue = 0;
                height = uint(sheet.height);
            }

            uint remainNum = uint(sheet.remainNum);
            totalEthNum += remainNum;
            totalTokenValue += decodeFloat(sheet.priceFloat) * remainNum;
        }

        return (0, 0);
    }

    /// @dev Get the last (num) effective price
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(address tokenAddress, uint count) override external view returns (uint[] memory) {
        
        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);

        uint[] memory array = new uint[](count <<= 1);
        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint height = 0;
        uint h = block.number - uint(_config.priceEffectSpan);
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet;

        uint index = sheets.length;
        while (count > 0 && index >= 0) {

            if (index == 0 || height != uint((sheet = sheets[--index]).height)) {
                if (totalEthNum > 0 && height < h) {
                    array[--count] = totalTokenValue / totalEthNum;
                    array[--count] = height;
                }
                totalEthNum = 0;
                totalTokenValue = 0;
                height = uint(sheet.height);
            }

            uint remainNum = uint(sheet.remainNum);
            totalEthNum += remainNum;
            totalTokenValue += decodeFloat(sheet.priceFloat) * remainNum;
        }

        return array;
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
        (
            triggeredPriceBlockNumber, 
            triggeredPriceValue, 
            triggeredAvgPrice, 
            triggeredSigmaSQ
        ) = triggeredPriceInfo(tokenAddress);
    }

    /// @dev Get the latest trigger price. (token and ntoken）
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function triggeredPrice2(address tokenAddress) override external returns (
        uint blockNumber, 
        uint price, 
        uint ntokenBlockNumber, 
        uint ntokenPrice
    ) {
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
    function triggeredPriceInfo2(address tokenAddress) override external returns (
        uint blockNumber, 
        uint price, 
        uint avgPrice, 
        uint sigmaSQ, 
        uint ntokenBlockNumber, 
        uint ntokenPrice, 
        uint ntokenAvgPrice, 
        uint ntokenSigmaSQ
    ) {
        (blockNumber, price, avgPrice, sigmaSQ) = triggeredPriceInfo(tokenAddress);
        (
            ntokenBlockNumber, 
            ntokenPrice, 
            ntokenAvgPrice, 
            ntokenSigmaSQ
        ) = triggeredPriceInfo(_getNTokenAddress(tokenAddress));
    }

    /// @dev Get the latest effective price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function latestPrice2(address tokenAddress) override external returns (
        uint blockNumber, 
        uint price, 
        uint ntokenBlockNumber, 
        uint ntokenPrice
    ) {
        (blockNumber, price) = latestPrice(tokenAddress);
        (ntokenBlockNumber, ntokenPrice) = latestPrice(_getNTokenAddress(tokenAddress));
    }

    /* ========== Tools and methods ========== */

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
}