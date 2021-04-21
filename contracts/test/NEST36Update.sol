// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.3;

// // 升级合约
// contract NEST36Update {
    
//     // usdt地址
//     address constant USDT_TOKEN_ADDRESS = address(0x9B70F432b8eE4e2B2BdDFb200AA9486c04081d12);
//     // nest地址
//     address constant NEST_TOKEN_ADDRESS = address(0xdE6A3E1153E9465d8E8011C5F846C567E1E05c41);
//     // NN地址
//     address constant NEST_NODE_ADDRESS = address(0x52Ab1592d71E20167EB657646e86ae5FC04e9E01);
    
//     //---3.0合约地址
//     // 3.0NToken_TokenMapping
//     // INest_NToken_TokenMapping
//     address constant NTOKEN_MAPPING30_ADDRESS = (address(0x0));
//     //---3.5地址
//     // 矿池 INestPool
//     address constant NEST_POOL_ADDRESS = address(0xB7a8CFCC45933B50E79E1aA8c9ED725F1EA7351D);
//     // DAO
//     // INestDAO
//     address constant NEST_DAO_ADDRESS = address(0xD517645668Ff57E748411D1B9C82d63Ca3fd70D2);
//     // nest挖矿合约
//     // INestMining35
//     address constant NEST_MINING35_ADDRESS = address(0xa14811eA3f754709F628DfDa728e56ccB99F1dC1);
    
//     //---3.6合约地址
//     // nest挖矿合约 
//     address constant NEST_MINING_ADDRESS = address(0xE63cBCbd6163f4872529D60961396758ffcFBF7c);
//     // NN挖矿合约
//     address constant NN_INCOME_ADDRESS = address(0x6Fc46387CD1041d32C49976a76c2b624feE282eC);
//     // DAO账本
//     address constant NEST_LEDGER_ADDRESS = address(0x8D765fA9C16e6f5AdfcFAeC3F5e52a085Fa17f70);
//     // 管理合约
//     address constant NEST_GOVERNANCE_ADDRESS = address(0xA2D58989ef9981065f749C217984DB21970fF0b7);
//     // nTokenController
//     // INTokenController
//     address constant NTOKEN_CONTROLLER_ADDRESS = address(0x51C7a4CDe357aeC596337161Bf40a682BEf61D82);
//     // NestRedeeming
//     address constant NEST_REDEEMING_ADDRESS = address(0x0);
    
//     // token数量
//     uint constant TOKEN_COUNT = 57;

//     function _tokenList() private pure returns (address[TOKEN_COUNT] memory) {
//         // token列表
//         return [
//             0x9B70F432b8eE4e2B2BdDFb200AA9486c04081d12,
//             0x0000000000000000000000000000000000000001,
//             0x0000000000000000000000000000000000000002,
//             0x0000000000000000000000000000000000000003,
//             0x0000000000000000000000000000000000000004,
//             0x0000000000000000000000000000000000000005,
//             0x0000000000000000000000000000000000000006,
//             0x0000000000000000000000000000000000000007,
//             0x0000000000000000000000000000000000000008,
//             0x0000000000000000000000000000000000000009,
//             0x0000000000000000000000000000000000000010,
//             0x0000000000000000000000000000000000000011,
//             0x0000000000000000000000000000000000000012,
//             0x0000000000000000000000000000000000000013,
//             0x0000000000000000000000000000000000000014,
//             0x0000000000000000000000000000000000000015,
//             0x0000000000000000000000000000000000000016,
//             0x0000000000000000000000000000000000000017,
//             0x0000000000000000000000000000000000000018,
//             0x0000000000000000000000000000000000000019,
//             0x0000000000000000000000000000000000000020,
//             0x0000000000000000000000000000000000000021,
//             0x0000000000000000000000000000000000000022,
//             0x0000000000000000000000000000000000000023,
//             0x0000000000000000000000000000000000000024,
//             0x0000000000000000000000000000000000000025,
//             0x0000000000000000000000000000000000000026,
//             0x0000000000000000000000000000000000000027,
//             0x0000000000000000000000000000000000000028,
//             0x0000000000000000000000000000000000000029,
//             0x0000000000000000000000000000000000000030,
//             0x0000000000000000000000000000000000000031,
//             0x0000000000000000000000000000000000000032,
//             0x0000000000000000000000000000000000000033,
//             0x0000000000000000000000000000000000000034,
//             0x0000000000000000000000000000000000000035,
//             0x0000000000000000000000000000000000000036,
//             0x0000000000000000000000000000000000000037,
//             0x0000000000000000000000000000000000000038,
//             0x0000000000000000000000000000000000000039,
//             0x0000000000000000000000000000000000000040,
//             0x0000000000000000000000000000000000000041,
//             0x0000000000000000000000000000000000000042,
//             0x0000000000000000000000000000000000000043,
//             0x0000000000000000000000000000000000000044,
//             0x0000000000000000000000000000000000000045,
//             0x0000000000000000000000000000000000000046,
//             0x0000000000000000000000000000000000000047,
//             0x0000000000000000000000000000000000000048,
//             0x0000000000000000000000000000000000000049,
//             0x0000000000000000000000000000000000000050,
//             0x0000000000000000000000000000000000000051,
//             0x0000000000000000000000000000000000000052,
//             0x0000000000000000000000000000000000000053,
//             0x0000000000000000000000000000000000000054,
//             0x0000000000000000000000000000000000000055,
//             0x0000000000000000000000000000000000000056
//         ];
//     }

//     function _ntokenList() private pure returns (address[TOKEN_COUNT] memory) {
//         // ntoken列表
//         return [
//             0xdE6A3E1153E9465d8E8011C5F846C567E1E05c41,
//             0xdB61D250372fb1c4BD49CE34C0caCaBeFe575592,
//             0x881b4d6939398dEE52D5CeF1942E568a01B91C93,
//             0xDAC0BD713ED8DE73aA0893Cc7dDf0BDC28457A63,
//             0xD7c8Ef96193de54D86967706559661731Fc84F08,
//             0x2392F63C005e1920B271BDAd655253eA3e0e239c,
//             0xd754fa0F7E127c58a0e40a283A9E929Fa1061358,
//             0x93Dc09be1e615aA65AFD6c2d911B661e311dB4B0,
//             0xCB3b9DeF13f4F904683f53c3EE4cE34F57c34bb6,
//             0x2dC52e1FcD06a43285c5D7f5E833131b1c411852,
//             0xd5798C4DbC5AC13DbE4809d2914b5fd5e5030948,
//             0x30C69c1511608aBCf5f7052CE330A47673BEF80a,
//             0x9AeE80A1df3cA0c5B859d94bCCf16d0440f1691d,
//             0x615c7448ED870aD41a24FE7e96016b2d9406C169,
//             0x7D3d375759Dce4D8609EcA61fCe5898e5Dd52E09,
//             0x537A8955B0E0466A487F8a417717551ac05bB580,
//             0x14A2341049fbdF36D35D7bd51afe7eFf2317Afa4,
//             0xA1e38e9DECB554b6AaC4b9B58f74Af1eb33CE291,
//             0x69E6CAae16Acf21134D839835C5f8bC9F2522680,
//             0x6a7325AAe473FDE1D4F84D20B51Ac2a1DD75c154,
//             0x32F58c1e1d93918760D3C67436971A0E17C67789,
//             0xd19eE5B17d886BEe1988f42eCC68104Be7b9074E,
//             0x936C00B8C63DB4CEc84672c20BD6e2a7A5054B61,
//             0xAd3c3a672722b8dA106e3C1133D88AAb7E138017,
//             0x93dB3EDEFFb26a6010EE430935c0c527DCAB2351,
//             0xf4DE45Da031dC45EFd94EE5983f00B4C2549beE8,
//             0xFb68577ce84d6529Ed912a2C187bE9AEA66C8F94,
//             0x9206436598178209Ec7b6A6ba6546C33FDA91A6d,
//             0x31fee0E55ef7Fc88369F56Cd5C3f9110a568c0fe,
//             0x47C62AD93bf0125D59EfE5Cf1E692D92165769f5,
//             0x9228A336bb91bFf6A1Ff54Ded0DE514D22dAED52,
//             0x6306963714c63DF4729b339586b567f4DB5dC7Ef,
//             0x7d975Da761e6bC6BD4579dE4CF9ec3745E512777,
//             0x8eB08d9a872928CFF2BDCE89c6f9395f45dEE701,
//             0xE54c459DA0C3040b825647Ad2897F37702A80d5A,
//             0x0F1cb2bB372edd39624bf1763FE4830DAFcf9139,
//             0x6166C2c92008473aF80B37068584205073008e79,
//             0x70f72a141083ab8CCef920eA6EF2fbA88161FAD2,
//             0x99C97274339073fdb3EFfF52976FD27A639E410F,
//             0x20CbEA172E200c6c6D6B1360839DC770dd613007,
//             0x86CdCfbE94dC99791Bf5b8154869fab11083873d,
//             0x643b07be2Ab8f44C95bb9B4EF1B952dFE4B7B11a,
//             0x43B27945fB7DA25EC50Ca5C8DE84b5C2f34168C6,
//             0x34b91Ecd636e70D4924D3481b860ddEe69285D45,
//             0x604246eE0528BD24b57d52ee9ab903d70B7741D8,
//             0x1d574b158b2DB127910693FDC970c18296480525,
//             0x31Be5E0c485E78942F01ce33a0751ea247964B69,
//             0xEED27D6CBf6F013dd861F4D7C08fce84a7ae08F5,
//             0x48aDA25925ee3FC6961A3bFFe197E568bAf5f703,
//             0x788cEcE6A0002fFD996643326b7785F82a211F1f,
//             0x685257102D6038693f755b82C8234e84200B1d71,
//             0x669fCc8AB0393b4E1b20ea895732d1f078f856c3,
//             0x00c8657602a51A37f152348511FAcE47140d16c3,
//             0x6C0fbE000aED17aDae766aEcCb8c662e3E981b8E,
//             0x39480a7Ad6FC45051fb92f9dF4843d2360D076fb,
//             0x374440077aF2F16C252DcAeaA8782eBca7302618,
//             0x9Ee5C5C2B3B4700ef8C84835da62f8755B9B9537];

//     }

//     // 管理员
//     address _owner;
    
//     constructor() {
//         _owner = msg.sender;
//     }
    
//     // // 输入ntoken地址
//     // function setNtokenList(address[] memory _tokenList, address[] memory _nTokenList) public onlyOwner {

//     //     // 判断第一个
//     //     require(_getToken(0) == USDT_TOKEN_ADDRESS, "!USDT_TOKEN_ADDRESS");
//     //     require(_getNToken(0) == NEST_TOKEN_ADDRESS, "!NEST_TOKEN_ADDRESS");

//     //     // 判断其他
//     //     for (uint i = 1; i < TOKEN_COUNT; i++) {
//     //         require(INest_NToken_TokenMapping(NTOKEN_MAPPING30_ADDRESS).checkTokenMapping(_tokenList[i]) == _nTokenList[i], "!checkTokenMapping");
//     //     }
//     //     tokenList = _tokenList;
//     //     ntokenList = _nTokenList;
//     // }
    
//     //================================
    
//     // 更新
//     function update() public {

//         // 1.转移NEST
//         transferNest();
//         // 2.转移DAO资产
//         transferDaoAssets();
//         // 3.更新nToken和NN的映射合约
//         changeMap();
//         // 4.恢复3.5管理员
//         setGov35();
//     }
    
//     // 恢复3.5管理员
//     function setGov35() public onlyOwner {
//         INestPool(NEST_POOL_ADDRESS).setGovernance(address(_owner));
//         INestDAO(NEST_DAO_ADDRESS).loadGovernance();
//     }
    
//     // 设置ntoken映射-可以提前操作
//     function setNToken() public onlyOwner {
        
//         address[TOKEN_COUNT] memory tokenList = _tokenList();
//         address[TOKEN_COUNT] memory ntokenList = _ntokenList();
//         for(uint i = 0; i < TOKEN_COUNT; i++) {
//             INTokenController(NTOKEN_CONTROLLER_ADDRESS).setNTokenMapping(tokenList[i], ntokenList[i], 1);
//         }
//     }
    
//     //================================
    
//     // 转移NEST
//     function transferNest() public onlyOwner {

//         // 0. 验证目标地址
//         require(INestMining(NEST_MINING_ADDRESS).getNTokenAddress(USDT_TOKEN_ADDRESS) == NEST_TOKEN_ADDRESS, "!NEST_MINING_ADDRESS");
//         require(INestMining(NEST_MINING_ADDRESS).getAccountCount() == 1, "!NEST_MINING_ADDRESS");

//         INestLedger(NEST_LEDGER_ADDRESS).totalETHRewards(NEST_TOKEN_ADDRESS);
//         require(INestLedger(NEST_LEDGER_ADDRESS).checkApplication(NEST_REDEEMING_ADDRESS) == 1, "!NEST_LEDGER_ADDRESS");
        
//         // 设置NN最新区块
//         uint latestMinedHeight = INestMining35(NEST_MINING35_ADDRESS).latestMinedHeight();
//         INNIncome(NN_INCOME_ADDRESS).setBlockCursor(latestMinedHeight);
//         INNIncome(NN_INCOME_ADDRESS).increment();
//         require(INNIncome(NN_INCOME_ADDRESS).getBlockCursor() == latestMinedHeight, "!NN_INCOME_ADDRESS");

//         // 1. 从3.5的NestPool取出矿池的nest
//         uint nestGov_front = INestPool(NEST_POOL_ADDRESS).getMinerNest(address(this));
//         INestPool(NEST_POOL_ADDRESS).drainNest(address(this), nestGov_front, address(this));
//         require(IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(this)) == nestGov_front, "!nestGov_front");
//         // 管理员nest置空
//         INestPool(NEST_POOL_ADDRESS).setGovernance(address(this));
        
//         // 2. 80%分给nest挖矿合约 
//         uint nestMiningAmount_front = IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NEST_MINING_ADDRESS));
//         uint nestMiningAmount = nestGov_front * 80 / 100;
//         require(IERC20(NEST_TOKEN_ADDRESS).transfer(NEST_MINING_ADDRESS, nestMiningAmount), "transfer:nestMiningAmount");
//         require(IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NEST_MINING_ADDRESS)) == nestMiningAmount_front + nestMiningAmount, "!NEST_MINING_ADDRESS");
        
//         // 3. 5%分给DAO账本
//         uint nestLedgerAmount_front = IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NEST_LEDGER_ADDRESS));
//         uint nestLedgerAmount = nestGov_front * 5 / 100;
//         require(IERC20(NEST_TOKEN_ADDRESS).transfer(NEST_LEDGER_ADDRESS, nestLedgerAmount), "transfer:nestLedgerAmount");
//         require(IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NEST_LEDGER_ADDRESS)) == nestLedgerAmount_front + nestLedgerAmount, "!NEST_LEDGER_ADDRESS");

//         // 4. 15%分给NN挖矿合约
//         uint NNIncomeAmount_front = IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NN_INCOME_ADDRESS));
//         uint NNIncomeAmount = nestGov_front * 15 / 100;
//         require(IERC20(NEST_TOKEN_ADDRESS).transfer(NN_INCOME_ADDRESS, NNIncomeAmount), "transfer:NNIncomeAmount");
//         require(IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(NN_INCOME_ADDRESS)) == NNIncomeAmount_front + NNIncomeAmount, "!NN_INCOME_ADDRESS");
        
//         // // 5. 验证
//         // uint plusAll = nestMiningAmount + nestLedgerAmount + NNIncomeAmount;
//         // require(plusAll == nestGov_front, "!plusAll");
//     }
    
//     // 转移DAO资产
//     function transferDaoAssets() public onlyOwner {

//         // 更新管理员地址
//         INestDAO(NEST_DAO_ADDRESS).loadGovernance();

//         // 领取剩余 nest
//         INestDAO(NEST_DAO_ADDRESS).collectNestReward();

//         // 转移资产
//         address[] memory list = new address[](TOKEN_COUNT);
//         address[TOKEN_COUNT] memory ntokenList = _ntokenList();
//         for (uint i = 0; i < TOKEN_COUNT; ++i) {
//             list[i] = ntokenList[i];
//         }
//         INestDAO(NEST_DAO_ADDRESS).migrateTo(NEST_LEDGER_ADDRESS, list);
//     }
    
//     // 更新nToken和NN的映射合约
//     function changeMap() public onlyOwner {

//         require(INestGovernance(NEST_GOVERNANCE_ADDRESS).checkOwners(address(this)), "!checkOwners");
//         // 排除NEST
//         address[TOKEN_COUNT] memory ntokenList = _ntokenList();
//         for(uint i = 1; i < TOKEN_COUNT; i++) {
//             INest_NToken(ntokenList[i]).changeMapping(NEST_GOVERNANCE_ADDRESS);
//         }
        
//         ISuperMan(NEST_NODE_ADDRESS).changeMapping(NEST_GOVERNANCE_ADDRESS);
//     }

//     modifier onlyOwner {
//         require(msg.sender == _owner);
//         _;
//     }
    
// }

// // ERC20合约
// interface IERC20 {
//     function totalSupply() external view returns (uint);
//     function balanceOf(address who) external view returns (uint);
//     function allowance(address _owner, address spender) external view returns (uint);
//     function transfer(address to, uint value) external returns (bool);
//     function approve(address spender, uint value) external returns (bool);
//     function transferFrom(address from, address to, uint value) external returns (bool);
//     event Transfer(address indexed from, address indexed to, uint value);
//     event Approval(address indexed _owner, address indexed spender, uint value);
// }

// // 3.6nest挖矿合约
// interface INestMining {
//     function getNTokenAddress(address tokenAddress) external view returns (address);

//     /// @dev Get the length of registered account array
//     /// @return The length of registered account array
//     function getAccountCount() external view returns (uint);
// }

// // 3.6DAO账本
// interface INestLedger {
//     function totalETHRewards(address ntokenAddress) external view returns (uint);

//     /// @dev Check DAO application flag
//     /// @param addr DAO application contract address
//     /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
//     function checkApplication(address addr) external view returns (uint);
// }

// // 3.6NN挖矿合约
// interface INNIncome {
//     function increment() external view returns (uint);
//     function setBlockCursor(uint blockCursor) external;
//     /// @dev Get blockCursor value
//     /// @return blockCursor value
//     function getBlockCursor() external view returns (uint);
// }

// // 3.6管理员合约
// interface INestGovernance {
//     function checkOwners(address addr) external view returns (bool);
//     function setGovernance(address addr, uint flag) external;
// }

// // 3.6NTokenController
// interface INTokenController {
//     function setNTokenMapping(address tokenAddress, address ntokenAddress, uint state) external;
// }

// // 3.5矿池合约
// interface INestPool {
//     // 取出nest
//     function drainNest(address to, uint amount, address gov) external;
//     // 查询nest数量
//     function getMinerNest(address miner) external view returns (uint nestAmount);
//     // 设置管理员
//     function setGovernance(address _gov) external;
// }

// // 3.5DAO合约
// interface INestDAO {
//     // 转移资产
//     function migrateTo(address newDAO_, address[] memory ntokenL_) external;
//     // 取出剩余 nest(5%)
//     function collectNestReward() external returns(uint);
//     // 更新管理员地址
//     function loadGovernance() external;
// }

// // 3.5挖矿合约
// interface INestMining35{
//     function latestMinedHeight() external view returns (uint64);
// }

// // NToken合约
// interface INest_NToken {
//     // 更改映射
//     function changeMapping (address voteFactory) external;
// }

// // NN合约
// interface ISuperMan {
//     // 更改映射
//     function changeMapping(address map) external;
// }

// // 3.0ntoken映射合约
// interface INest_NToken_TokenMapping {
//     function checkTokenMapping(address token) external view returns (address);
// }

