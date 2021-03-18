// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/TransferHelper.sol";
import "./interface/INestMining.sol";
import "./interface/INestQuery.sol";
import "./interface/INTokenController.sol";
import "./interface/INestLedger.sol";
import "./interface/INToken.sol";
import "./interface/INest_NToken.sol";
import "./NestBase.sol";

/// @dev nest挖矿合约
contract NestMining is NestBase, INestMining, INestQuery {

    constructor(address nestTokenAddress, uint nestGenesisBlock) {
        
        // 权限控制
        // DAO添加分红的方法
        // 价格调用门面
        // 配置参数
        // ntoken出矿
        // ntoken竞拍者的token如何分发。考虑到同一区块内有多笔报价是小概率事件，暂定每个关闭的时候给竞拍者分发
        // 老的ntoken竞拍者挖矿
        // 初始化方法
        // ntoken不断的在衰减，但是挖矿限制为最多可以挖出100区块，如果一直没有人挖，但是衰减在继续，将来会越来越难得启动
        // 出矿，衰减
        // ntoken创建，管理
        // DAO合约
        // NestDAO分为账本部分，市场行为部分
        // 投票执行赋予临时权限
        // NestDAO配置
        // 计算价格，处理价格字段的编码问题
        // 投票
        // 整理PriceInfoV36结构体，完成_stat()方法的实现逻辑
        // 投票的通过状态改为实时计算，并且任何时候都可以撤回投票。（什么时候可以取回资产，投票并行问题如何解决）
        // 吃单手续费，配置
        // NN挖矿
        // nest挖矿和ntoken挖矿合约分开
        // TODO: 验证均价，波动率计算是否正确
        // TODO: freeze，unfreeze方法整理
        // TODO: nest和ntoken挖矿分别配置
        // TODO: 全面清理SafeMath
        // TODO: 检查系统权限控制，漏洞问题

        NEST_TOKEN_ADDRESS = nestTokenAddress;
        NEST_GENESIS_BLOCK = nestGenesisBlock;

        // 占位，实际的注册账号的索引必须大于0
        //_accounts.push(Account(address(0)));
        //Account storage account = Account(address(0));
        _accounts.push();
    }

    /// 报价单信息。(占256位，一个以太坊存储单元)
    struct PriceSheetV36 {
        
        // 矿工注册编号。通过矿工注册的方式，将矿工地址（160位）映射为32位整数，最多可以支持注册40亿矿工
        uint32 miner;

        // 挖矿所在区块高度
        uint32 height;

        // 报价剩余规模
        uint32 remainNum;

        // 剩余的eth数量
        uint32 ethNumBal;

        // 剩余的token对应的eth数量
        uint32 tokenNumBal;

        // nest抵押数量（单位: 1000nest）
        uint32 nestNum1k;

        // 当前报价单的深度。0表示初始报价，大于0表示吃单报价
        uint8 level;

        // 价格改为这种表示方式，可能损失精度，误差控制在1/10^14以内
        // 价格的指数. price = priceFraction * 16 ^ priceExponent
        uint8 priceExponent;

        // 价格分数值. price = priceFraction * 16 ^ priceExponent
        uint48 priceFraction;
    }

    /// @dev 价格信息。
    struct PriceInfoV36 {

        // 记录报价单的索引，为下一次从报价单此处继续更新价格信息做准备
        uint32 index;

        // 报价单所处区块的高度
        uint32 height;

        // 剩余的有效报价单的总规模
        uint32 remainNum;

        // token 余额
        //uint64 tokenAmount;
        // token数量的浮动表示
        uint8 priceExponent;
        uint48 priceFraction;

        // // 平均 token 的价格（多少 token 可以兑换 1 ETH）
        // uint64 avgTokenAmount;
        // 平均价格的浮动表示
        uint8 avgExponent;
        uint48 avgFraction;
        
        // // 波动率的平方，为下次计算新的波动率准备
        // uint32 volatility_sigma_sq;

        // // 记录值，计算新波动率的必要参数
        // uint32 volatility_ut_sq;

        // 波动率的平方。需要除以2^48
        uint48 sigmaSQ;
    }

    /// @dev 表示一个价格通道
    struct PriceChannel {

        // 报价单数组
        PriceSheetV36[] sheets;

        // 价格信息
        PriceInfoV36 price;

        // // 报价手续费
        // uint postFee;

        // // 从上次结算后的吃单计数
        // // TODO: ntoken不需要计数
        // uint nofeeCount;

        // 报价佣金相关信息。
        // 低128位表示当前每笔报价需要收取的佣金值
        // 高128位表示当前累计的不需要收佣金的报价单数量（包括吃单和已经结算的）
        uint feeInfo;
    }

    /// @dev ntoken状态结构，用户缓存ntoken的各种状态
    struct NTokenStatus {
        uint32 genesisBlockNumber;
    }

    /// @dev 用结构体表示一个存储位置，可以使用storage变量，避免多次从mapping中索引
    struct UINT {
        uint value;
    }

    /// @dev 账户信息
    struct Account {
        
        // 挖矿账号地址
        address addr;

        //// nest余额
        //uint nestBalance;

        // 挖矿账号的余额账本
        // tokenAddress=>balance
        mapping(address=>UINT) balances;
    }

    /// @dev 配置
    Config _config;

    /// @dev 账号信息
    Account[] _accounts;

    /// @dev 账号地址映射
    mapping(address=>uint) _accountMapping;

    /// @dev 报价通道
    mapping(address=>PriceChannel) _channels;

    /// @dev ntoken映射缓存
    mapping(address=>address) _addressCache;

    /// @dev 缓存ntoken状态信息
    mapping(address=>NTokenStatus) _ntokenStatusCache;

    /// @dev 缓存双轨报价状态标记
    mapping(address=>uint) _doublePostFlags;

    /// @dev 价格调用入口合约地址
    address _nestPriceFacadeAddress;

    /// @dev NTokenController合约地址
    address _nTokenControllerAddress;

    /// @dev nest账本合约
    address _nestLedgerAddress;

    /// @dev NEST代币合约地址
    address immutable NEST_TOKEN_ADDRESS; // = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    
    // TODO: 确定nest的创世区块
    /// @dev NEST创世区块
    uint immutable NEST_GENESIS_BLOCK; // = 6236588;	

    /// @dev 万分之一eth，手续费单位
    uint constant DIMI_ETHER = 1 ether / 10000;

    /// @dev 批量结算分红的掩码。测试时每16个报价单结算一次，线上版本256个报价单结算一次
    uint constant COLLECT_REWARD_MASK = 0xF;
    
    /// @dev ntoken最多可以挖到100区块
    uint constant MINING_NTOKEN_YIELD_BLOCK_LIMIT = 100;
    
    /// @dev Average block mining interval, ~ 14s
    uint constant ETHEREUM_BLOCK_TIMESPAN = 14;

    /* ========== 治理相关 ========== */

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
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

    /// @dev 修改配置。（修改配置之前，需要对所有的ntoken的收益进行结算）
    /// @param config 配置对象
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev 获取配置
    /// @return 配置对象
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    // /// @dev 设置出矿衰减数组
    // function setReduction(
    //     uint[NEST_REDUCTION_STEP_COUNT] memory nestReductionSteps, 
    //     uint[NTOKEN_REDUCTION_STEP_COUNT] memory ntokenReductionSteps
    // ) external onlyGovernance {
    //     _nestReductionSteps = nestReductionSteps;
    //     _ntokenReductionSteps = ntokenReductionSteps;
    // }

    /* ========== 报价相关 ========== */

    // 获取token对应的ntoken地址
    function _getNTokenAddress(address tokenAddress) private returns (address) {
        
        // 处理禁用ntoken后导致的缓存问题
        address ntokenAddress = _addressCache[tokenAddress];
        if (ntokenAddress == address(0)) {
            ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress);
            if (ntokenAddress != address(0)) {
                _addressCache[tokenAddress] = ntokenAddress;
            }
        }

        return ntokenAddress;
    }

    // 获取ntoken的创世区块
    function _getNTokenGenesisBlock(address ntokenAddress) private returns (uint) {

        uint genesisBlockNumber = uint(_ntokenStatusCache[ntokenAddress].genesisBlockNumber);
        if (genesisBlockNumber == 0) {
            (genesisBlockNumber,) = INToken(ntokenAddress).checkBlockInfo();
            _ntokenStatusCache[ntokenAddress].genesisBlockNumber = uint32(genesisBlockNumber);
        }

        return genesisBlockNumber;
    }

    /// @dev 清空缓存的ntoken信息。如果发生ntoken被禁用后重建，需要调用此方法
    /// @param tokenAddress token地址
    function resetNTokenCache(address tokenAddress) public {

        address ntokenAddress = _getNTokenAddress(tokenAddress);
        _ntokenStatusCache[ntokenAddress] = NTokenStatus(uint32(0));
        _addressCache[tokenAddress] = address(0);
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
        uint fee = ethNum * uint(config.postFeeRate) * DIMI_ETHER;
        require(msg.value == fee + ethNum * 1 ether, "NM:!value");

        // 3. 检查报价轨道
        // 检查是否允许单轨报价
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");

        // nest单位不同，但是也早已经超过此发行数量，不再做额外判断
        require(IERC20(ntokenAddress).totalSupply() < uint(config.doublePostThreshold) * 10000 ether, "NM:!post2");        

        // 4. 存入佣金
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheetV36[] storage sheets = channel.sheets;
        
        // 每隔256个报价单存入一次收益，扣除吃单的次数
        uint length = sheets.length;
        // {
        //     uint feeInfo = channel.feeInfo;
        //     if (length & COLLECT_REWARD_MASK == COLLECT_REWARD_MASK || fee != (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) {
        //         INestLedger(_nestLedgerAddress).carveReward { 
        //             value: fee + (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) * (COLLECT_REWARD_MASK - (feeInfo >> 128)) 
        //         } (ntokenAddress);
        //         // 更新佣金信息
        //         // 当前累计的不需要收佣金的报价单数量清零，因此无需给高128位赋值
        //         channel.feeInfo = fee;
        //     }
        // }
        _collect(channel, ntokenAddress, length, fee, fee);

        // 5. 冻结资产
        uint accountIndex = _addressIndex(msg.sender);

        // 冻结token，nest
        // 由于使用浮点表示法(uint48 fraction, uint8 exponent)会带来一定的精度损失
        // 按照tokenAmountPerEth * ethNum冻结资产后，退回的时候可能损失精度差部分
        // 实际应该按照decodeFloat(fraction, exponent) * ethNum来冻结
        // 但是考虑到损失在1/10^14以内，因此忽略此处的损失，精度损失的部分，将来可以作为系统收益转出
        //freeze2(tokenAddress, tokenAmountPerEth * ethNum, POST_PLEDGE_UNIT);
        //mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        //freeze(balances, tokenAddress, tokenAmountPerEth * ethNum);
        //freeze(balances, NEST_TOKEN_ADDRESS, uint(config.nestPledgeNest) * 1000 ether);
        _freeze2(_accounts[accountIndex].balances, tokenAddress, tokenAmountPerEth * ethNum, uint(config.nestPledgeNest) * 1000 ether);

        // 6. 计算价格
        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 7. 创建报价单
        // (uint48 fraction, uint8 exponent) = encodeFloat(tokenAmountPerEth);
        // sheets.push(PriceSheetV36(
        //     uint32(accountIndex),       // uint32 miner;
        //     uint32(block.number),       // uint32 height;
        //     uint32(ethNum),             // uint32 remainNum;
        //     uint32(ethNum),             // uint32 ethNumBal;
        //     uint32(ethNum),             // uint32 tokenNumBal;
        //     uint32(POST_NEST_1K_ONE),   // uint32 nestNum1k;
        //     uint8(0),                   // uint8 level;
        //     exponent,                   // uint8 priceExponent;
        //     fraction                    // uint48 priceFraction;
        // ));

        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), uint(config.nestPledgeNest), 0, tokenAmountPerEth);
    }

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev  Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
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
        uint fee = ethNum * uint(config.postFeeRate) * DIMI_ETHER;
        require(msg.value == fee + ethNum * 2 ether, "NM:!value");

        // 3. 检查报价轨道
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");

        // 4. 存入佣金
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheetV36[] storage sheets = channel.sheets;
        // 每隔256个报价单存入一次收益，扣除吃单的次数
        uint length = sheets.length;
        // {
        //     uint feeInfo = channel.feeInfo;
        //     if (length & COLLECT_REWARD_MASK == COLLECT_REWARD_MASK || fee != (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) {
        //         INestLedger(_nestLedgerAddress).carveReward { 
        //             value: fee + (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) * (COLLECT_REWARD_MASK - (feeInfo >> 128)) 
        //         } (ntokenAddress);
        //         // 更新佣金信息
        //         // 当前累计的不需要收佣金的报价单数量清零，因此无需给高128位赋值
        //         channel.feeInfo = fee;
        //     }
        // }
        _collect(channel, ntokenAddress, length, fee, fee);

        // 5. 冻结资产
        uint accountIndex = _addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        _freeze(balances, tokenAddress, ethNum * tokenAmountPerEth);
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _freeze(balances, NEST_TOKEN_ADDRESS, ethNum * ntokenAmountPerEth + uint(config.nestPledgeNest) * 1000 ether);
        } else {
            // TODO: token和ntoken一起冻结
            _freeze(balances, ntokenAddress, ethNum * ntokenAmountPerEth);
            _freeze(balances, NEST_TOKEN_ADDRESS, uint(config.nestPledgeNest) * 2000 ether);
        }
        
        // 6. 计算价格
        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        // TODO: 考虑在计算价格的时候帮人关闭报价单
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 7. 创建报价单
        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), uint(config.nestPledgeNest), 0, tokenAmountPerEth);

        channel = _channels[ntokenAddress];
        sheets = channel.sheets;

        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        _stat(channel, sheets, uint(config.priceEffectSpan));
        emit Post(ntokenAddress, msg.sender, sheets.length, ethNum, ntokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), uint(config.nestPledgeNest), 0, ntokenAmountPerEth);
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
        PriceSheetV36[] storage sheets = channel.sheets;
        PriceSheetV36 memory sheet = sheets[index];

        // 3.检查报价单状态
        require(uint(sheet.remainNum) >= biteNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        {
            // 每隔256个报价单存入一次收益，扣除吃单的次数
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            if (tokenAddress != ntokenAddress) {
                _collect(channel, ntokenAddress, sheets.length, 0, uint(config.postEthUnit) * uint(config.postFeeRate) * DIMI_ETHER);
            }
            if (uint(config.biteFeeRate) > 0) {
                INestLedger(_nestLedgerAddress).carveReward { 
                    value: biteNum * uint(config.biteFeeRate) * DIMI_ETHER
                } (ntokenAddress);
            }
        }

        // 4. 计算需要的eth, token, nest数量
        //uint needEthValue;
        uint needTokenValue;
        uint level = uint(sheet.level);

        // 当吃单深度小于4的时候, nest和报价规模都翻倍
        if (level < uint(config.maxBiteNestedLevel)) {
            // 翻倍报价 + 用于买入token的数量，一共三倍
            //needEthValue = biteNum * 3 ether;
            require(msg.value == biteNum * 3 ether + biteNum * uint(config.biteFeeRate) * DIMI_ETHER, "NM:!value");
            // 翻倍报价
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
            ++level;
        } 
        // 当吃单深度达到4或以上时, nest翻倍, 规模不翻倍
        else {
            // 单倍报价 + 用于买入token的数量，一共两倍
            //needEthValue = biteNum * 2 ether;
            require(msg.value == biteNum * 2 ether + biteNum * uint(config.biteFeeRate) * DIMI_ETHER, "NM:!value");
            // 单倍报价
            needTokenValue = newTokenAmountPerEth * biteNum;
            if (level < 255) ++level;
        }

        // 转入的eth数量必须正确
        //require(msg.value == needEthValue, "NestMining:eth value error");

        // 需要抵押的nest数量
        uint needNest1k = ((biteNum << 1) / uint(config.postEthUnit)) * uint(config.nestPledgeNest);

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

        // 5.更新被吃的报价单
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal + biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal - biteNum);
        sheets[index] = sheet;

        // 6. 计算价格
        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 7.生成吃单报价单
        emit Post(tokenAddress, msg.sender, sheets.length, uint32(biteNum << 1), newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(biteNum << 1), needNest1k, level, newTokenAmountPerEth);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) override external payable {

        Config memory config = _config;

        // 1.参数检查
        require(biteNum > 0 && biteNum % uint(config.postEthUnit) == 0, "NM:!biteNum");
        require(newTokenAmountPerEth > 0, "NM:!price");

        // 2.加载报价单
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheetV36[] storage sheets = channel.sheets;
        PriceSheetV36 memory sheet = sheets[index];

        // 3.检查报价单状态
        require(uint(sheet.remainNum) >= biteNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        {
            // 每隔256个报价单存入一次收益，扣除吃单的次数
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            if (tokenAddress != ntokenAddress) {
                _collect(channel, ntokenAddress, sheets.length, 0, uint(config.postEthUnit) * uint(config.postFeeRate) * DIMI_ETHER);
            }
            if (uint(config.biteFeeRate) > 0) {
                INestLedger(_nestLedgerAddress).carveReward { 
                    value: biteNum * uint(config.biteFeeRate) * DIMI_ETHER
                } (ntokenAddress);
            }
        }
        // {
        //     uint feeInfo = channel.feeInfo;
        //     if (sheets.length & COLLECT_REWARD_MASK == COLLECT_REWARD_MASK || uint(config.postEthUnit) * uint(config.postFeeRate) * DIMI_ETHER != (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) {
        //         address ntokenAddress = getNTokenAddress(tokenAddress);
        //         if (tokenAddress != ntokenAddress) {
        //             INestLedger(_nestLedgerAddress).carveReward { 
        //                 value: (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) * (COLLECT_REWARD_MASK - (feeInfo >> 128)) 
        //             } (ntokenAddress);
        //             // 更新佣金信息
        //             // 当前累计的不需要收佣金的报价单数量清零，因此无需给高128位赋值
        //             channel.feeInfo = uint(config.postEthUnit) * uint(config.postFeeRate) * DIMI_ETHER;
        //         }
        //     } else {
        //         channel.feeInfo = (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | (((feeInfo >> 128) + 1) << 128);
        //     }
        // }

        // 4. 计算需要的eth, token, nest数量
        //uint needEthValue;
        uint needTokenValue;
        uint level = uint(sheet.level);

        // 当吃单深度小于4的时候, nest和报价规模都翻倍
        if (level < uint(config.maxBiteNestedLevel)) {
            // 翻倍报价 - 卖出token换得的数量，一共一倍
            //needEthValue = biteNum * 1 ether;
            require(msg.value == biteNum * 1 ether + biteNum * uint(config.biteFeeRate) * DIMI_ETHER, "NM:!value");

            // 翻倍报价
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
            ++level;
        } 
        // 当吃单深度达到4或以上时, nest翻倍, 规模不翻倍
        else {
            // 单倍报价 - 用于买入token的数量，一共0倍
            //needEthValue = 0 ether;
            require(msg.value == biteNum * uint(config.biteFeeRate) * DIMI_ETHER, "NM:!value");

            // 单倍报价
            needTokenValue = newTokenAmountPerEth * biteNum;
            if (level < 255) ++level;
        }
        
        // 转入的eth数量必须正确
        //require(msg.value == needEthValue, "NestMining:eth value error");

        // 需要抵押的nest数量
        uint needNest1k = ((biteNum << 1) / uint(config.postEthUnit)) * uint(config.nestPledgeNest);

        // 5.结算
        // 冻结nest
        uint accountIndex = _addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
        if (tokenAddress == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1000 ether;
        } else {
            _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether);        
        }

        // 冻结token
        //uint backTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum;
        //freeze(tokenAddress, balances[tokenAddress], needTokenValue + backTokenValue);
        _freeze(balances, tokenAddress, needTokenValue + decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum);

        // 6.更新被吃的报价单信息
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal - biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal + biteNum);
        sheets[index] = sheet;

        // 7. 计算价格
        // 根据目前的机制，刚添加的报价单不可能生效，因此计算价格放在添加报价单之前，这样可以减少不必要的遍历
        _stat(channel, sheets, uint(config.priceEffectSpan));

        // 8.生成吃单报价
        emit Post(tokenAddress, msg.sender, sheets.length, uint32(biteNum << 1), newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(biteNum << 1), needNest1k, level, newTokenAmountPerEth);
    }

    // 创建报价单
    function _createPriceSheet(
        PriceSheetV36[] storage sheets, 
        uint accountIndex, 
        uint32 ethNum, 
        uint nestNum1k, 
        uint level, 
        uint tokenAmountPerEth
    ) private {
        
        (uint48 fraction, uint8 exponent) = encodeFloat(tokenAmountPerEth);
        sheets.push(PriceSheetV36(
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
    
    // uint constant NEST_REDUCTION_STEP_COUNT = 10;
    // uint constant NTOKEN_REDUCTION_STEP_COUNT = 10;
    // uint constant NEST_STABLE_MINING_SPEED = 40 ether;
    // uint constant NTOKEN_STABLE_MINING_SPEED = 0.4 ether;

    /// @dev nest衰减梯度数组
    //uint[NEST_REDUCTION_STEP_COUNT] _nestReductionSteps;

    /// @dev ntoken衰减梯度数组
    //uint[NTOKEN_REDUCTION_STEP_COUNT] _ntokenReductionSteps;

    // TODO: 出矿衰减数组是否需要修改，如果不需要修改，考虑改为在一个常量中表示
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

        // TODO: 考虑同时支持token和ntoken的关闭

        //PriceChannel storage channel = _channels[tokenAddress];
        PriceSheetV36[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheetV36 memory sheet = sheets[index];

        uint accountIndex = uint(sheet.miner);
        // 检查报价单状态，是否达到生效区块间隔或者被吃完
        if (accountIndex > 0 && (uint(sheet.height) + uint(config.priceEffectSpan) < block.number || uint(sheet.remainNum) == 0)) {

            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            // 关闭即将覆盖的报价单
            sheet.miner = uint32(0);

            // 吃单报价和ntoken报价不挖矿
            if (uint(sheet.level) > 0 || tokenAddress == ntokenAddress) {
                _unfreeze2(
                    balances,
                    tokenAddress, 
                    decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
                    uint(sheet.nestNum1k) * 1000 ether
                );
            } 
            // 挖矿逻辑
            else {
                
                (uint minedBlocks, uint count) = _calcMinedBlocks(sheets, index, uint(sheet.height));
                // nest挖矿
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                    _unfreeze2(
                        balances,
                        // 解冻token
                        tokenAddress, 
                        // 解冻token数量 = price * tokenNumBal
                        decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
                        // 解冻抵押的nest和挖矿的nest
                        uint(sheet.nestNum1k) * 1000 ether + minedBlocks * _redution(block.number - NEST_GENESIS_BLOCK) * 1 ether * uint(config.minerNestReward) / 10000 / count
                    );
                } 
                // ntoken挖矿
                else {

                    // 最多挖到100区块
                    if (minedBlocks > MINING_NTOKEN_YIELD_BLOCK_LIMIT) {
                        minedBlocks = MINING_NTOKEN_YIELD_BLOCK_LIMIT;
                    }
                    
                    uint mined = (minedBlocks * _redution(block.number - _getNTokenGenesisBlock(ntokenAddress)) * 0.01 ether) / count;

                    // ntoken竞拍者分成
                    address bidder = INToken(ntokenAddress).checkBidder();

                    // 新的ntoken
                    if (bidder == address(this)) {
                        // 出矿全部给矿工
                        _unfreeze3(
                            balances,
                            // 解冻token
                            tokenAddress, 
                            // 解冻token数量 = price * tokenNumBal
                            decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
                            // 挖矿的ntoken
                            ntokenAddress,
                            // 出矿数量和分成
                            mined,
                            // 解冻抵押的nest和挖矿的nest
                            uint(sheet.nestNum1k) * 1000 ether
                        );

                        // TODO: 出矿逻辑放到取回里面实现，减少gas消耗
                        // 挖矿
                        INToken(ntokenAddress).mint(mined, address(this));
                    }
                    // 老的ntoken
                    else {
                        // 出矿95%给矿工
                        _unfreeze3(
                            balances,
                            // 解冻token
                            tokenAddress, 
                            // 解冻token数量 = price * tokenNumBal
                            decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
                            // 挖矿的ntoken
                            ntokenAddress,
                            // 出矿数量和分成
                            mined * uint(config.minerNTokenReward) / 10000,
                            // 解冻抵押的nest和挖矿的nest
                            uint(sheet.nestNum1k) * 1000 ether
                        );

                        // 考虑到同一区块内多笔转账是小概率事件，可以再每个关闭操作中给竞拍者发ntoken
                        // 5%给竞拍者
                        _unfreeze(_accounts[_addressIndex(bidder)].balances, ntokenAddress, mined * (10000 - uint(config.minerNTokenReward)) / 10000);
                        
                        // TODO: 出矿逻辑放到取回里面实现，减少gas消耗
                        // 挖矿
                        INest_NToken(ntokenAddress).increaseTotal(mined);
                    }
                }
            }

            // 转回其eth
            if (uint(sheet.ethNumBal) > 0) {
                //address payable miner = address(uint160(indexAddress(accountIndex)));
                //miner.transfer(uint(sheet.ethNumBal) * 1 ether);
                payable(address(uint160(indexAddress(accountIndex)))).transfer(uint(sheet.ethNumBal) * 1 ether);
            }

            sheet.ethNumBal = uint32(0);
            sheet.tokenNumBal = uint32(0);
            sheets[index] = sheet;
        }

        _stat(_channels[tokenAddress], sheets, uint(config.priceEffectSpan));
    }

    function _calcMinedBlocks(PriceSheetV36[] storage sheets, uint index, uint height) private view returns (uint minedBlocks, uint count) {

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

    // struct Values {
    //     uint128 ethNum;
    //     uint128 tokenValue;
    //     uint128 nestValue;
    //     uint128 ntokenValue;
    // }

    // /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    // /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    // /// @param tokenAddress The address of TOKEN contract
    // /// @param indices A list of indices of sheets w.r.t. `token`
    // function closeList(address tokenAddress, uint32[] memory indices) override external noContract {
    //     // // TODO: 考虑同时支持token和ntoken的关闭

    //     PriceSheetV36[] storage sheets = _channels[tokenAddress].sheets;
    //     address ntokenAddress = _getNTokenAddress(tokenAddress);
    //     uint accountIndex = uint(sheets[uint(indices[0])].miner);
        
    //     if (accountIndex > 0) {
    
    //         //Config memory config = _config;
    //         // 需要退回的eth个数
    //         //uint totalEthNum = 0;
    //         // 需要解冻的token资产数量
    //         //uint totalTokenValue = 0;
    //         // 需要解冻的nest资产数量
    //         //uint totalNestValue = 0;
    //         // 需要挖出的ntoken数量
    //         //uint totalNTokenValue = 0;
    //         Values memory total;

    //         for (uint i = 0; i < indices.length; ++i) {
                
    //             // 1. 遍历报价单
    //             //(uint tokenValue, uint nestValue, uint ntokenValue, uint ethNum) = _close(sheets, uint(indices[i]), accountIndex, tokenAddress, ntokenAddress);
    //             Values memory value = _close(sheets, uint(indices[i]), accountIndex, tokenAddress, ntokenAddress);
    //             total.ethNum += value.ethNum;
    //             total.tokenValue += value.tokenValue;
    //             total.nestValue += value.nestValue;
    //             total.ntokenValue += value.ntokenValue;
    //         }
    //         mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;

    //         // 3. 解冻资产
    //         // 5. 转账
    //         if (uint128(total.ethNum) > 0) {
    //             payable(address(uint160(indexAddress(accountIndex)))).transfer(uint(total.ethNum) * 1 ether);
    //         }
    //         _unfreeze3(balances, tokenAddress, uint(total.tokenValue), ntokenAddress, uint(total.ntokenValue), uint(total.nestValue));
    //         // 4. 出矿逻辑
    //         // if ((total.ntokenValue) > 0) {
                
    //         // }
    //     }
    // }

    // function _close(PriceSheetV36[] storage sheets, uint index, uint accountIndex, address tokenAddress, address ntokenAddress) private returns (Values memory value) {
    // //(uint totalTokenValue, uint totalNestValue, uint totalNTokenValue, uint totalEthNum) {
        
    //     Config memory config = _config;
    //     PriceSheetV36 memory sheet = sheets[index];
    //     require(accountIndex == uint(sheet.miner), "NM:!miner");
    //     // 2. 找到可以关闭的报价单
    //     // 检查报价单状态，是否达到生效区块间隔或者被吃完
    //     if ((uint(sheet.height) + uint(config.priceEffectSpan) < block.number || uint(sheet.remainNum) == 0)) {
    //         // 将报价矿工注册编号清空，表示报价单已经关闭
    //         sheet.miner = uint32(0);
    //         // 吃单报价和ntoken报价不挖矿
    //         if (uint(sheet.level) > 0 || tokenAddress == ntokenAddress) {
    //             // _unfreeze2(
    //             //     balances,
    //             //     tokenAddress, 
    //             //     decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
    //             //     uint(sheet.nestNum1k) * 1000 ether
    //             // );
    //             value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
    //             value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
    //         } 
    //         // 挖矿逻辑
    //         else {
                
    //             (uint minedBlocks, uint count) = _calcMinedBlocks(sheets, index, uint(sheet.height));
    //             // nest挖矿
    //             if (ntokenAddress == NEST_TOKEN_ADDRESS) {
    //                 // _unfreeze2(
    //                 //     balances,
    //                 //     // 解冻token
    //                 //     tokenAddress, 
    //                 //     // 解冻token数量 = price * tokenNumBal
    //                 //     decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
    //                 //     // 解冻抵押的nest和挖矿的nest
    //                 //     uint(sheet.nestNum1k) * 1000 ether + minedBlocks * _redution(block.number - NEST_GENESIS_BLOCK) * 1 ether * uint(config.minerNestReward) / 10000 / count
    //                 // );
    //                 value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
    //                 value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether + minedBlocks * _redution(block.number - NEST_GENESIS_BLOCK) * 1 ether * uint(config.minerNestReward) / 10000 / count);
    //             } 
    //             // ntoken挖矿
    //             else {
    //                 // 最多挖到100区块
    //                 if (minedBlocks > MINING_NTOKEN_YIELD_BLOCK_LIMIT) {
    //                     minedBlocks = MINING_NTOKEN_YIELD_BLOCK_LIMIT;
    //                 }
                    
    //                 uint mined = (minedBlocks * _redution(block.number - _getNTokenGenesisBlock(ntokenAddress)) * 0.01 ether) / count;
    //                 // ntoken竞拍者分成
    //                 address bidder = INToken(ntokenAddress).checkBidder();
    //                 // 新的ntoken
    //                 if (bidder == address(this)) {
    //                     // 出矿全部给矿工
    //                     // _unfreeze3(
    //                     //     balances,
    //                     //     // 解冻token
    //                     //     tokenAddress, 
    //                     //     // 解冻token数量 = price * tokenNumBal
    //                     //     decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
    //                     //     // 挖矿的ntoken
    //                     //     ntokenAddress,
    //                     //     // 出矿数量和分成
    //                     //     mined,
    //                     //     // 解冻抵押的nest和挖矿的nest
    //                     //     uint(sheet.nestNum1k) * 1000 ether
    //                     // );
    //                     value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
    //                     value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
    //                     value.ntokenValue = uint128(mined);
    //                     // TODO: 出矿逻辑放到取回里面实现，减少gas消耗
    //                     // 挖矿
    //                     INToken(ntokenAddress).mint(mined, address(this));
    //                 }
    //                 // 老的ntoken
    //                 else {
    //                     // // 出矿95%给矿工
    //                     // _unfreeze3(
    //                     //     balances,
    //                     //     // 解冻token
    //                     //     tokenAddress, 
    //                     //     // 解冻token数量 = price * tokenNumBal
    //                     //     decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
    //                     //     // 挖矿的ntoken
    //                     //     ntokenAddress,
    //                     //     // 出矿数量和分成
    //                     //     mined * uint(config.minerNTokenReward) / 10000,
    //                     //     // 解冻抵押的nest和挖矿的nest
    //                     //     uint(sheet.nestNum1k) * 1000 ether
    //                     // );
    //                     value.tokenValue = uint128(decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
    //                     value.nestValue = uint128(uint(sheet.nestNum1k) * 1000 ether);
    //                     value.ntokenValue = uint128(mined * uint(config.minerNTokenReward) / 10000);
    //                     // 考虑到同一区块内多笔转账是小概率事件，可以再每个关闭操作中给竞拍者发ntoken
    //                     // 5%给竞拍者
    //                     _unfreeze(_accounts[_addressIndex(bidder)].balances, ntokenAddress, mined * (10000 - uint(config.minerNTokenReward)) / 10000);
                        
    //                     // TODO: 出矿逻辑放到取回里面实现，减少gas消耗
    //                     // 挖矿
    //                     INest_NToken(ntokenAddress).increaseTotal(mined);
    //                 }
    //             }
    //         }
    //         // // 转回其eth
    //         // if (uint(sheet.ethNumBal) > 0) {
    //         //     //address payable miner = address(uint160(indexAddress(accountIndex)));
    //         //     //miner.transfer(uint(sheet.ethNumBal) * 1 ether);
    //         //     payable(address(uint160(indexAddress(accountIndex)))).transfer(uint(sheet.ethNumBal) * 1 ether);
    //         // }
    //         value.ethNum = uint128(sheet.ethNumBal);
    //         sheet.ethNumBal = uint32(0);
    //         sheet.tokenNumBal = uint32(0);
    //         sheets[index] = sheet;
    //     }
    // }

    function _stat(PriceChannel storage channel, PriceSheetV36[] storage sheets, uint priceEffectSpan) private {

        // 找到token的价格信息
        PriceInfoV36 memory p0 = channel.price;
        
        // 报价单数组长度
        uint length = sheets.length;
        // 即将处理的报价单在报价数组里面的索引
        uint index = uint(p0.index);
        // 已经计算价格的最新区块高度
        uint prev = uint(p0.height);
        // 用于计算价格的eth基数变量
        uint totalEth = 0; //uint(p0.remainNum);
        // 用于计算价格的token计数变量
        uint totalTokenValue = 0; //decodeFloat(p0.priceFraction, p0.priceExponent) * totalEth;
        // 当前报价单所在的区块高度
        uint height;
        // 当前价格
        uint price;

        // 遍历报价单，找到生效价格
        PriceSheetV36 memory sheet;
        for (;;) {
            
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
        if (length & COLLECT_REWARD_MASK == COLLECT_REWARD_MASK) {
            INestLedger(_nestLedgerAddress).carveReward { 
                value: currentFee + oldFee * (COLLECT_REWARD_MASK - (feeInfo >> 128)) 
            } (ntokenAddress);
            // 更新佣金信息
            // 当前累计的不需要收佣金的报价单数量清零，因此无需给高128位赋值
            channel.feeInfo = newFee;
        } else if (newFee != oldFee) {
            INestLedger(_nestLedgerAddress).carveReward { 
                value: currentFee + oldFee * (COLLECT_REWARD_MASK - (feeInfo >> 128)) 
            } (ntokenAddress);
            // 更新佣金信息
            // 当前累计的不需要收佣金的报价单数量清零，因此无需给高128位赋值
            channel.feeInfo = newFee | (((length & COLLECT_REWARD_MASK) + 1) << 128);
        } else if (currentFee == 0) {
            channel.feeInfo = newFee | (((feeInfo >> 128) + 1) << 128);
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
            //Config memory config = _config;
            channel.feeInfo = (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | (count << 128);
        }
    }

    /// @dev 分页列出报价单
    /// @param tokenAddress 目标token地址
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式. 0倒序, 非0正序
    /// @return 报价单列表
    function list(address tokenAddress, uint offset, uint count, uint order) override external view returns (PriceSheetView[] memory) {
        
        PriceSheetV36[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheetView[] memory result = new PriceSheetView[](count);
        PriceSheetV36 memory sheet;

        // 倒序
        if (order == 0) {

            uint index = sheets.length - offset;
            uint end = index - count;
            uint i = 0;
            while (index > end) {

                sheet = sheets[--index];
                result[i++] = PriceSheetView(
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
        } 
        // 正序
        else {
            
            uint index = offset;
            uint end = index + count;
            uint i = 0;
            while (index < end) {

                sheet = sheets[index];
                result[i++] = PriceSheetView(
                    // 索引号
                    uint32(index++),
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
        }

        return result;
    }

    /// @dev 预估出矿量
    /// @param tokenAddress 目标token地址
    /// @return 预估的出矿量
    function estimate(address tokenAddress) override external view returns (uint) {

        PriceSheetV36[] storage sheets = _channels[tokenAddress].sheets;
        uint index = sheets.length;
        while (index > 0) {

            PriceSheetV36 memory sheet = sheets[--index];
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
    function getMinedBlocks(address tokenAddress, uint index) override public view returns (uint minedBlocks, uint count) {
        
        PriceSheetV36[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheetV36 memory sheet = sheets[index];
        
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

    /// @dev 解冻token和nest
    /// @param balances 账本
    /// @param tokenAddress token地址
    /// @param tokenValue token数量
    /// @param nestValue nest数量
    function _unfreeze2(mapping(address=>UINT) storage balances, address tokenAddress, uint tokenValue, uint nestValue) private {

        UINT storage balance = balances[tokenAddress];
        balance.value = balance.value + tokenValue;

        balance = balances[NEST_TOKEN_ADDRESS];
        balance.value = balance.value + nestValue;
    }

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
        PriceInfoV36 memory priceInfo = _channels[tokenAddress].price;
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
        PriceInfoV36 memory priceInfo = _channels[tokenAddress].price;

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
        PriceSheetV36[] storage sheets = _channels[tokenAddress].sheets;
        uint index = sheets.length;

        // 找到已经生效的报价单索引
        while (index > 0) { 
            PriceSheetV36 memory sheet = sheets[--index];
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
                // if (totalEth > 0) {
                //     return (height, totalTokenValue / totalEth);
                // }
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

    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    function triggeredPrice2(address tokenAddress) override external returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice) {
        (blockNumber, price) = triggeredPrice(tokenAddress);
        (ntokenBlockNumber, ntokenPrice) = triggeredPrice(_getNTokenAddress(tokenAddress));
    }

    /// @dev 获取最新的触发价格完整信息
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

    /// @dev 获取最新的生效价格
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