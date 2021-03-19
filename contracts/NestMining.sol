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

    ///dev Definitions for the price sheet, include the full information. (use 256bits, a storage unit in ethereum evm)
    struct PriceSheet {
        
        // Index of miner account in _accounts. for this way, mapping an address(which need 160bits) to a 32bits integer, support 4billion accounts
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
        // high 128bits in the high level indicate the current cumulative number of quotations that do not require Commission (including bills and settled ones)
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

    /// @dev 报价通道。tokenAddress=>PriceChannel
    mapping(address=>PriceChannel) _channels;

    /// @dev ntoken映射缓存。tokenAddress=>ntokenAddress
    mapping(address=>address) _addressCache;

    /// @dev 缓存ntoken创世区块号。ntokenAddress=>genesisBlockNumber
    mapping(address=>uint) _genesisBlockNumberCache;

    /// @dev 价格调用入口合约地址
    address _nestPriceFacadeAddress;

    /// @dev NTokenController合约地址
    address _nTokenControllerAddress;

    /// @dev nest账本合约地址
    address _nestLedgerAddress;

    /// @dev nest代币合约地址
    address immutable NEST_TOKEN_ADDRESS; // = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    
    /// @dev nest创世区块号
    uint immutable NEST_GENESIS_BLOCK; // = 6236588;	

    /// @dev 万分之一eth，手续费单位
    uint constant DIMI_ETHER = 1 ether / 10000;

    /// @dev 批量结算分红的掩码。测试时每16个报价单结算一次，线上版本256个报价单结算一次
    uint constant COLLECT_REWARD_MASK = 0xFF;
    
    /// @dev 以太坊平均出块时间间隔，14秒
    uint constant ETHEREUM_BLOCK_TIMESPAN = 14;

    /* ========== 治理相关 ========== */

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请调用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
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

    /// @dev 修改配置
    /// @param config 配置对象
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev 获取配置
    /// @return 配置对象
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /* ========== 报价相关 ========== */

    // 获取token对应的ntoken地址
    function _getNTokenAddress(address tokenAddress) private returns (address) {
        
        // 处理禁用ntoken后导致的缓存问题
        address ntokenAddress = _addressCache[tokenAddress];
        if (ntokenAddress == address(0)) {
            if ((ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress)) != address(0)) {
                _addressCache[tokenAddress] = ntokenAddress;
            }
        }

        return ntokenAddress;
    }

    // 获取ntoken的创世区块
    function _getNTokenGenesisBlock(address ntokenAddress) private returns (uint) {

        uint genesisBlockNumber = _genesisBlockNumberCache[ntokenAddress];
        if (genesisBlockNumber == 0) {
            (genesisBlockNumber,) = INToken(ntokenAddress).checkBlockInfo();
            _genesisBlockNumberCache[ntokenAddress] = genesisBlockNumber;
        }

        return genesisBlockNumber;
    }

    /// @dev 清空缓存的ntoken信息。如果发生ntoken被禁用后重建，需要调用此方法
    /// @param tokenAddress token地址
    function resetNTokenCache(address tokenAddress) public {

        // 清除缓存
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        _genesisBlockNumberCache[ntokenAddress] = 0;
        _addressCache[tokenAddress] = _addressCache[ntokenAddress] = address(0);

        // 重新加载
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

        // 1. 参数检查
        require(ethNum > 0 && ethNum == uint(config.postEthUnit), "NM:!ethNum");
        require(tokenAmountPerEth > 0, "NM:!price");
        
        // 2. 手续费
        uint fee = uint(config.postFee) * DIMI_ETHER;
        require(msg.value == fee + ethNum * 1 ether, "NM:!value");

        // 3. 检查报价轨道
        // 检查是否允许单轨报价
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");
        // nest单位不同，但是也早已经超过此发行数量，不再做额外判断
        // ntoken采用关闭时出矿（或者取回时出矿），可能存在用户故意不关闭，或者故意不取回，导致总量判断不准确的问题。忽略
        require(IERC20(ntokenAddress).totalSupply() < uint(config.doublePostThreshold) * 10000 ether, "NM:!post2");        

        // 4. 存入收益
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        // 每隔256个报价单存入一次收益，扣除吃单的次数和已结算部分
        uint length = sheets.length;
        _collect(channel, ntokenAddress, length, fee, fee);

        // 5. 冻结资产
        uint accountIndex = _addressIndex(msg.sender);
        // 冻结token，nest
        // 由于使用浮点表示法(uint48 fraction, uint8 exponent)会带来一定的精度损失
        // 按照tokenAmountPerEth * ethNum冻结资产后，退回的时候可能损失精度差部分
        // 实际应该按照decodeFloat(fraction, exponent) * ethNum来冻结
        // 但是考虑到损失在1/10^14以内，因此忽略此处的损失，精度损失的部分，将来可以作为系统收益转出
        _freeze2(_accounts[accountIndex].balances, tokenAddress, tokenAmountPerEth * ethNum, uint(config.pledgeNest) * 1000 ether);

        // 6. 计算价格
        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 7. 创建报价单
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

        // 1. 参数检查
        require(ethNum > 0 && ethNum == uint(config.postEthUnit), "NM:!ethNum");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "NM:!price");
        
        // 2. 手续费
        // ******** tmp是多用途变量，从此处开始表示fee
        uint tmp = uint(config.postFee) * DIMI_ETHER;
        require(msg.value == tmp + ethNum * 2 ether, "NM:!value");

        // 3. 检查报价轨道
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");

        // 4. 存入收益
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        // 每隔256个报价单存入一次收益，扣除吃单的次数和已结算部分
        uint length = sheets.length;
        _collect(channel, ntokenAddress, length, tmp, tmp);

        // 5. 冻结资产
        uint accountIndex = _addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        // ******** tmp是多用途变量，从此处开始表示config.pledgeNest
        tmp = uint(config.pledgeNest);
        _freeze(balances, tokenAddress, ethNum * tokenAmountPerEth);
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _freeze(balances, NEST_TOKEN_ADDRESS, ethNum * ntokenAmountPerEth + tmp * 1000 ether);
        } else {
            // TODO: token和ntoken一起冻结
            //_freeze(balances, ntokenAddress, ethNum * ntokenAmountPerEth);
            //_freeze(balances, NEST_TOKEN_ADDRESS, tmp * 2000 ether);
            _freeze2(balances, ntokenAddress, ethNum * ntokenAmountPerEth, tmp * 2000 ether);
        }
        
        // 6. 计算价格
        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 7. 创建报价单
        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), tmp, 0, tokenAmountPerEth);

        channel = _channels[ntokenAddress];
        sheets = channel.sheets;

        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
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

        // 1.参数检查
        require(biteNum > 0 && biteNum % uint(config.postEthUnit) == 0, "NM:!biteNum");
        require(newTokenAmountPerEth > 0, "NM:!price");

        // 2.加载报价单
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        PriceSheet memory sheet = sheets[index];

        // 3.检查报价单状态
        require(uint(sheet.remainNum) >= biteNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        // 4. 存入收益
        {
            // 每隔256个报价单存入一次收益，扣除吃单的次数和已结算部分
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            if (tokenAddress != ntokenAddress) {
                _collect(channel, ntokenAddress, sheets.length, 0, uint(config.postFee) * DIMI_ETHER);
            }
        }

        // 5. 计算需要的eth，token，nest数量，并冻结
        uint needTokenValue;
        uint level = uint(sheet.level);

        // 当吃单深度小于4的时候, nest和报价规模都翻倍
        if (level < uint(config.maxBiteNestedLevel)) {
            // 翻倍报价 + 用于买入token的数量，一共三倍
            require(msg.value == biteNum * 3 ether, "NM:!value");
            // 翻倍报价
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
            ++level;
        } 
        // 当吃单深度达到4或以上时, nest翻倍, 规模不翻倍
        else {
            // 单倍报价 + 用于买入token的数量，一共两倍
            require(msg.value == biteNum * 2 ether, "NM:!value");
            // 单倍报价
            needTokenValue = newTokenAmountPerEth * biteNum;
            // 吃单链长度超过255是有可能的，当链长度达到4或以上时，对于合约来说，没有逻辑依赖其具体值，此计数累加到255以后就不再更新
            if (level < 255) ++level;
        }

        // 需要抵押的nest数量
        uint needNest1k = ((biteNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);

        // 冻结nest
        uint accountIndex = _addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        if (tokenAddress == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1000 ether;
        } else {
            _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether);        
        }

        {
            // 冻结token
            uint backTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum;
            if (needTokenValue > backTokenValue) {
                _freeze(balances, tokenAddress, needTokenValue - backTokenValue);
            } else {
                _unfreeze(balances, tokenAddress, backTokenValue - needTokenValue);
            }
        }

        // 6.更新被吃的报价单
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal + biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal - biteNum);
        sheets[index] = sheet;

        // 7. 计算价格
        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 8. 生成吃单报价单
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

        // 1.参数检查
        require(biteNum > 0 && biteNum % uint(config.postEthUnit) == 0, "NM:!biteNum");
        require(newTokenAmountPerEth > 0, "NM:!price");

        // 2.加载报价单
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        PriceSheet memory sheet = sheets[index];

        // 3.检查报价单状态
        require(uint(sheet.remainNum) >= biteNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        // 4. 存入收益
        {
            // 每隔256个报价单存入一次收益，扣除吃单的次数和已结算部分
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            if (tokenAddress != ntokenAddress) {
                _collect(channel, ntokenAddress, sheets.length, 0, uint(config.postFee) * DIMI_ETHER);
            }
        }

        // 5. 计算需要的eth，token，nest数量，并冻结
        uint needTokenValue;
        uint level = uint(sheet.level);

        // 当吃单深度小于4的时候, nest和报价规模都翻倍
        if (level < uint(config.maxBiteNestedLevel)) {
            // 翻倍报价 - 卖出token换得的数量，一共一倍
            require(msg.value == biteNum * 1 ether, "NM:!value");
            // 翻倍报价
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
            ++level;
        } 
        // 当吃单深度达到4或以上时, nest翻倍, 规模不翻倍
        else {
            // 单倍报价 - 用于买入token的数量，一共0倍
            require(msg.value == 0, "NM:!value");
            // 单倍报价
            needTokenValue = newTokenAmountPerEth * biteNum;
            // 吃单链长度超过255是有可能的，当链长度达到4或以上时，对于合约来说，没有逻辑依赖其具体值，此计数累加到255以后就不再更新
            if (level < 255) ++level;
        }
        
        // 需要抵押的nest数量
        uint needNest1k = ((biteNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);

        // 冻结nest
        uint accountIndex = _addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        if (tokenAddress == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1000 ether;
        } else {
            _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether);        
        }

        // 冻结token
        _freeze(balances, tokenAddress, needTokenValue + decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum);

        // 6. 更新被吃的报价单信息
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal - biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal + biteNum);
        sheets[index] = sheet;

        // 7. 计算价格
        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 8. 生成吃单报价
        emit Post(tokenAddress, msg.sender, sheets.length, uint32(biteNum << 1), newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(biteNum << 1), needNest1k, level, newTokenAmountPerEth);
    }

    // 创建报价单
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
    
    // NEST出矿衰减间隔。2400000区块，约一年
    uint constant NEST_REDUCTION_SPAN = 2400000;
    // NEST出矿衰减极限，超过此间隔后变为稳定出矿。24000000区块，约十年
    uint constant NEST_REDUCTION_LIMIT = NEST_REDUCTION_SPAN * 10;
    // 衰减梯度数组，每个衰减阶梯值占16位。衰减值取整数
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

    // 计算衰减梯度
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

        // 加载通道数据
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        // 调用_close()关闭报价单
        (uint accountIndex, Tunple memory total) = _close(config, sheets, index, tokenAddress, ntokenAddress);

        if (accountIndex > 0) {
            // 退回eth
            if (uint128(total.ethNum) > 0) {
                payable(address(uint160(indexAddress(accountIndex)))).transfer(uint(total.ethNum) * 1 ether);
            }
            // 解冻资产
            _unfreeze3(_accounts[accountIndex].balances, tokenAddress, uint(total.tokenValue), ntokenAddress, uint(total.ntokenValue), uint(total.nestValue));
        }

        // 计算价格
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

    function _calcMinedBlocks(PriceSheet[] storage sheets, uint index, uint height) private view returns (uint minedBlocks, uint count) {

        // 计算出矿量
        uint length = sheets.length;
        //uint height = uint(sheet.height);
        uint i = index;
        count = 1;
        
        // 向后查找同一区块内的报价单
        while (++i < length && uint(sheets[i].height) == height) {
            
            // 同一区块内有多笔报价，当前是小概率事件，此时多读取一次可以忽略
            // 如果同一区块内总是有多笔报价时，说明报价非常密集，此处多消耗的gas并没有带来较大影响
            if (uint(sheets[i].level) == 0) {
                ++count;
            }
        }

        i = index;
        // 向前查找同一区块内的报价单
        uint prev = height;
        while (i > 0 && uint(prev = sheets[--i].height) == height) {

            // 同一区块内有多笔报价，当前是小概率事件，此时多读取一次可以忽略
            // 如果同一区块内总是有多笔报价时，说明报价非常密集，此处多消耗的gas并没有带来较大影响
            if (uint(sheets[i].level) == 0) {
                ++count;
            }
        }

        //uint minedBlocks;
        if (i == 0 && sheets[i].height == height) {
            // TODO: 考虑第一笔挖矿的出矿量如何计算
            //minedBlocks = 10;
            return (10, count);
        } else {
            //minedBlocks = height - prev;
            return (height - prev, count);
        }
    }

    // 用于给_close()方法返回多个值的结构体
    struct Tunple {
        uint128 ethNum;
        uint128 tokenValue;
        uint128 nestValue;
        uint128 ntokenValue;
    }

    // 关闭报价单
    function _close(Config memory config, PriceSheet[] storage sheets, uint index, address tokenAddress, address ntokenAddress) private returns (uint accountIndex, Tunple memory value) {
        
        PriceSheet memory sheet = sheets[index];

        // 检查报价单状态，是否达到生效区块间隔或者被吃完
        if ((accountIndex = uint(sheet.miner)) > 0 && (uint(sheet.height) + uint(config.priceEffectSpan) < block.number || uint(sheet.remainNum) == 0)) {
            // 将报价矿工注册编号清空，表示报价单已经关闭
            sheet.miner = uint32(0);
            // 吃单报价和ntoken报价不挖矿
            if (uint(sheet.level) > 0 || tokenAddress == ntokenAddress) {
                value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
                value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
            } 
            // 挖矿逻辑
            else {
                
                (uint minedBlocks, uint count) = _calcMinedBlocks(sheets, index, uint(sheet.height));
                // nest挖矿
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                    value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
                    value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether + minedBlocks * _redution(block.number - NEST_GENESIS_BLOCK) * 1 ether * uint(config.minerNestReward) / 10000 / count);
                } 
                // ntoken挖矿
                else {
                    // 最多挖到100区块
                    if (minedBlocks > uint(config.ntokenMinedBlockLimit)) {
                        minedBlocks = uint(config.ntokenMinedBlockLimit);
                    }
                    
                    uint mined = (minedBlocks * _redution(block.number - _getNTokenGenesisBlock(ntokenAddress)) * 0.01 ether) / count;
                    // ntoken竞拍者分成
                    address bidder = INToken(ntokenAddress).checkBidder();
                    // 新的ntoken
                    if (bidder == address(this)) {
                        value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
                        value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
                        value.ntokenValue = uint128(mined);
                        // TODO: 出矿逻辑放到取回里面实现，减少gas消耗
                        // 挖矿
                        INToken(ntokenAddress).mint(mined, address(this));
                    }
                    // 老的ntoken
                    else {
                        value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
                        value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
                        value.ntokenValue = uint128(mined * uint(config.minerNTokenReward) / 10000);
                        // 考虑到同一区块内多笔转账是小概率事件，可以再每个关闭操作中给竞拍者发ntoken
                        // 5%给竞拍者
                        _unfreeze(_accounts[_addressIndex(bidder)].balances, ntokenAddress, mined * (10000 - uint(config.minerNTokenReward)) / 10000);
                        
                        // TODO: 出矿逻辑放到取回里面实现，减少gas消耗
                        // 挖矿
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

    // 批量关闭报价单
    function _closeList(Config memory config, PriceChannel storage channel, address tokenAddress, uint32[] memory indices) private {

        PriceSheet[] storage sheets = channel.sheets;
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        uint accountIndex = 0; 
        Tunple memory total;

        // 1. 遍历报价单
        for (uint i = 0; i < indices.length; ++i) {

            // 由于需要返回的变量太多，会导定义的变量数量过多，因此定义Tunple结构体
            (uint minerIndex, Tunple memory value) = _close(config, sheets, uint(indices[i]), tokenAddress, ntokenAddress);
            // 批量关闭报价单只能关闭同一用户的报价单
            if (accountIndex == 0) {
                // accountIndex == 0表示是第一个报价单，取此报价单的矿工编号
                accountIndex = minerIndex;
            } else {
                // accountIndex != 0表示是后续报价单，矿工编号必须与之前记录的保持一致
                require(accountIndex == minerIndex, "NM:!miner");
            }

            total.ethNum += value.ethNum;
            total.tokenValue += value.tokenValue;
            total.nestValue += value.nestValue;
            total.ntokenValue += value.ntokenValue;
        }

        // 退回eth
        if (uint128(total.ethNum) > 0) {
            payable(address(uint160(indexAddress(accountIndex)))).transfer(uint(total.ethNum) * 1 ether);
        }
        // 解冻资产
        _unfreeze3(_accounts[accountIndex].balances, tokenAddress, uint(total.tokenValue), ntokenAddress, uint(total.ntokenValue), uint(total.nestValue));

        _stat(channel, sheets, uint(config.priceEffectSpan));
    }

    function _stat(PriceChannel storage channel, PriceSheet[] storage sheets, uint priceEffectSpan) private {

        // 找到token的价格信息
        PriceInfo memory p0 = channel.price;
        
        // 报价单数组长度
        uint length = sheets.length;
        // 即将处理的报价单在报价数组里面的索引
        uint index = uint(p0.index);
        // 已经计算价格的最新区块高度
        uint prev = uint(p0.height);
        // 用于计算价格的eth计数变量
        uint totalEth = 0; //uint(p0.remainNum);
        // 用于计算价格的token计数变量
        uint totalTokenValue = 0; //decodeFloat(p0.priceFraction, p0.priceExponent) * totalEth;
        // 当前报价单所在的区块高度
        uint height;
        // 当前价格
        uint price;

        // 遍历报价单，找到生效价格
        PriceSheet memory sheet;
        for (; ; ) {
            
            // 从当前位置遍历已经达到生效间隔的报价单
            bool flag = index < length && (height = uint((sheet = sheets[index]).height)) + priceEffectSpan < block.number;

            // 同一区块, 并且flag为true, 累计计数
            if (prev == height && flag) {
                totalEth += uint(sheet.remainNum);
                totalTokenValue += decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
            }
            // 不是同一个区块（或者flag为false），计算价格并更新
            else {
                // totalEth > 0 可以计算价格
                if (totalEth > 0) {

                    // 新产生的价格
                    price = totalTokenValue / totalEth;

                    // 计算平均价格和波动率
                    // 后续价格的波动率计算方法
                    if (prev > 0) {
                        // 计算平均价格
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

                            // 当前实现假定波动率不可能超过1，与此对应的，当计算值超过0xFFFFFFFFFFFF时
                            // 表示波动率已经超过可以表示的范围，用0xFFFFFFFFFFFF表示
                            if (tmp > 0xFFFFFFFFFFFF) {
                                tmp = 0xFFFFFFFFFFFF;
                            }
                            p0.sigmaSQ = uint48(tmp);
                        }
                    } 
                    // 第一个价格，平均价格、波动率计算方式有所不同
                    else {
                        // 平均价格等于价格
                        //p0.avgTokenAmount = uint64(price);
                        (p0.avgFraction, p0.avgExponent) = encodeFloat(price);

                        // 波动率为0
                        p0.sigmaSQ = uint48(0);
                    }

                    // 更新价格区块高度
                    p0.height = uint32(prev);
                    // 更新价格
                    p0.remainNum = uint32(totalEth);
                    //p0.tokenAmount = uint64(totalTokenValue);
                    (p0.priceFraction, p0.priceExponent) = encodeFloat(totalTokenValue / totalEth);

                    // 移动到新的高度
                    prev = height;
                }

                // 清空累加值
                totalEth = uint(sheet.remainNum);
                totalTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
            }

            if (!flag) {
                break;
            }
            ++index;
        }

        // 更新价格信息
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

    // 将累计的分红转入到nest账本
    function _collect(PriceChannel storage channel, address ntokenAddress, uint length, uint currentFee, uint newFee) private {

        uint feeInfo = channel.feeInfo;
        uint oldFee = feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        
        if (currentFee == 0) {
            channel.feeInfo = newFee | (((feeInfo >> 128) + 1) << 128);
        } else if (length & COLLECT_REWARD_MASK == COLLECT_REWARD_MASK || newFee != oldFee) {
            INestLedger(_nestLedgerAddress).carveReward { 
                value: currentFee + oldFee * (COLLECT_REWARD_MASK - (feeInfo >> 128)) 
            } (ntokenAddress);
            // 更新佣金信息
            if (newFee == oldFee) {
                // 当前累计的不需要收佣金的报价单数量清零，因此无需给高128位赋值
                channel.feeInfo = newFee;
            } else {
                // 更新佣金信息
                // 当前累计的不需要收佣金的报价单数量清零，因此无需给高128位赋值
                channel.feeInfo = newFee | (((length & COLLECT_REWARD_MASK) + 1) << 128);
            }
        }
    }

    /// @dev 结算佣金
    /// @param tokenAddress 目标token地址
    function settle(address tokenAddress) override external {
        
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        if (tokenAddress != ntokenAddress) {

            PriceChannel storage channel = _channels[tokenAddress];
            uint count = channel.sheets.length & COLLECT_REWARD_MASK;
            uint feeInfo = channel.feeInfo;

            INestLedger(_nestLedgerAddress).carveReward { 
                value: (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) * (count - (feeInfo >> 128)) 
            } (ntokenAddress);

            // 手动结算不需要更新佣金变量
            channel.feeInfo = (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | (count << 128);
        }
    }

    // 将PriceSheet转化为PriceSheetView
    function _toPriceSheetView(PriceSheet memory sheet, uint index) private view returns (PriceSheetView memory) {

        return PriceSheetView(
            // 索引号
            uint32(index),
            // 矿工地址
            indexAddress(sheet.miner),
            // 挖矿所在区块高度
            uint32(sheet.height),
            // 报价剩余规模
            uint32(sheet.remainNum),
            // 剩余的eth数量
            uint32(sheet.ethNumBal),
            // 剩余的token对应的eth数量
            uint32(sheet.tokenNumBal),
            // nest抵押数量（单位: 1000nest）
            uint32(sheet.nestNum1k),
            // 当前报价单的深度。0表示初始报价，大于0表示吃单报价
            uint8(sheet.level),
            // 每个eth等值的token数量
            uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent))
        );
    }

    /// @dev 分页列出报价单
    /// @param tokenAddress 目标token地址
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式。0倒序，非0正序
    /// @return 报价单列表
    function list(address tokenAddress, uint offset, uint count, uint order) override external view returns (PriceSheetView[] memory) {
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheetView[] memory result = new PriceSheetView[](count);
        uint i = 0;

        // 倒序
        if (order == 0) {

            uint index = sheets.length - offset;
            uint end = index - count;
            while (index-- > end) {
                result[i++] = _toPriceSheetView(sheets[index], index);
            }
        } 
        // 正序
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

    /// @dev 预估出矿量
    /// @param tokenAddress 目标token地址
    /// @return 预估的出矿量
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

    /// @dev 查询目标报价单挖矿情况。
    /// @param tokenAddress token地址。ntoken不能挖矿，调用的时候请自行保证不要使用ntoken地址
    /// @param index 报价单地址
    function getMinedBlocks(address tokenAddress, uint index) override external view returns (uint minedBlocks, uint count) {
        
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet = sheets[index];
        
        // 吃单报价或者ntoken报价不挖矿
        if (sheet.level > 0 /*|| INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress) == tokenAddress*/) {
            return (0, 0);
        }

        return _calcMinedBlocks(sheets, index, uint(sheet.height));
    }

    /* ========== 账户相关 ========== */

    /// @dev 取出资产
    /// @param tokenAddress 目标token地址
    /// @param value 要取回的数量
    /// @return 实际取回的数量
    function withdraw(address tokenAddress, uint value) override external returns (uint) {

        // TODO: 用户锁定的nest和矿池的nest混合存储在一起，当nest挖完时，会出现将别人锁定的nest当作出矿取走的问题
        // 由于nest挖完还需要较长时间，此问题惨不考虑
        Account storage account = _accounts[_accountMapping[msg.sender]];
        uint balance = account.balances[tokenAddress].value;
        require(balance >= value, "NM:!balance");
        account.balances[tokenAddress].value = balance - value;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);

        return value;
    }

    /// @dev 查看用户的指定资产数量
    /// @param tokenAddress 目标token地址
    /// @param addr 目标地址
    /// @return 资产数量
    function balanceOf(address tokenAddress, address addr) override external view returns (uint) {
        return _accounts[_accountMapping[addr]].balances[tokenAddress].value;
    }

    /// @dev 获取指定地址的索引号. 如果不存在，则注册
    /// @param addr 目标地址
    /// @return 索引号
    function _addressIndex(address addr) private returns (uint) {

        uint index = _accountMapping[addr];
        if (index == 0) {
            // 超过32位所能存储的最大数字，无法再继续注册新的账户，如果需要支持新的账户，需要更新合约
            require((_accountMapping[addr] = index = _accounts.length) < 0x100000000, "NM:!accounts");
            _accounts.push().addr = addr;
        }

        return index;
    }

    /// @dev 获取给定索引号对应的地址
    /// @param index 索引号
    /// @return 给定索引号对应的地址
    function indexAddress(uint index) override public view returns (address) {
        return _accounts[index].addr;
    }

    /// @dev 获取指定地址的注册索引号
    /// @param addr 目标地址
    /// @return 0表示不存在, 非0表示索引号
    function getAccountIndex(address addr) override external view returns (uint) {
        return _accountMapping[addr];
    }

    /// @dev 获取注册账户数组长度
    /// @return 注册账户数组长度
    function getAccountCount() override external view returns (uint) {
        return _accounts.length;
    }

    /* ========== 资产管理 ========== */

    /// @dev 解冻token
    /// @param balances 账本
    /// @param tokenAddress token地址
    /// @param value token数量
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

    /// @dev 解冻token
    /// @param balances 账本
    /// @param tokenAddress token地址
    /// @param value token数量
    function _unfreeze(mapping(address=>UINT) storage balances, address tokenAddress, uint value) private {
        UINT storage balance = balances[tokenAddress];
        balance.value = balance.value + value;
    }

    /// @dev 冻结token和nest
    /// @param balances 账本
    /// @param tokenAddress token地址
    /// @param tokenValue token数量
    /// @param nestValue nest数量
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

    // /// @dev 解冻token和nest
    // /// @param balances 账本
    // /// @param tokenAddress token地址
    // /// @param tokenValue token数量
    // /// @param nestValue nest数量
    // function _unfreeze2(mapping(address=>UINT) storage balances, address tokenAddress, uint tokenValue, uint nestValue) private {

    //     UINT storage balance = balances[tokenAddress];
    //     balance.value = balance.value + tokenValue;

    //     balance = balances[NEST_TOKEN_ADDRESS];
    //     balance.value = balance.value + nestValue;
    // }

    // /// @dev 冻结token和nest
    // /// @param balances 账本
    // /// @param tokenAddress token地址
    // /// @param tokenValue token数量
    // /// @param ntokenAddress ntoken地址
    // /// @param ntokenValue ntoken数量
    // /// @param nestValue nest数量
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

    /// @dev 解冻token和nest
    /// @param balances 账本
    /// @param tokenAddress token地址
    /// @param tokenValue token数量
    /// @param ntokenAddress ntoken地址
    /// @param ntokenValue ntoken数量
    /// @param nestValue nest数量
    function _unfreeze3(mapping(address=>UINT) storage balances, address tokenAddress, uint tokenValue, address ntokenAddress, uint ntokenValue, uint nestValue) private {

        //mapping(address=>UINT) storage balances = accounts[addressIndex(msg.sender)].balances;
        UINT storage balance = balances[tokenAddress];
        balance.value = balance.value + tokenValue;

        balance = balances[ntokenAddress];
        balance.value = balance.value + ntokenValue;

        balance = balances[NEST_TOKEN_ADDRESS];
        balance.value = balance.value + nestValue;
    }

    /* ========== 价格查询 ========== */
    
    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function triggeredPrice(address tokenAddress) override public view returns (uint blockNumber, uint price) {

        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);
        PriceInfo memory priceInfo = _channels[tokenAddress].price;
        if (uint(priceInfo.remainNum) > 0) {
            return (uint(priceInfo.height), decodeFloat(priceInfo.priceFraction, priceInfo.priceExponent));
        }
        return (0, 0);
    }

    /// @dev 获取最新的触发价格完整信息
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格（1eth可以兑换多少token）
    /// @return avgPrice 平均价格
    /// @return sigmaSQ 波动率的平方（18位小数）。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
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

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function latestPrice(address tokenAddress) override public view returns (uint blockNumber, uint price) {

        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);

        Config memory config = _config;
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        uint index = sheets.length;

        // 找到已经生效的报价单索引
        while (index > 0) { 
            PriceSheet memory sheet = sheets[--index];
            if (uint(sheet.height) + uint(config.priceEffectSpan) < block.number && uint(sheet.remainNum) > 0) {
                
                // 根据区块内的报价单计算价格
                // 目标区块
                uint height = uint(sheet.height);
                uint totalEth = uint(sheet.remainNum);
                uint totalTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
                
                // 遍历区块内的报价单
                while (index > 0 && uint(sheets[--index].height) == height) {
                    
                    // 找到报价单
                    sheet = sheets[index];

                    // 累加eth数量
                    totalEth += uint(sheet.remainNum);

                    // 累加token数量
                    totalTokenValue += decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
                }

                // totalEth必然大于0
                return (height, totalTokenValue / totalEth);
            }
        }

        return (0, 0);
    }

    /// @dev 返回latestPrice()和triggeredPriceInfo()两个方法的结果
    /// @param tokenAddress 目标token地址
    /// @return latestPriceBlockNumber 价格所在区块号
    /// @return latestPriceValue 价格(1eth可以兑换多少token)
    /// @return triggeredPriceBlockNumber 价格所在区块号
    /// @return triggeredPriceValue 价格(1eth可以兑换多少token)
    /// @return triggeredAvgPrice 平均价格
    /// @return triggeredSigmaSQ 波动率的平方
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

    /// @dev 获取最新的触发价格（token和ntoken）
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    function triggeredPrice2(address tokenAddress) override external returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice) {
        (blockNumber, price) = triggeredPrice(tokenAddress);
        (ntokenBlockNumber, ntokenPrice) = triggeredPrice(_getNTokenAddress(tokenAddress));
    }

    /// @dev 获取最新的触发价格完整信息（token和ntoken）
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格（1eth可以兑换多少token）
    /// @return avgPrice 平均价格
    /// @return sigmaSQ 波动率的平方（18位小数）。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    /// @return ntokenAvgPrice 平均价格
    /// @return ntokenSigmaSQ 波动率的平方（18位小数）。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
    function triggeredPriceInfo2(address tokenAddress) override external returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ, uint ntokenBlockNumber, uint ntokenPrice, uint ntokenAvgPrice, uint ntokenSigmaSQ) {
        (blockNumber, price, avgPrice, sigmaSQ) = triggeredPriceInfo(tokenAddress);
        (ntokenBlockNumber, ntokenPrice, ntokenAvgPrice, ntokenSigmaSQ) = triggeredPriceInfo(_getNTokenAddress(tokenAddress));
    }

    /// @dev 获取最新的生效价格（token和ntoken）
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    function latestPrice2(address tokenAddress) override external returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice) {
        (blockNumber, price) = latestPrice(tokenAddress);
        (ntokenBlockNumber, ntokenPrice) = latestPrice(_getNTokenAddress(tokenAddress));
    }

    /* ========== 工具方法 ========== */

    /// @dev 将uint值编码成fraction * 16 ^ exponent形式的浮点表示形式
    /// @param value 目标uint值
    /// @return fraction 分数值
    /// @return exponent 指数值
    function encodeFloat(uint value) public pure returns (uint48 fraction, uint8 exponent) {
        
        uint decimals = 0; 
        while (value > 0xFFFFFFFFFFFF /* 281474976710655 */) {
            value >>= 4;
            ++decimals;
        }

        return (uint48(value), uint8(decimals));
    }

    /// @dev 将fraction * 16 ^ exponent形式的浮点表示形式解码成uint
    /// @param fraction 分数值
    /// @param exponent 指数值
    function decodeFloat(uint fraction, uint exponent) public pure returns (uint) {
        return fraction << (exponent << 2);
    }
}