// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev nest挖矿合约
interface INestMining {
    
    /// @dev 报价事件
    /// @param tokenAddress token地址
    /// @param miner 矿工地址
    /// @param index 报价单index
    /// @param ethNum 报价的eth规模
    event Post(address tokenAddress, address miner, uint index, uint ethNum, uint price);

    /* ========== 数据定义 ========== */
    
    /// @dev nest挖矿配置结构体
    struct Config {
        
        // 报价的eth单位。30
        // 可以通过将postEthUnit设置为0来停止报价和吃单（关闭和取回不受影响）
        uint32 postEthUnit;

        // 报价的手续费（万分之一eth，DIMI_ETHER）。1000
        uint16 postFee;

        // 矿工挖到nest的比例（万分制）。8000
        uint16 minerNestReward;
        
        // 矿工挖到的ntoken比例，只对3.0版本创建的ntoken有效（万分制）。9500
        uint16 minerNTokenReward;

        // 双轨报价阈值，当ntoken的发行量超过此阈值时，禁止单轨报价（单位：10000 ether）。500
        uint32 doublePostThreshold;
        
        // ntoken最多可以挖到多少区块。100
        uint16 ntokenMinedBlockLimit;

        // -- 公共配置
        // 吃单资产翻倍次数。4
        uint16 maxBiteNestedLevel;
        
        // 价格生效区块间隔。20
        uint16 priceEffectSpan;

        // 报价抵押nest数量（单位千）。100
        uint16 pledgeNest;
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

        // 每个eth等值的token数量
        uint128 price;
    }

    /* ========== 系统配置 ========== */

    /// @dev 修改配置
    /// @param config 配置对象
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置对象
    function getConfig() external view returns (Config memory);

    /* ========== 报价相关 ========== */

    /// @notice Post a price sheet for TOKEN
    /// @dev It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address tokenAddress, uint ethNum, uint tokenAmountPerEth) external payable;

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(address tokenAddress, uint ethNum, uint tokenAmountPerEth, uint ntokenAmountPerEth) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) external payable;

    /// @notice Call the function to buy ETH from a posted price sheet
    /// @dev bite ETH by TOKEN(NTOKEN),  (-ethNumBal, +tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) external payable;
    
    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param tokenAddress The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address tokenAddress, uint index) external;

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint32[] memory indices) external;

    /// @notice Close two batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress1 The address of TOKEN1 contract
    /// @param indices1 A list of indices of sheets w.r.t. `token1`
    /// @param tokenAddress2 The address of TOKEN2 contract
    /// @param indices2 A list of indices of sheets w.r.t. `token2`
    function closeList2(address tokenAddress1, uint32[] memory indices1, address tokenAddress2, uint32[] memory indices2) external;

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function stat(address tokenAddress) external;

    /// @dev 结算佣金
    /// @param tokenAddress 目标token地址
    function settle(address tokenAddress) external;

    /// @dev 分页列出报价单
    /// @param tokenAddress 目标token地址
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式。0倒序，非0正序
    /// @return 报价单列表
    function list(address tokenAddress, uint offset, uint count, uint order) external view returns (PriceSheetView[] memory);

    /// @dev 预估出矿量
    /// @param tokenAddress 目标token地址
    /// @return 预估的出矿量
    function estimate(address tokenAddress) external view returns (uint);

    /// @dev 查询目标报价单挖矿情况。
    /// @param tokenAddress token地址。ntoken不能挖矿，调用的时候请自行保证不要使用ntoken地址
    /// @param index 报价单地址
    function getMinedBlocks(address tokenAddress, uint index) external view returns (uint minedBlocks, uint count);

    /* ========== 账户相关 ========== */

    /// @dev 取出资产
    /// @param tokenAddress 目标token地址
    /// @param value 要取回的数量
    /// @return 实际取回的数量
    function withdraw(address tokenAddress, uint value) external returns (uint);

    /// @dev 查看用户的指定资产数量
    /// @param tokenAddress 目标token地址
    /// @param addr 目标地址
    /// @return 资产数量
    function balanceOf(address tokenAddress, address addr) external view returns (uint);

    /// @dev 获取给定索引号对应的地址
    /// @param index 索引号
    /// @return 给定索引号对应的地址
    function indexAddress(uint index) external view returns (address);
    
    /// @dev 获取指定地址的注册索引号
    /// @param addr 目标地址
    /// @return 0表示不存在, 非0表示索引号
    function getAccountIndex(address addr) external view returns (uint);

    /// @dev 获取注册账户数组长度
    /// @return 注册账户数组长度
    function getAccountCount() external view returns (uint);
}