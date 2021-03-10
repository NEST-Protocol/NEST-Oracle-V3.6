# NEST的挖矿合约

## 1. 合约说明
    NEST的挖矿合约。

## 2. 接口说明

报价相关

### 2.1. 单轨报价
    
    /// @notice Post a price sheet for TOKEN
    /// @dev It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param tokenAdderss The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address tokenAdderss, uint ethNum, uint tokenAmountPerEth) external payable;

### 2.2. 双轨报价

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAdderss The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(address tokenAdderss, uint ethNum, uint tokenAmountPerEth, uint ntokenAmountPerEth) external payable;

### 2.3. 吃单，买入token

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAdderss The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address tokenAdderss, uint index, uint biteNum, uint newTokenAmountPerEth) external payable;

### 2.4. 吃单，买入eth

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAdderss The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address tokenAdderss, uint index, uint biteNum, uint newTokenAmountPerEth) external payable;

### 2.5. 关闭报价单

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param tokenAdderss The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address tokenAdderss, uint index) external;

### 2.6. 批量关闭报价单

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint32[] memory indices) external; 

### 2.7. 触发计算价格

    /// @dev 触发计算价格
    /// @param tokenAdderss 目标token地址
    function stat(address tokenAdderss) external;

### 2.8. 分页列出报价单

    /// @dev 分页列出报价单
    /// @param tokenAddress 目标token地址
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式. 0倒序, 非0正序
    function list(address tokenAddress, uint offset, uint count, uint order) external view returns (PriceSheetView[] memory);

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
    
### 2.9. 预估出矿量

    /// @dev 预估出矿量
    /// @param tokenAddress 目标token地址
    /// @return 预估的出矿量
    function estimate(address tokenAddress) external view returns (uint);

账户相关

### 2.10. 取出资产

    /// @dev 取出资产
    /// @param tokenAddress 目标token地址
    /// @param value 要取回的数量
    /// @return 实际取回的数量
    function withdraw(address tokenAddress, uint value) external returns (uint);

### 2.11. 查看用户的指定资产数量

    /// @dev 查看用户的指定资产数量
    /// @param tokenAddress 目标token地址
    /// @param addr 目标地址
    /// @return 资产数量
    function balanceOf(address tokenAddress, address addr) external view returns (uint);

### 2.12. 获取给定索引号对应的地址

    /// @dev 获取给定索引号对应的地址
    /// @param index 索引号
    /// @return 给定索引号对应的地址
    function indexAddress(uint index) external view returns (address);

### 2.13. 获取指定地址的注册索引号

    /// @dev 获取指定地址的注册索引号
    /// @param addr 目标地址
    /// @return 0表示不存在, 非0表示索引号
    function getAccountIndex(address addr) external view returns (uint);

### 2.14. 获取注册账户数组长度

    /// @dev 获取注册账户数组长度
    /// @return 注册账户数组长度
    function getAccountCount() external view returns (uint);