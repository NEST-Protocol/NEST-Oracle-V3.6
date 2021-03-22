# NEST3.6合约说明

## 1. 背景描述
NEST3.6针对NEST3.5进行了一定的功能调整和较多的非功能性修改。

### 1.1. 功能类
1. 取消分红
2. 添加投票治理模块（详情见产品文档），3.6上线后将通过投票的方式删除系统维护账号
3. nest报价规模30eth，ntoken报价规模10eth，佣金由原来的根据规模比例计算改为固定值，nest和ntoken的佣金都设置为0.1eth
4. 验证区块拟调整为20区块
5. NN独立挖矿，出矿速度为nest全部出矿速度的15%

### 1.2. 非功能类
1. 对合约结构进行了调整，重新定义了本次和将来允许变化和需要固定的合约、将DAO分为账本和DAO应用两个部分（目前只有一个应用：回购，将来可能会有更多的DAO应用）
2. 对合约数据结构进行了调整，主要目标是为了节省gas消耗，调整后，一部分计算会有精度损失，但是精度损失控制在万亿分之一以内

## 2. 合约结构

![avatar](nest36-contracts.svg)

合约关系如上图所示，其中绿色的合约是需要实际部署的合约，其他则是接口定义或者抽象合约。有如下要点：

1. nest体系的合约都继承NestBase合约，NestBase合约主要实现了属于nest治理体系内的合约需要配合治理完成的逻辑。

2. NestGovernance是nest治理合约。包含了治理相关的功能，同时实现了nest体系内建合约地址的映射管理。

3. NestVote合约是nest系统的投票治理合约。部署时需要在NestGovernance中给其赋予管理权限。NestVote工作原理是通过在得票率达到设定阈值时给执行目标合约赋予治理权限来达到投票治理的目的。

4. NTokenController合约负责nToken的创建和管理。

5. NestMining合约是挖矿合约。其实现了INestMining（挖矿接口）和INestQuery（价格查询接口），基本逻辑是NestMining通过报价挖矿的方式实现了一种价格生成的机制。NestMining在线上会部署两个，一个是nest挖矿合约，一个是ntoken挖矿合约。

6. NestPriceFacade是NestPrice的价格查询入口。负责给DeFi提供价格调用接口，同时完成收费逻辑。NestPriceFacade中查找价格查询接口合约时，使用了两级查询机制，其首先在一个映射中查找目标token是否有单独设置INestQuery合约，如果没有找到，就使用系统内建的合约地址进行查询，从而实现nest和ntoken可以分成不同的合约报价的功能。

7. NNIncome是NestNode挖矿合约。3.6开始，NestNode挖矿和报价挖矿分离，NestNode根据区块来确定出矿量，出矿速度是nest总出矿速度的15%。

8. NestLedger是NestDAO合约的账本合约。3.6开始，DAO不再对应一个具体的合约，而是拆分成一个账本合约和多个DAO应用合约，账本合约用于接收并记录nest和ntoken的资金情况，DAO应用合约则是经过账本合约授权的合约，目前DAO应用合约只有一个回购，将来可能会上线更多的DAO应用合约。

9. NestRedeeming是回购合约。是DAO应用合约的一种实现。

## 3. 接口说明

### 3.1. INestMapping
INestMapping定义了nest体系内建合约地址的映射管理，主要包含查询合约地址、修改合约地址。

### 3.2. INestGovernance
INestGovernance定义了nest治理相关的功能，继承自INestMapping，除了INestMapping的功能接口外，还包含了检查治理权限、设置治理权限。

### 3.3. INestVote
INestVote定义了nest投票治理相关的功能，主要包含发起投票、投票、执行投票。

### 3.4. INTokenController
INTokenController定义了ntoken开通和管理相关的功能，主要包含开通ntoken、查询ntoken信息。

### 3.5. INestMining
INestMining定义了nest挖矿相关的功能，主要包含报价、吃单、查询报价单。

### 3.6. INestQuery
INestQuery定义了nest价格查询相关的功能，主要包含查询价格、查询最新价格。

### 3.7. INestPriceFacade
INestPriceFacade定义了nest价格调用相关的功能，和INestQuery一一对应，但是多了收费逻辑。

### 3.8. INestLedger
INestLedger定义了nest账本相关的功能，主要包含存入收益、支付、结算。

### 3.9. INestRedeeming
INestRedeeming定义了回购相关的功能。主要包含查看回购额度、回购。

## 4. 数据结构
3.6对数据结构进了一些调整，主要目标是为了节省gas消耗，一部分计算会有精度损失，但是损失控制在万亿分之一以内。下面列出重要的数据结构。

### 4.1. 报价单

```javascript
    ///dev 报价单信息。(占256位，一个以太坊存储单元)
    struct PriceSheet {
        
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
```

报价单数据结构将矿工地址和价格两个字段进行了处理，从而使得整个报价单占用的空间可以压缩到256位。

1. 将地址改为注册编号，每个矿工（验证者）地址会在挖矿合约内有一个唯一对应的注册账号信息，包含矿工地址，token余额等信息，同时通过一个编号来对矿工进行标示，这样将原来占用160位的地址信息映射成占用32位的整形数据，理论上大约可以注册40亿个地址，如果注册地址满了，则需要通过更新挖矿合约来解决。

2. 将原来128位的价格字段改为形如fraction * 16 ^ exponent的表示方式。由于不同的token小数位有较大差异，币价也是天差地别，固定小数位的表示方式难以满足，因此采用这种类似浮点的表示方法，理论上可以提供14位有效数字，精度损失控制在万亿分之一以内。下面是这种表示的编码和解码的代码。

```javascript
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
```

### 4.2. 价格信息

```javascript
    /// @dev 价格信息。
    struct PriceInfo {

        // 记录报价单的索引，为下一次从报价单此处继续更新价格信息做准备
        uint32 index;

        // 报价单所处区块的高度
        uint32 height;

        // 剩余的有效报价单的总规模
        uint32 remainNum;

        // 价格的浮动表示
        uint8 priceExponent;
        uint48 priceFraction;

        // 平均价格的浮动表示
        uint8 avgExponent;
        uint48 avgFraction;
        
        // 波动率的平方。需要除以2^48
        uint48 sigmaSQ;
    }
```

1. 价格信息中，将价格、平均价格改为前面提到的浮点表示法。

2. 波动率的平方改为48位整形表示，实际值需要除以2^48，实现中假定波动率不会达到1，如果出现这种极端情况，则此字段的值为0xFFFFFFFFFFFF。

## 5. 部署方式

## 6. 应用场景

