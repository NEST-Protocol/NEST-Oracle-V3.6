// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/TransferHelper.sol";
import "./interface/INestMining.sol";
import "./interface/INestDAO.sol";
import "./interface/INestQuery.sol";
import "./lib/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// TODO: 实现价格查询接口
contract NestMining is INestMining, INestQuery {

    using SafeMath for uint;

    uint constant PRICE_EFFECT_SPAN = 20;
    uint constant MAX_SHEET_DURING_SPAN = PRICE_EFFECT_SPAN * 5;
    uint constant MAX_SHEET_INDEX = MAX_SHEET_DURING_SPAN - 1;
    uint constant BATCH_ADD_REWARD_SIZE = 0x10;
    uint constant BATCH_ADD_REWARD_MASK = BATCH_ADD_REWARD_SIZE - 1;

    uint constant POST_PLEDGE_UNIT = 100000 ether;
    uint constant POST_ETH_UNIT = 30;
    uint constant POST_ETH_UINT2 = POST_ETH_UNIT << 1;
    uint constant POST_NEST_1K_ONE = 100;
    uint constant POST_FEE_RATE = 33 ether / 10000;

    uint constant MAX_BITE_NESTED_LEVEL = 4;

    /// @dev Average block mining interval, ~ 14s
    uint constant ETHEREUM_BLOCK_TIMESPAN = 14;

    event Post(address tokenAddress, address miner, uint index, uint ethNum, uint price);

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

        // TODO: 重新优化数据结构
        uint32 remainNum;

        // token 余额
        uint64 tokenAmount;

        // 波动率的平方，为下次计算新的波动率准备
        uint32 volatility_sigma_sq;

        // 记录值，计算新波动率的必要参数
        uint32 volatility_ut_sq;

        // 平均 token 的价格（多少 token 可以兑换 1 ETH）
        uint64 avgTokenAmount;
    }

    /// @dev 表示一个价格通道
    struct PriceChannel {
        
        // // 指向报价数据结构当前位置的指针，0~99循环
        // uint index;

        // 报价单数组
        PriceSheetV36[] sheets;

        // 从上次结算后的吃单计数
        uint256 biteCount;

        // // 挖矿信息
        // MiningShare[] shares;

        // 价格信息
        PriceInfoV36 price;
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
    
    struct Param {
        uint empty;
    }

    /// @dev 账号信息
    Account[] accounts;

    /// @dev 报价通道
    mapping(address=>PriceChannel) channels;

    /// @dev 账号地址映射
    mapping(address=>uint) accountMapping;

    /// @dev DAO合约地址
    INestDAO immutable NEST_DAO_CONTRACT;

    /// @dev NEST代币合约地址
    address immutable NEST_TOKEN_ADDRESS; // = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

    constructor(address nestTokenAddress, address nestDaoAddress) public {
        
        // 占位，实际的注册账号的索引必须大于0
        accounts.push(Account(address(0)));

        NEST_TOKEN_ADDRESS = nestTokenAddress;
        NEST_DAO_CONTRACT = INestDAO(nestDaoAddress);
    }

    /* ========== 报价相关 ========== */

    /// @notice Post a price sheet for TOKEN
    /// @dev  It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address tokenAddress, uint ethNum, uint tokenAmountPerEth) override external payable {
        
        // TODO: nToken映射问题

        // 1. 检查
        require(ethNum > 0 && ethNum % POST_ETH_UNIT == 0, "NestMining:ethNum invalid");
        require(tokenAmountPerEth > 0, "NestMining:price invalid");
        require(msg.sender == tx.origin, "NestMining:not for contract");

        // TODO: 检查是否允许单轨报价
        
        // 2. 转账
        // 2.1 手续费
        uint fee = ethNum * POST_FEE_RATE;
        require(msg.value == fee + ethNum * 1 ether, "NestMining:eth value error");

        // TODO: 改为批量触发收益
        // TODO: NestDAO和nTokenDAO分成
        address ntokenAddress = NEST_TOKEN_ADDRESS;
        PriceChannel storage channel = channels[tokenAddress];
        // 每隔256个报价单存入一次收益，扣除吃单的次数
        uint length = channel.sheets.length;
        if (length & 0xFF == 0xFF) {
            NEST_DAO_CONTRACT.addReward { value: fee * (0x100 - channel.biteCount) } (ntokenAddress);
            channel.biteCount = 0;
        }

        // 2.2 
        uint accountIndex = addressIndex(msg.sender);

        // 冻结token，nest
        // 由于使用浮点表示法(uint48 fraction, uint8 exponent)会带来一定的精度损失
        // 按照tokenAmountPerEth * ethNum冻结资产后，退回的时候可能损失精度差部分
        // 实际应该按照decodeFloat(fraction, exponent) * ethNum来冻结
        // 但是考虑到损失在1/10^14以内，因此忽略此处的损失，精度损失的部分，将来可以作为系统收益转出
        //freeze2(tokenAddress, tokenAmountPerEth * ethNum, POST_PLEDGE_UNIT);
        mapping(address=>UINT) storage balances = accounts[accountIndex].balances;
        freeze(tokenAddress, balances[tokenAddress], tokenAmountPerEth * ethNum);
        freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], POST_PLEDGE_UNIT);

        // 3. 生成报价单
        (uint48 fraction, uint8 exponent) = encodeFloat(tokenAmountPerEth);
        channel.sheets.push(PriceSheetV36(
            uint32(accountIndex),       // uint32 miner;
            uint32(block.number),       // uint32 height;
            uint32(ethNum),             // uint32 remainNum;
            uint32(ethNum),             // uint32 ethNumBal;
            uint32(ethNum),             // uint32 tokenNumBal;
            uint32(POST_NEST_1K_ONE),   // uint32 nestNum1k;
            uint8(0),                   // uint8 level;
            exponent,                   // uint8 priceExponent;
            fraction                    // uint48 priceFraction;
        ));
        
        // 4. 计算
        _stat(tokenAddress);
    }

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev  Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(address tokenAddress, uint ethNum, uint tokenAmountPerEth, uint ntokenAmountPerEth) override external payable {

        // TODO: nToken映射问题
        address ntokenAddress = NEST_TOKEN_ADDRESS;

        // 1. 检查
        require(ethNum > 0 && ethNum % POST_ETH_UNIT == 0, "NestMining:ethNum invalid");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "NestMining:price invalid");
        require(msg.sender == tx.origin, "NestMining:not for contract");
        
        // 2. 手续费
        uint fee = ethNum * POST_FEE_RATE;
        require(msg.value == fee + ethNum * 2 ether, "NestMining:eth value error");

        // TODO: 改为批量触发分红
        // TODO: NestDAO和nTokenDAO分成
        // 80%进入nToken的分红池
        //NEST_DAO_CONTRACT.addETHReward { value: fee * 80 / 100 } (ntokenAddress);
        // 20%进入nest的分红池
        //NEST_DAO_CONTRACT.addETHReward { value: fee * 20 / 100 } (NEST_TOKEN_ADDRESS);
        
        PriceChannel storage channel = channels[tokenAddress];
        // 每隔256个报价单存入一次收益，扣除吃单的次数
        uint length = channel.sheets.length;
        if (length & 0xFF == 0xFF) {
            NEST_DAO_CONTRACT.addReward { value: fee * (0x100 - channel.biteCount) } (ntokenAddress);
            channel.biteCount = 0;
        }
        //NEST_DAO_CONTRACT.addReward { value: fee } (ntokenAddress);

        // 3. 冻结资产
        uint accountIndex = addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = accounts[accountIndex].balances;
        freeze(tokenAddress, balances[tokenAddress], ethNum * tokenAmountPerEth);
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], ethNum * ntokenAmountPerEth + (POST_PLEDGE_UNIT << 1));
        } else {
            // TODO: token和ntoken一起冻结
            freeze(ntokenAddress, balances[ntokenAddress], ethNum * ntokenAmountPerEth);
            freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], POST_PLEDGE_UNIT << 1);
        }

        // 4. 创建报价单
        (uint48 fraction, uint8 exponent) = encodeFloat(tokenAmountPerEth);
        channels[tokenAddress].sheets.push(PriceSheetV36(
            uint32(accountIndex),       // uint32 miner;
            uint32(block.number),       // uint32 height;
            uint32(ethNum),             // uint32 remainNum;
            uint32(ethNum),             // uint32 ethNumBal;
            uint32(ethNum),             // uint32 tokenNumBal;
            uint32(POST_NEST_1K_ONE),   // uint32 nestNum1k;
            uint8(0),                   // uint8 level;
            exponent,                   // uint8 priceExponent;
            fraction                    // uint48 priceFraction;
        ));

        (fraction, exponent) = encodeFloat(ntokenAmountPerEth);
        channels[ntokenAddress].sheets.push(PriceSheetV36(
            uint32(accountIndex),       // uint32 miner;
            uint32(block.number),       // uint32 height;
            uint32(ethNum),             // uint32 remainNum;
            uint32(ethNum),             // uint32 ethNumBal;
            uint32(ethNum),             // uint32 tokenNumBal;
            uint32(POST_NEST_1K_ONE),   // uint32 nestNum1k;
            uint8(0),                   // uint8 level;
            exponent,                   // uint8 priceExponent;
            fraction                    // uint48 priceFraction;
        ));

        // 5. 计算

        // TODO: 考虑在计算价格的时候帮人关闭报价单
        _stat(tokenAddress);
        _stat(ntokenAddress);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) override external payable {

        // 1.检查
        require(biteNum > 0 && biteNum % POST_ETH_UNIT == 0, "NestMining:biteNum invalid");
        require(newTokenAmountPerEth > 0, "NestMining:price invalid");

        // 2.加载报价单
        PriceChannel storage channel = channels[tokenAddress];
        PriceSheetV36[] storage sheets = channel.sheets;
        PriceSheetV36 memory sheet = sheets[index];

        // 3.检查报价单状态
        require(uint(sheet.remainNum) >= biteNum, "NestMining:remainNum not enough");
        require(uint(sheet.height) + PRICE_EFFECT_SPAN >= block.number, "NestMining:price effected");

        // 每隔256个报价单存入一次收益，扣除吃单的次数
        if (channel.sheets.length & 0xFF == 0xFF) {
            
            NEST_DAO_CONTRACT.addReward { 
                value: POST_ETH_UNIT * POST_FEE_RATE * (0xFF - channel.biteCount) 
            } (NEST_DAO_CONTRACT.getNToken(tokenAddress));

            channel.biteCount = 0;
        } else {
            ++channel.biteCount;
        }

        // 4.结算资金
        // 抵押的nest翻倍
        // 前面4次报价规模需要翻倍
        
        // 4. 计算需要的eth, token, nest数量
        //uint needEthValue;
        uint needTokenValue;

        // TODO: level可以超过256
        // 当吃单深度小于4的时候, nest和报价规模都翻倍
        if (uint(sheet.level) < MAX_BITE_NESTED_LEVEL) {
            // 翻倍报价 + 用于买入token的数量，一共三倍
            //needEthValue = biteNum * 3 ether;
            require(msg.value == biteNum * 3 ether, "NestMining:eth value error");
            // 翻倍报价
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
        } 
        // 当吃单深度达到4或以上时, nest翻倍, 规模不翻倍
        else {
            // 单倍报价 + 用于买入token的数量，一共两倍
            //needEthValue = biteNum * 2 ether;
            require(msg.value == biteNum * 2 ether, "NestMining:eth value error");
            // 单倍报价
            needTokenValue = newTokenAmountPerEth * biteNum;
        }

        // 转入的eth数量必须正确
        //require(msg.value == needEthValue, "NestMining:eth value error");

        // 需要抵押的nest数量
        uint needNest1k = (biteNum / POST_ETH_UNIT) * 200;

        // 冻结nest
        uint accountIndex = addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = accounts[accountIndex].balances;
        if (tokenAddress == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1 ether;
        } else {
            freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], needNest1k * 1 ether);        
        }

        // 冻结token
        uint backTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum;
        if (needTokenValue > backTokenValue) {
            freeze(tokenAddress, balances[tokenAddress], needTokenValue - backTokenValue);
        } else {
            unfreeze(balances[tokenAddress], backTokenValue - needTokenValue);
        }

        // 用于吃单的eth转给被吃单者
        // TODO:不应该有此逻辑
        //address payable miner = address(uint160(indexAddress(sheet.miner)));
        //miner.transfer(biteNum * 1 ether);

        // 5.更新被吃的报价单
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal + biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal - biteNum);
        sheets[index] = sheet;

        // 6.生成吃单报价单
        (uint48 fraction, uint8 exponent) = encodeFloat(newTokenAmountPerEth);
        sheets.push(PriceSheetV36(
            uint32(accountIndex),       // uint32 miner;
            uint32(block.number),       // uint32 height;
            uint32(biteNum << 1),       // uint32 remainNum;
            uint32(biteNum << 1),       // uint32 ethNumBal;
            uint32(biteNum << 1),       // uint32 tokenNumBal;
            uint32(needNest1k),         // uint32 nestNum1k;
            uint8(sheet.level + 1),     // uint8 level;
            exponent,                   // uint8 priceExponent;
            fraction                    // uint48 priceFraction;
        ));

        // 7.结算
        _stat(tokenAddress);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) override external payable {

        // 1.检查
        require(biteNum > 0 && biteNum % POST_ETH_UNIT == 0, "NestMining:biteNum invalid");
        require(newTokenAmountPerEth > 0, "NestMining:price invalid");

        // 2.加载报价单
        PriceChannel storage channel = channels[tokenAddress];
        PriceSheetV36[] storage sheets = channel.sheets;
        PriceSheetV36 memory sheet = sheets[index];

        // 3.检查报价单状态
        require(uint(sheet.remainNum) >= biteNum, "NestMining:remainNum not enough");
        require(uint(sheet.height) + PRICE_EFFECT_SPAN >= block.number, "NestMining:price effected");

        // 每隔256个报价单存入一次收益，扣除吃单的次数
        if (channel.sheets.length & 0xFF == 0xFF) {
            NEST_DAO_CONTRACT.addReward { 
                value: POST_ETH_UNIT * POST_FEE_RATE * (0xFF - channel.biteCount) 
            } (NEST_DAO_CONTRACT.getNToken(tokenAddress));
            channel.biteCount = 0;
        } else {
            ++channel.biteCount;
        }

        // 4. 计算需要的eth, token, nest数量
        //uint needEthValue;
        uint needTokenValue;

        // 当吃单深度小于4的时候, nest和报价规模都翻倍
        if (uint(sheet.level) < MAX_BITE_NESTED_LEVEL) {
            // 翻倍报价 - 卖出token换得的数量，一共一倍
            //needEthValue = biteNum * 1 ether;
            require(msg.value == biteNum * 1 ether, "NestMining:eth value error");

            // 翻倍报价
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
        } 
        // 当吃单深度达到4或以上时, nest翻倍, 规模不翻倍
        else {
            // 单倍报价 - 用于买入token的数量，一共0倍
            //needEthValue = 0 ether;
            require(msg.value == 0, "NestMining:eth value error");

            // 单倍报价
            needTokenValue = newTokenAmountPerEth * biteNum;
        }
        
        // 转入的eth数量必须正确
        //require(msg.value == needEthValue, "NestMining:eth value error");

        // 需要抵押的nest数量
        uint needNest1k = (biteNum / POST_ETH_UNIT) * 200;

        // 5.结算
        // 冻结nest
        uint accountIndex = addressIndex(msg.sender);
        mapping(address=>UINT) storage balances = accounts[accountIndex].balances;
        if (tokenAddress == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1 ether;
        } else {
            freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], needNest1k * 1 ether);        
        }

        // 冻结token
        //uint backTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum;
        //freeze(tokenAddress, balances[tokenAddress], needTokenValue + backTokenValue);
        freeze(tokenAddress, balances[tokenAddress], needTokenValue + decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum);

        // 6.更新被吃的报价单信息
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal - biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal + biteNum);
        sheets[index] = sheet;

        // 7.生成吃单报价
        (uint48 fraction, uint8 exponent) = encodeFloat(newTokenAmountPerEth);
        sheets.push(PriceSheetV36(
            uint32(accountIndex),       // uint32 miner;
            uint32(block.number),       // uint32 height;
            uint32(biteNum << 1),       // uint32 remainNum;
            uint32(biteNum << 1),       // uint32 ethNumBal;
            uint32(biteNum << 1),       // uint32 tokenNumBal;
            uint32(needNest1k),         // uint32 nestNum1k;
            uint8(sheet.level + 1),     // uint8 level;
            exponent,                   // uint8 priceExponent;
            fraction                    // uint48 priceFraction;
        ));

        // TODO: 触发报价事件

        _stat(tokenAddress);
    }

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address token, uint index) override external {
        
        // TODO: 考虑同时支持token和ntoken的关闭

        PriceSheetV36[] storage sheets = channels[token].sheets;
        PriceSheetV36 memory sheet = sheets[index];

        uint accountIndex = uint(sheet.miner);
        if (accountIndex > 0) {
            
            // 关闭即将覆盖的报价单
            address payable miner = address(uint160(indexAddress(accountIndex)));
            sheet.miner = 0;

            // 计算出矿量
            uint length = sheets.length;
            uint height = uint(sheet.height);
            uint count = 1;
            uint i = index;
            
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

            uint minedBlocks;
            if (i == 0) {
                // TODO: 考虑第一笔挖矿的出矿量如何计算
                minedBlocks = 10;
            } else {
                minedBlocks = height - prev;
            }

            // TODO: DAO分成，NN分成
            // TODO: nToken出矿，nest出矿
            // 转回其token
            unfreeze2(
                token, 
                decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
                uint(sheet.nestNum1k) * 1000 ether + minedBlocks * 400 ether / count
            );
            //mapping(address=>UINT) storage balances = accounts[addressIndex(msg.sender)].balances;
            //freeze(token, balances[token], decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal));
            //freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], uint(sheet.nestNum1k) * 1000 ether + minedBlocks * 400 ether / count);

            // 转回其eth
            if (uint(sheet.ethNumBal) > 0) {
                miner.transfer(uint(sheet.ethNumBal) * 1 ether);
            }

            sheet.ethNumBal = 0;
            sheet.tokenNumBal = 0;

            sheets[index] = sheet;
        }

        _stat(token);
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint32[] memory indices) override external {

    }

    function _stat(address token) private {
        // TODO: 优化计算逻辑
        PriceChannel storage channel = channels[token];
        // 找到token的价格信息
        PriceInfoV36 memory p0 = channel.price;
        
        // 找到token的报价单数组
        PriceSheetV36[] storage sheets = channel.sheets;

        uint length = sheets.length;
        uint index = uint(p0.index);
        uint prev = uint(p0.height);
        uint totalEth = uint(p0.remainNum);
        uint totalTokenValue = uint(p0.tokenAmount);
        uint height;
        uint price;

        // 遍历报价单，找到生效价格
        PriceSheetV36 memory sheet;
        while (index < length && (height = uint((sheet = sheets[index]).height)) + PRICE_EFFECT_SPAN < block.number) {
        // while (index < length && (uint(sheets[index].height)) + PRICE_EFFECT_SPAN < block.number) {
        //     sheet = sheets[index];
        //     height = uint(sheet.height);

            // 同一区块, 累计价格
            if (prev == height) {
                totalEth += uint(sheet.remainNum);
                totalTokenValue += decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
            } else if (totalEth > 0){

                // 计算价格
                // TODO: 价格表示问题
                price = totalTokenValue / totalEth;

                // 计算平均价格
                // 计算波动率
                if (index == 0) {
                    p0.avgTokenAmount = uint64(price);
                    p0.volatility_sigma_sq = uint32(0);
                    p0.volatility_ut_sq = uint32(0);
                } else {
                    p0.avgTokenAmount = uint64((uint(p0.avgTokenAmount) * 95 + price * 5) / 100);
                    // _ut_sq_2 = _ut_sq / (_interval * ETHEREUM_BLOCK_TIMESPAN);
                    // _new_ut_sq = (tokenA1 / tokenA0 - 1) ^ 2;
                    uint _new_ut_sq = price * 1 ether * uint(p0.remainNum) / uint(p0.tokenAmount) - 1 ether;
                    _new_ut_sq = _new_ut_sq * _new_ut_sq;

                    // _new_sigma_sq = _sigma_sq * 0.95 + _ut_sq_2 * 0.5;
                    uint _new_sigma_sq = ((uint(p0.volatility_sigma_sq)) * 95 + (uint(p0.volatility_ut_sq) / ETHEREUM_BLOCK_TIMESPAN / (height - prev))) / 100;
                    p0.volatility_sigma_sq = uint32(_new_sigma_sq);
                    p0.volatility_ut_sq = uint32(_new_ut_sq);
                    p0.remainNum = uint32(totalEth);
                    p0.tokenAmount = uint64(totalTokenValue);
                    p0.index = uint32(index);
                    p0.height = uint32(height);
                }
                prev = height;
            } else {

            }

            ++index;
        }

        if (uint(p0.height) < prev) {
            p0.height = uint32(prev);
            channel.price = p0;
        }
    }

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function stat(address token) override public 
    {
        _stat(token);
    }

    /// @dev 分页列出报价单
    /// @param tokenAddress 目标token地址
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式. 0倒序, 非0正序
    function list(address tokenAddress, uint offset, uint count, uint order) override external view returns (PriceSheetView[] memory) {
        
        PriceSheetV36[] storage sheets = channels[tokenAddress].sheets;
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
                    uint32(index),
                    indexAddress(sheet.miner),
                    uint32(sheet.height),
                    uint32(sheet.remainNum),
                    uint32(sheet.ethNumBal),
                    uint32(sheet.tokenNumBal),
                    uint32(sheet.nestNum1k),
                    uint8(sheet.level),
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

                //// 索引号
                //uint32 index;

                //// 矿工地址
                //address miner;

                //// 挖矿所在区块高度
                //uint32 height;

                //// 报价剩余规模
                //uint32 remainNum;

                //// 剩余的eth数量
                //uint32 ethNumBal;

                //// 剩余的token对应的eth数量
                //uint32 tokenNumBal;

                //// nest抵押数量（单位: 1000nest）
                //uint32 nestNum1k;

                //// 当前报价单的深度。0表示初始报价，大于0表示吃单报价
                //uint8 level;

                //// 每个eth等值的token数量
                //uint128 price;
                
                sheet = sheets[index];
                result[i++] = PriceSheetView(
                    uint32(index++),
                    indexAddress(sheet.miner),
                    uint32(sheet.height),
                    uint32(sheet.remainNum),
                    uint32(sheet.ethNumBal),
                    uint32(sheet.tokenNumBal),
                    uint32(sheet.nestNum1k),
                    uint8(sheet.level),
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

        PriceSheetV36[] storage sheets = channels[tokenAddress].sheets;
        uint index = sheets.length;
        while (index > 0) {
            
            if (sheets[--index].height == 0) {

                if (tokenAddress == NEST_TOKEN_ADDRESS) {
                    return (block.number - uint(sheets[index].height)) * 4 ether;
                }
                
                return (block.number - uint(sheets[index].height)) * 400 ether;
            }
        }

        return 0;
    }

    /* ========== 账户相关 ========== */

    /// @dev 取出资产
    /// @param tokenAddress 目标token地址
    /// @param value 要取回的数量
    /// @return 实际取回的数量
    function withdraw(address tokenAddress, uint value) override external returns (uint) {

        Account storage account = accounts[accountMapping[msg.sender]];
        uint balance = account.balances[tokenAddress].value;
        require(balance >= value, "NestMining:balance not enough");
        account.balances[tokenAddress].value -= value;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);

        return value;
    }

    /// @dev 查看用户的指定资产数量
    /// @param tokenAddress 目标token地址
    /// @param addr 目标地址
    /// @return 资产数量
    function balanceOf(address tokenAddress, address addr) override external view returns (uint) {
        return accounts[accountMapping[addr]].balances[tokenAddress].value;
    }

    /// @dev 获取指定地址的索引号. 如果不存在，则注册
    /// @param addr 目标地址
    /// @return 索引号
    function addressIndex(address addr) private returns (uint) {

        uint index = accountMapping[addr];
        if (index == 0) {
            //uint length = accounts.length;

            // 超过32位所能存储的最大数字，无法再继续注册新的账户，如果需要支持新的账户，需要更新合约
            require((accountMapping[addr] = index = accounts.length) < 0x100000000, "NestMining:too much accounts");
            accounts.push(Account(addr));
        }

        return index;
    }

    /// @dev 获取给定索引号对应的地址
    /// @param index 索引号
    /// @return 给定索引号对应的地址
    function indexAddress(uint index) override public view returns (address) {
        return accounts[index].addr;
    }

    // /// @dev 获取给定索引号处的Account
    // /// @param index 索引号
    // /// @return 给定索引号对应的Account
    // function getAccount(uint index) private view returns (Account memory) {
    //     return accounts[index];
    // }
    
    /// @dev 获取指定地址的注册索引号
    /// @param addr 目标地址
    /// @return 0表示不存在, 非0表示索引号
    function getAccountIndex(address addr) override external view returns (uint) {
        return accountMapping[addr];
    }

    /// @dev 获取注册账户数组长度
    /// @return 注册账户数组长度
    function getAccountCount() override external view returns (uint) {
        return accounts.length;
    }

    /* ========== 资产管理 ========== */

    /// @dev 冻结token和nest
    /// @param tokenAddress token地址
    /// @param tokenValue token数量
    /// @param nestValue nest数量
    function freeze2(address tokenAddress, uint tokenValue, uint nestValue) private {

        mapping(address=>UINT) storage balances = accounts[addressIndex(msg.sender)].balances;
        
        UINT storage balance = balances[tokenAddress];
        uint balanceValue = balance.value;
        if (balanceValue < tokenValue) {
            TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenValue - balanceValue);
            balance.value = 0;
        } else {
            balance.value = balanceValue - tokenValue;
        }

        balance = balances[NEST_TOKEN_ADDRESS];
        if (balanceValue < nestValue) {
            TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestValue - balanceValue);
            balance.value = 0;
        } else {
            balance.value = balanceValue - nestValue;
        }
    }

    // TODO: 删除此方法
    /// @dev 解冻token和nest
    /// @param tokenAddress token地址
    /// @param tokenValue token数量
    /// @param nestValue nest数量
    function unfreeze2(address tokenAddress, uint tokenValue, uint nestValue) private {

        mapping(address=>UINT) storage balances = accounts[addressIndex(msg.sender)].balances;
        
        UINT storage balance = balances[tokenAddress];
        balance.value = balance.value + tokenValue;

        balance = balances[NEST_TOKEN_ADDRESS];
        balance.value = balance.value + nestValue;
    }

    // TODO: 删除此方法
    /// @dev 解冻token
    /// @param tokenAddress token地址
    /// @param balance 余额结构体
    /// @param value token数量
    function freeze(address tokenAddress, UINT storage balance, uint value) private {

        uint balanceValue = balance.value;
        if (balanceValue < value) {
            TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), value - balanceValue);
            balance.value = 0;
        } else {
            balance.value = (balanceValue - value);
        }
    }

    /// @dev 解冻token
    /// @param balance 余额结构体
    /// @param value token数量
    function unfreeze(UINT storage balance, uint value) private {
        balance.value = balance.value + value;
    }

    /* ========== 价格查询 ========== */
    
    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function triggeredPrice(address tokenAddress) override external view returns (uint blockNumber, uint price) {

        PriceInfoV36 memory priceInfo = channels[tokenAddress].price;
        return (uint(priceInfo.height), uint(priceInfo.tokenAmount) / uint(priceInfo.remainNum));
    }

    /// @dev 获取最新的触发价格完整信息
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return avgPrice 平均价格
    /// @return sigma 波动率的平方
    function triggeredPriceInfo(address tokenAddress) override public view returns (uint blockNumber, uint price, uint avgPrice, uint sigma) {
        
        PriceInfoV36 memory priceInfo = channels[tokenAddress].price;
        return (
            uint(priceInfo.height), 
            uint(priceInfo.tokenAmount) / uint(priceInfo.remainNum),
            uint(priceInfo.avgTokenAmount),
            uint(priceInfo.volatility_sigma_sq) // 波动率的平方
        );
    }

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function latestPrice(address tokenAddress) override public view returns (uint blockNumber, uint price) {

        PriceSheetV36[] storage sheets = channels[tokenAddress].sheets;
        uint index = sheets.length;

        // 找到已经生效的报价单索引
        while (index > 0 
            && uint(sheets[--index].height) + PRICE_EFFECT_SPAN <= block.number 
            && uint(sheets[index].remainNum) == 0
        ) { }
        
        // 根据区块内的报价单计算价格
        PriceSheetV36 memory sheet = sheets[index];
        
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
        
        if (totalEth > 0) {
            return (height, totalTokenValue / totalEth);
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
    /// @return triggeredSigma 波动率的平方
    function latestPriceAndTriggeredPriceInfo(address tokenAddress) override external view 
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigma
    ) {
        (latestPriceBlockNumber, latestPriceValue) = latestPrice(tokenAddress);
        (triggeredPriceBlockNumber, triggeredPriceValue, triggeredAvgPrice, triggeredSigma) = triggeredPriceInfo(tokenAddress);
    }

    /* ========== 治理相关 ========== */
    
    /// @dev 结算佣金
    /// @param tokenAddress 目标token地址
    function settle(address tokenAddress) external {
        
        address ntokenAddress = tokenAddress;
        PriceChannel storage channel = channels[tokenAddress];
        uint count = channel.sheets.length & 0xFF;
        NEST_DAO_CONTRACT.addReward { 
            value: POST_ETH_UNIT * POST_FEE_RATE * (count - channel.biteCount) 
        } (ntokenAddress);

        channel.biteCount = count;
    }

    /// @dev 将当前合约的资金转走
    /// @param tokenAddress 目标token地址（0表示eth）
    /// @param to 转入地址
    /// @param value 转账金额
    function transfer(address tokenAddress, address to, uint value) external {
        if (tokenAddress == address(0)) {
            address(uint160(to)).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
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

        //while(exponent-- > 0) {
        //    fraction <<= 4;
        //}
        //
        //return fraction;

        return fraction << (exponent << 2);
    }
}