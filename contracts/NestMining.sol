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

    uint constant PRICE_EFFECT_BLOCK_COUNT = 20;
    uint constant MAX_BITE_NESTED_LEVEL = 4;

    /// @dev Average block mining interval, ~ 14s
    uint constant ETHEREUM_BLOCK_TIMESPAN = 14;

    address immutable NEST_TOKEN_ADDRESS; // = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

    /// @dev 报价单信息。(占256位，一个以太坊存储单元)
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

    /// @dev 报价单视图
    struct PriceSheetView {
        
        // 索引号
        uint32 index;

        // 矿工地址
        address miner;

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

        // 每个eth等职的token数量
        uint128 price;
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

        // // 挖矿信息
        // MiningShare[] shares;

        // 价格信息
        PriceInfoV36 price;
    }

    mapping(address=>PriceChannel) channels;

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

    /// @dev 账号信息
    Account[] accounts;

    /// @dev 账号地址映射
    mapping(address=>uint32) accountMapping;

    /// @dev DAO合约地址
    INestDAO C_NestDAO;

    constructor(address nest, address NestDAO) public {
        
        // 占位，实际的注册账号的索引必须大于0
        accounts.push(Account(address(0x0)));

        NEST_TOKEN_ADDRESS = nest;
        C_NestDAO = INestDAO(NestDAO);
    }

    /* ========== 报价挖矿 ========== */
    /// @notice Post a price sheet for TOKEN
    /// @dev  It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param token The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address token, uint ethNum, uint tokenAmountPerEth) override external payable {
        
        // TODO: nToken映射问题

        // 1. 检查
        require(ethNum > 0 && ethNum % POST_ETH_UNIT == 0, "NestMining:ethNum invalid");
        require(tokenAmountPerEth > 0, "NestMining:price invalid");

        // TODO: 检查是否允许单轨报价

        // 2. 转账
        // 2.1 手续费
        uint fee = ethNum * POST_FEE_RATE;
        require(msg.value == fee + ethNum * 1 ether, "NestMining:eth value error");

        // TODO: 改为批量触发分红
        // TODO: NestDAO和nTokenDAO分成
        address ntoken = NEST_TOKEN_ADDRESS;

        C_NestDAO.addETHReward { value: fee } (ntoken);
        // 80%进入nToken的分红池
        C_NestDAO.addETHReward { value: fee * 80 / 100 } (ntoken);
        // 20%进入nest的分红池
        C_NestDAO.addETHReward { value: fee * 20 / 100 } (NEST_TOKEN_ADDRESS);

        // 2.2 
        // 冻结token，nest
        // 由于使用浮点表示法(uint48 fraction, uint8 exponent)会带来一定的精度损失
        // 按照tokenAmountPerEth * ethNum冻结资产后，退回的时候可能损失精度差部分
        // 实际应该按照decodeFloat(fraction, exponent) * ethNum来冻结
        // 但是考虑到损失在1/10^14以内，因此忽略此处的损失，精度损失的部分，将来可以作为系统收益转出
        freeze2(token, tokenAmountPerEth * ethNum, POST_PLEDGE_UNIT);

        // 3. 生成报价单
        //PriceChannel storage channel = channels[token];
        //uint index = channel.index;

        // 3.1 检查当前位置是否有未关闭的报价单
        //PriceSheetV36 memory sheet = channel.sheets[index];
        
        // // 当前位置有报价单，先给其结算
        // if (sheet.miner > 0) {
            
        //     // 报价单数组中还存在未超过验证区块的价格，不允许新报价
        //     require(sheet.height + PRICE_EFFECT_SPAN > block.number, "NestMining:out of capacity");

        //     // 关闭即将覆盖的报价单
        //     address payable miner = address(uint160(indexAddress(sheet.miner)));
            
        //     // 转回其eth
        //     if (sheet.ethNumBal > 0) {
        //         miner.transfer(sheet.ethNumBal * 1 ether);
        //     }

        //     // 转回其token
        //     if (sheet.tokenNumBal > 0) {
        //         TransferHelper.safeTransfer(token, miner, decodeFloat(sheet.priceFraction, sheet.priceExponent) * sheet.tokenNumBal);
        //     }

        //     // TODO: 出矿

        //     // 清空报价单
        //     //channel.sheets[index] = PriceSheetV36(0,0,0,0,0,0,0,0,0);
        // } 

        // 计算出矿

        // 生成报价单并保存
        (uint48 fraction, uint8 exponent) = encodeFloat(tokenAmountPerEth);
        channels[token].sheets.push(PriceSheetV36(
            addressIndex(msg.sender),   // uint32 miner;
            uint32(block.number),       // uint32 height;
            uint32(ethNum),             // uint32 remainNum;
            uint32(ethNum),             // uint32 ethNumBal;
            uint32(ethNum),             // uint32 tokenNumBal;
            uint32(POST_NEST_1K_ONE),   // uint32 nestNum1k;
            uint8(0),                   // uint8 level;
            exponent,                   // uint8 priceExponent;
            fraction                    // uint48 priceFraction;
        ));
        
        // if (index < MAX_SHEET_INDEX) {
        //     ++index;
        // } else {
        //     index = 0;
        // }

        // channel.index = index;

        // 4. 计算
        stat(token);
    }

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev  Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param token The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(
        address token, 
        uint256 ethNum, 
        uint256 tokenAmountPerEth, 
        uint256 ntokenAmountPerEth
    ) override external payable {

        // TODO: nToken映射问题
        address ntoken = NEST_TOKEN_ADDRESS;

        // 1. 检查
        require(ethNum > 0 && ethNum % POST_ETH_UNIT == 0, "NestMining:ethNum invalid");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "NestMining:price invalid");
        
        // 2. 手续费
        uint fee = ethNum * POST_FEE_RATE;
        require(msg.value == fee + ethNum * 2 ether, "NestMining:eth value error");
        // TODO: 改为批量触发分红
        // TODO: NestDAO和nTokenDAO分成
        // 80%进入nToken的分红池
        C_NestDAO.addETHReward { value: fee * 80 / 100 } (ntoken);
        // 20%进入nest的分红池
        C_NestDAO.addETHReward { value: fee * 20 / 100 } (NEST_TOKEN_ADDRESS);

        // 3. 冻结资产
        mapping(address=>UINT) storage balances = accounts[addressIndex(msg.sender)].balances;
        freeze(token, balances[token], ethNum * tokenAmountPerEth);
        if (ntoken == NEST_TOKEN_ADDRESS) {
            freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], ethNum * ntokenAmountPerEth + (POST_PLEDGE_UNIT << 1));
        } else {
            freeze(ntoken, balances[ntoken], ethNum * ntokenAmountPerEth);
            freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], POST_PLEDGE_UNIT << 1);
        }

        // 4. 创建报价单
        (uint48 fraction, uint8 exponent) = encodeFloat(tokenAmountPerEth);
        channels[token].sheets.push(PriceSheetV36(
            addressIndex(msg.sender),   // uint32 miner;
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
        channels[ntoken].sheets.push(PriceSheetV36(
            addressIndex(msg.sender),   // uint32 miner;
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
        stat(token);
        stat(ntoken);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address token, uint256 index, uint256 biteNum, uint256 newTokenAmountPerEth) override external payable {

        // 1.检查
        require(biteNum > 0 && biteNum % POST_ETH_UNIT == 0, "NestMining:biteNum invalid");
        require(newTokenAmountPerEth > 0, "NestMining:price invalid");

        // 2.加载报价单
        PriceSheetV36[] storage sheets = channels[token].sheets;
        PriceSheetV36 memory sheet = sheets[index];

        // 3.检查报价单状态
        require(uint(sheet.remainNum) >= biteNum, "NestMining:remainNum not enough");
        require(uint(sheet.height) + PRICE_EFFECT_BLOCK_COUNT >= block.number, "NestMining:price effected");

        // 4.结算资金
        // 抵押的nest翻倍
        // 前面4次报价规模需要翻倍
        
        // 4. 计算需要的eth, token, nest数量
        uint needNest1k;
        uint needEthValue;
        uint needTokenValue;

        // 当吃单深度小于4的时候, nest和报价规模都翻倍
        if (uint(sheet.level) < MAX_BITE_NESTED_LEVEL) {
            // 翻倍报价 + 用于买入token的数量，一共三倍
            needEthValue = biteNum * 3 ether;
            // 翻倍报价
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
        } 
        // 当吃单深度达到4或以上时, nest翻倍, 规模不翻倍
        else {
            // 单倍报价 + 用于买入token的数量，一共两倍
            needEthValue = biteNum * 2 ether;
            // 但倍报价
            needTokenValue = newTokenAmountPerEth * biteNum;
        }

        // 转入的eth数量必须正确
        require(msg.value == needEthValue, "NestMining:eth value error");

        // 需要抵押的nest数量
        needNest1k = (biteNum / POST_ETH_UNIT) * 100;

        // 冻结nest
        mapping(address=>UINT) storage balances = accounts[addressIndex(msg.sender)].balances;
        if (token == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1 ether;
        } else {
            freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], needNest1k * 1 ether);        
        }

        // 冻结token
        uint backTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum;
        if (needTokenValue > backTokenValue) {
            freeze(token, balances[token], needTokenValue - backTokenValue);
        } else {
            unfreeze(balances[token], backTokenValue - needTokenValue);
        }

        // 用于吃单的eth转给被吃单者
        address payable miner = address(uint160(indexAddress(sheet.miner)));
        miner.transfer(biteNum * 1 ether);

        // 5.更新被吃的报价单
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal + biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal - biteNum);
        sheets[index] = sheet;

        // 6.生成吃单报价单
        (uint48 fraction, uint8 exponent) = encodeFloat(newTokenAmountPerEth);
        sheets.push(PriceSheetV36(
            addressIndex(msg.sender),   // uint32 miner;
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
        stat(token);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address token, uint256 index, uint256 biteNum, uint256 newTokenAmountPerEth) override external payable {

        // 1.检查
        require(biteNum > 0 && biteNum % POST_ETH_UNIT == 0, "NestMining:biteNum invalid");
        require(newTokenAmountPerEth > 0, "NestMining:price invalid");

        // 2.加载报价单
        PriceSheetV36[] storage sheets = channels[token].sheets;
        PriceSheetV36 memory sheet = sheets[index];

        // 3.检查报价单状态
        require(uint(sheet.remainNum) >= biteNum, "NestMining:remainNum not enough");
        require(uint(sheet.height) + PRICE_EFFECT_BLOCK_COUNT >= block.number, "NestMining:price effected");

        // 4. 计算需要的eth, token, nest数量
        uint needNest1k;
        uint needEthValue;
        uint needTokenValue;

        // 当吃单深度小于4的时候, nest和报价规模都翻倍
        if (uint(sheet.level) < MAX_BITE_NESTED_LEVEL) {
            // 翻倍报价 - 卖出token换得的数量，一共一倍
            needEthValue = biteNum * 1 ether;
            // 翻倍报价
            needTokenValue = newTokenAmountPerEth * (biteNum << 1);
        } 
        // 当吃单深度达到4或以上时, nest翻倍, 规模不翻倍
        else {
            // 单倍报价 - 用于买入token的数量，一共0倍
            needEthValue = 0 ether;
            // 但倍报价
            needTokenValue = newTokenAmountPerEth * biteNum;
        }
        
        // 转入的eth数量必须正确
        require(msg.value == needEthValue, "NestMining:eth value error");

        // 需要抵押的nest数量
        needNest1k = (biteNum / POST_ETH_UNIT) * 100;

        // 5.结算
        // 冻结nest
        mapping(address=>UINT) storage balances = accounts[addressIndex(msg.sender)].balances;
        if (token == NEST_TOKEN_ADDRESS) {
            needTokenValue += needNest1k * 1 ether;
        } else {
            freeze(NEST_TOKEN_ADDRESS, balances[NEST_TOKEN_ADDRESS], needNest1k * 1 ether);        
        }

        // 冻结token
        uint backTokenValue = decodeFloat(sheet.priceFraction, sheet.priceExponent) * biteNum;
        freeze(token, balances[token], needTokenValue + backTokenValue);

        // 6.更新被吃的报价单信息
        sheet.remainNum = uint32(sheet.remainNum - biteNum);
        sheet.ethNumBal = uint32(sheet.ethNumBal - biteNum);
        sheet.tokenNumBal = uint32(sheet.tokenNumBal + biteNum);
        sheets[index] = sheet;

        // 7.生成吃单报价
        (uint48 fraction, uint8 exponent) = encodeFloat(newTokenAmountPerEth);
        sheets.push(PriceSheetV36(
            addressIndex(msg.sender),   // uint32 miner;
            uint32(block.number),       // uint32 height;
            uint32(biteNum << 1),       // uint32 remainNum;
            uint32(biteNum << 1),       // uint32 ethNumBal;
            uint32(biteNum << 1),       // uint32 tokenNumBal;
            uint32(needNest1k),         // uint32 nestNum1k;
            uint8(sheet.level + 1),     // uint8 level;
            exponent,                   // uint8 priceExponent;
            fraction                    // uint48 priceFraction;
        ));

        stat(token);
    }

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address token, uint index) public {
        
        // TODO: 考虑同时支持token和ntoken的关闭

        PriceSheetV36[] storage sheets = channels[token].sheets;
        PriceSheetV36 memory sheet = sheets[index];

        if (sheet.miner > 0) {
            
            // 关闭即将覆盖的报价单
            address payable miner = address(uint160(indexAddress(sheet.miner)));
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

            // 转回其token
            unfreeze2(
                token, 
                decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.tokenNumBal), 
                uint(sheet.nestNum1k) * 1000 ether + minedBlocks * 400 ether / count
            );

            // 转回其eth
            if (uint(sheet.ethNumBal) > 0) {
                miner.transfer(uint(sheet.ethNumBal) * 1 ether);
            }

            sheet.ethNumBal = 0;
            sheet.tokenNumBal = 0;

            sheets[index] = sheet;
        }

        stat(token);
    }

    function _stat(PriceChannel storage channel) private {
        // TODO: 优化计算逻辑

        // 找到token的价格信息
        PriceInfoV36 memory p0 = channel.price;
        
        // 找到token的报价单数组
        PriceSheetV36[] storage sheets = channel.sheets;

        uint height;
        uint length = sheets.length;
        uint index = uint(p0.index);
        uint prev = uint(p0.height);
        uint totalEth = uint(p0.remainNum);
        uint totalTokenValue = uint(p0.tokenAmount);
        uint price;

        // 遍历报价单，找到生效价格
        PriceSheetV36 memory sheet;
        while (index < length && (height = uint((sheet = sheets[index]).height)) + PRICE_EFFECT_BLOCK_COUNT < block.number) {

            // 同一区块, 累计价格
            if (prev == height) {
                totalEth += uint(sheet.remainNum);
                totalTokenValue += decodeFloat(sheet.priceFraction, sheet.priceExponent) * uint(sheet.remainNum);
            } else {

                // 计算价格
                price = totalTokenValue / totalEth;

                // 计算平均价格
                // 计算波动率
                if (index == 0) {
                    p0.avgTokenAmount = uint64(price);
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
                }
                prev = height;
            }
        }

        if (uint(p0.height) < prev) {
            p0.height = uint32(prev);
            channel.price = p0;
        }
    }

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function stat(address token) public 
    {
        // TODO: 优化计算逻辑

        PriceChannel storage channel = channels[token];

        // 找到token的价格信息
        PriceInfoV36 memory p0 = channel.price;
        
        // 找到token的报价单数组
        PriceSheetV36[] storage pL = channel.sheets;

        // 报价单长度小于2不计算
        if (pL.length < 2) {
            return;
        }

        // 还没有形成过报价
        if (p0.height == 0) {

            // 取第一个报价单
            PriceSheetV36 memory _sheet = pL[0];

            // 根据第一个报价单生成价格信息

            // 报价规模
            p0.remainNum = _sheet.remainNum;
            // token数量

            // TODO: 原算法如下，请确定是否可以这样代替 
            // p0.tokenAmount = uint128(uint(_sheet.tokenAmountPerEth).mul(_sheet.ethNum));
            uint price = decodeFloat(_sheet.priceFraction, _sheet.priceExponent);
            p0.tokenAmount = uint64(price.mul(_sheet.remainNum));
            // 价格所在区块号
            p0.height = _sheet.height;
            // K为0
            p0.volatility_sigma_sq = 0;
            // 波动率为0
            p0.volatility_ut_sq = 0;
            // 平均价格
            p0.avgTokenAmount = uint64(price);

            // 将价格写入到token状态结构中
            // write back
            channel.price = p0;
        }

        PriceInfoV36 memory p1;

        // record the gas usage
        //uint startGas = gasleft();
        //uint gasUsed;

        // TODO: 多次读取state.priceDurationBlock, 考虑先读取到内存中
        // p0是循环变量
        // p0.index表示遍历到的索引编号
        // 从上次遍历到的地方开始遍历报价单，并且报价单已经达到生效区块
        while (uint(p0.index) < pL.length && uint(p0.height) + 0 < block.number){

            // TODO: 改为在外部计算
           // gasUsed = startGas - gasleft();

            // NOTE: check gas usage to prevent DOS attacks
            // if (gasUsed > 1_000_000) {
            //     break; 
            // }

            // 计算价格
            p1 = _moveAndCalc(p0, pL, 0);

            // 没有新的价格信息
            if (p1.index <= p0.index) {    // bootstraping
                break;
            } 
            // 报价单已经被吃完，跳过
            else if (p1.remainNum == 0) {   // jump cross a block with bitten prices
                p0.index = p1.index;
                continue;
            }
            // 进入下一个
            else {                       // calculate one more block
                p0 = p1;
            }
        }

        // TODO: 存在价格必须被触发的问题，也就是价格必须超过25区块才能生效！
        // 有新的价格生成，更新token的价格
        if (p0.index > channel.price.index) {
            channel.price = p0;
        }

        return;
    }

    // 计算新价格
    function _moveAndCalc(
            PriceInfoV36 memory p0,
            PriceSheetV36[] storage pL,
            uint priceDurationBlock
        )
        private
        view
        returns (PriceInfoV36 memory)
    {
        //uint pLlength = pL.length;

        // 找下一个报价单的索引
        uint i = p0.index + 1;
        // 超出报价单数组长度，返回0值
        // TODO：直接在外部判断，减少损耗
        if (i >= pL.length) {
            //return (MiningV1Data.PriceInfo(0,0,0,0,0,int128(0),int128(0), uint128(0), 0));
            return PriceInfoV36(0,0,0,0,0,0,0);
        }

        PriceSheetV36 memory sheet = pL[i];

        // 下一个价格所在的区块高度
        uint h = uint(sheet.height);
        // 如果报价单还没有生效，就返回0值
        // TODO: 直接在外部判断，减少损耗
        if (h + priceDurationBlock >= block.number) {
            //return (MiningV1Data.PriceInfo(0,0,0,0,0,int128(0),int128(0), uint128(0), 0));
            return PriceInfoV36(0,0,0,0,0,0,0);
        }

        uint ethA1 = 0;
        uint tokenA1 = 0;

        // 遍历当前区块内的报价单
        while (i < pL.length && sheet.height == h) {
            // 跳过剩余规模为0的报价单
            uint _remain = uint(sheet.remainNum);
            if (_remain == 0) {
                i = i + 1;
                continue;
            }
            // 累计eth数量
            ethA1 = ethA1 + _remain;
            // 累计token数量
            tokenA1 = tokenA1 + _remain.mul(decodeFloat(sheet.priceFraction, sheet.priceExponent));
            i = i + 1;
        }
        i = i - 1;

        // 累计eth数量或者累计token数量为0，没有价格
        if (ethA1 == 0 || tokenA1 == 0) {
            // return (MiningV1Data.PriceInfo(
            //         uint32(i),  // index TODO: 没有价格，index直接赋值0?
            //         uint32(0),  // height
            //         uint32(0),  // ethNum
            //         uint32(0),  // _reserved
            //         uint32(0),  // tokenAmount
            //         int128(0),  // volatility_sigma_sq
            //         int128(0),  // volatility_ut_sq
            //         uint128(0),  // avgTokenAmount
            //         0           // _reserved2
            // ));
            return PriceInfoV36(0,0,0,0,0,0,0);
        }

        // TODO：波动率对套利者来说，是否是无效的?
        // 计算波动率
        int128 new_sigma_sq;
        int128 new_ut_sq;
        {
            if (uint(p0.remainNum) != 0) {
                // 计算波动率
                (new_sigma_sq, new_ut_sq) = _calcVola(

                    // 上一个价格
                    uint(p0.tokenAmount).div(uint(p0.remainNum)), 

                    // 当前的新价格
                    uint(tokenA1).div(uint(ethA1)),

                    // 上一个波动率
                    p0.volatility_sigma_sq, 
                
                    p0.volatility_ut_sq,

                    // 与上一个最新价格之间的区块间隔
                    h - p0.height);
            }
        }

        // 计算平均价格
        //uint _newAvg = _calcAvg(ethA1, tokenA1, p0.avgTokenAmount); 

        // 返回新价格
        return(PriceInfoV36(
                uint32(i),          // index
                uint32(h),          // height
                uint32(ethA1),      // ethNum
                //uint32(0),          // _reserved
                uint64(tokenA1),   // tokenAmount
                uint32(new_sigma_sq),       // volatility_sigma_sq
                uint32(new_ut_sq),          // volatility_ut_sq
                uint64(_calcAvg(ethA1, tokenA1, p0.avgTokenAmount))   // avgTokenAmount
                //uint128(0)          // _reserved2
        ));
    }

    /// @dev 计算波动率
    /// @param tokenA0 是上一个价格? 
    /// @param tokenA1 是当前的新价格? 
    /// @param _sigma_sq 前一个波动率?
    /// @param _ut_sq ?
    /// @param _interval 与上一个最新价格之间的区块间隔
    /// @return 新计算出来的波动率
    /// @return ?
    function _calcVola(
            // uint ethA0, 
            uint tokenA0, 
            // uint ethA1, 
            uint tokenA1, 
            int128 _sigma_sq, 
            int128 _ut_sq,
            uint _interval
        )
        private
        pure
        // pure 
        returns (int128, int128)
    {
        // _ut_sq_2 = _ut_sq / (_interval * ETHEREUM_BLOCK_TIMESPAN);
        int128 _ut_sq_2 = ABDKMath64x64.div(_ut_sq, 
            ABDKMath64x64.fromUInt(_interval.mul(ETHEREUM_BLOCK_TIMESPAN)));

        // _new_sigma_sq = _sigma_sq * 0.95 + _ut_sq_2 * 0.5;
        int128 _new_sigma_sq = ABDKMath64x64.add(
            ABDKMath64x64.mul(ABDKMath64x64.divu(95, 100), _sigma_sq),
            ABDKMath64x64.mul(ABDKMath64x64.divu(5,100), _ut_sq_2));

        // _new_ut_sq = (tokenA1 / tokenA0 - 1) ^ 2;
        int128 _new_ut_sq;

        // TODO: 搞清楚波动率增量计算公式
        _new_ut_sq = ABDKMath64x64.pow(ABDKMath64x64.sub(
                    ABDKMath64x64.divu(tokenA1, tokenA0), 
                    ABDKMath64x64.fromUInt(1)), 
                2);
        
        return (_new_sigma_sq, _new_ut_sq);
    }

    /// @dev 计算平均价格
    /// @param ethA 用于表示价格的eth数量
    /// @param tokenA 用于表示价格的token数量
    /// @param _avg 上一个平均价格
    /// @return 平均价格?
    function _calcAvg(uint ethA, uint tokenA, uint _avg)
        private 
        pure
        returns(uint)
    {
        uint _newP = tokenA.div(ethA);
        uint _newAvg;

        // 上一个平均价格为0，直接返回新的价格作为平均价格
        if (_avg == 0) {
            _newAvg = _newP;
        } 
        //         
        else {
            // _newAvg = _avg * 0.95 + _newP * 0.5;
            _newAvg = (_avg.mul(95).div(100)).add(_newP.mul(5).div(100));
            // _newAvg = ABDKMath64x64.add(
            //     ABDKMath64x64.mul(ABDKMath64x64.divu(95, 100), _avg),
            //     ABDKMath64x64.mul(ABDKMath64x64.divu(5,100), _newP));
        }

        return _newAvg;
    }

    // PriceSheetV36 [1000] testsheets;
    // function test(uint n) public {
    //     for (uint i = 0; i < n; ++i) {
    //         //testsheets[i] = (PriceSheetV36(1,1,1,1,1,1,1,1,1));
    //         testsheets[i] = (PriceSheetV36(0,0,1,0,0,0,0,0,0, 1));
    //     }
    // }

    // function test(uint n) public {

    //     if (n > 0) {
    //         n++;
    //     }

    //     n = uint(int(n + 1));

    //     address addr = address(0x01);
    //     addr = address(uint160(addr));
    // }

    function list(address tokenAddress, uint offset, uint count, uint order) public view returns (PriceSheetView[] memory) {
        
        PriceSheetV36[] storage sheets = channels[tokenAddress].sheets;
        PriceSheetView[] memory result = new PriceSheetView[](count);

        if (order == 0) {

            uint index = sheets.length - offset;
            uint end = index - count;
            uint i = 0;
            while (index > end) {
                PriceSheetV36 memory sheet = sheets[--index];
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

                //// 每个eth等职的token数量
                //uint128 price;

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

        return result;
    }

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

    function withdraw(address tokenAddress, uint value) public returns (uint) {

        Account storage account = accounts[accountMapping[msg.sender]];
        uint balance = account.balances[tokenAddress].value;
        require(balance >= value, "NestMining:balance not enough");
        account.balances[tokenAddress].value -= value;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);

        return value;
    }

    function balanceOf(address tokenAddress, address addr) public view returns (uint) {
        return accounts[accountMapping[addr]].balances[tokenAddress].value;
    }

    function addressIndex(address addr) private returns (uint32) {

        uint32 index = accountMapping[addr];
        if (uint(index) == 0) {
            uint length = accounts.length;

            // 超过32位所能存储的最大数字，无法再继续注册新的账户，如果需要支持新的账户，需要更新合约
            require(length < 0x100000000, "NestMining:too much accounts");
            accountMapping[addr] = index = uint32(length);
            accounts.push(Account(addr));
        }

        return index;
    }

    function indexAddress(uint32 index) public view returns (address) {
        return accounts[index].addr;
    }

    function encodeFloat(uint value) public pure returns (uint48 fraction, uint8 exponent) {
        
        uint decimals = 0; 
        while (value > 0xFFFFFFFFFFFF /* 281474976710655 */) {
            value >>= 4;
            ++decimals;
        }

        return (uint48(value), uint8(decimals));
    }

    function decodeFloat(uint fraction, uint exponent) public pure returns (uint) {

        //while(exponent-- > 0) {
        //    fraction <<= 4;
        //}
        //
        //return fraction;

        return fraction << (exponent << 2);
    }
}