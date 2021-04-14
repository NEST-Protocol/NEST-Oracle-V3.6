const BN = require("bn.js");
const $hcj = require("./hcore.js");

const NestGovernance = artifacts.require("NestGovernance");
const NestLedger = artifacts.require("NestLedger");
const NestMining = artifacts.require("NestMining");
const NestPriceFacade = artifacts.require("NestPriceFacade");
const NestRedeeming = artifacts.require("NestRedeeming");
const NestVote = artifacts.require("NestVote");
const NNIncome = artifacts.require("NNIncome");
const NToken = artifacts.require("NToken");
const NTokenController = artifacts.require("NTokenController");
const TestERC20 = artifacts.require("TestERC20");
const IBNEST = artifacts.require("IBNEST");
const NNToken = artifacts.require("NNToken");
const Nest_NToken = artifacts.require("Nest_NToken");
const SetQueryPrice = artifacts.require("SetQueryPrice");
const ITransferable = artifacts.require("ITransferable");
const UpdateAdmin = artifacts.require("UpdateAdmin");

const USDT = function(value) { return new BN('1000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const GWEI = function(value) { return new BN('1000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const ETHER = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const HBTC = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const nHBTC = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }

const LOG = function(fmt, ctx) {
    console.log($hcj.fmt(fmt, ctx));
};

const ethBalance = async function(account) {
    return new BN(await web3.eth.getBalance(account));
}

contract("NestMining", async accounts => {
    it('test', async () => {

        const account0 = accounts[0];
        //const account1 = accounts[1];

        /* 
        2021-03-22
        hbtc: 0x52e669eb87fBF69027190a0ffb6e6fEd48451E04
        usdt: 0xBa2064BbD49454517A9dBba39005bf46d31971f8
        nest: 0xBaa792bba02D82Ebf3569E01f142fc80F72D9b8f
        nest_3_VoteFactory: 0xF4061985d6854965d443c09bE09f29f51708446F
        nhbtc: 0x4269Fee5d9aAC83F1A9a81Cd17Bf71A01240765a
        nn: 0xF6298cc65E84F6a6D67Fa2890fbD2AD8735e3c29
        nestGovernance: 0xad33e1B199265dEAE3dfe4eB49B9FcaB824268E3
        nestLedger: 0x239C1421fEC5cc00695584803F52188A9eD92ef2
        nestMining: 0x7d919aaC07Ec3a7330a0C940F711abb6a6599E23
        nestPriceFacade: 0x0d3Be4D8F602469BbdF9CDEA3fA59293EFeB223B
        nestRedeeming: 0x146Af6aE0c93e9Aca1a39A644Ee7728bA9ddFA7c
        nestVote: 0xC75bd10B11E498083075876B3D6e1e6df1427De6
        nnIncome: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
        nTokenController: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
        setQueryPrice: 0x661D928e196797389Af5826BFE590345E0E2d6C0
        setQueryPrice: 0xD83C860d3A27cC5EddaB68EaBFCF9cc8ad38F15D
        */

        /*
        2021-04-04
        hbtc: 0x52e669eb87fBF69027190a0ffb6e6fEd48451E04
        usdt: 0xBa2064BbD49454517A9dBba39005bf46d31971f8
        nest: 0x3145AF0F18759D7587F22278d965Cdf7e19d6437
        nn: 0xF6298cc65E84F6a6D67Fa2890fbD2AD8735e3c29
        nestGovernance: 0x8a4fD519CEcFA7eCE7B4a204Dbb4b781B397C460
        nhbtc: 0x4269Fee5d9aAC83F1A9a81Cd17Bf71A01240765a
        nestLedger: 0x4397F20d20b5B89131b631c43AdE98Baf3A6dc9F
        nestMining: 0x4218e20Cdc77172972E40B9B56400E6ffe680724
        ntokenMining: 0x13742076bc96950cAfF0d0EfE64ebE818018121B
        nestPriceFacade: 0xCAc72395a6EaC6D0D06C8B303e26cC0Bfb5De33c
        nestRedeeming: 0xf453E3c1733f4634210ce15cd2A4fAfb191c36A5
        nestVote: 0x6B9C63a52533CB9b653B468f72fD751E0f2bc181
        nnIncome: 0xAc88d1fBF58E2646E0F4FF60aa436a70753885D9
        nTokenController: 0xF0737e3C98f1Ee41251681e2C6ad53Ab92AB0AEa
        */

        /*
        2021-04-06
        hbtc: 0x52e669eb87fBF69027190a0ffb6e6fEd48451E04
        usdt: 0xBa2064BbD49454517A9dBba39005bf46d31971f8
        nest: 0x3145AF0F18759D7587F22278d965Cdf7e19d6437
        nn: 0x8f89663562dDD4519566e590C18ec892134A0cdD
        nestGovernance: 0x74487D1a0FB2a70bb67e7D6c154d2ac71954a313
        nhbtc: 0x7A4DAca8f91c94479A6F8DD00D4bBABCa1Ac174d
        nestLedger: 0x82502A8f52BF186907BD0E12c8cEe612b4C203d1
        nestMining: 0xf94Af5800A4104aDEab67b3f5AA7A3a6E5bC64c3
        ntokenMining: 0x0684746A347033436E77030a43891Ea4FDaBb78E
        nestPriceFacade: 0x97F09D58a87B9a6f0cA1E69aCef77da3EFF8da0A
        nestRedeeming: 0xC545b531e1A093E33ec7058b70E74eD3aD113a2A
        nestVote: 0xD2BD52C52c0C2A220Ce2750e41Bc09b84526f26E
        nnIncome: 0xD5A32f6de0997749cb6F2F5B6042e2f878688aE2
        nTokenController: 0x57513Fc3133C7A4a930c345AB3aA9a4D21600Db9
        ht: 0xff2EDDDCF81033De38e70E6CdA75187a2cA567D9
        nht: 0x28aC53bD7e65306dF8ffccBbf77e7CcCaAf8415F
        updateAdmin: 0xd8C3cc981394d671939E1c51a99f70e13896162e
        */

        // 部署测试币
        //let hbtc = await TestERC20.new('HBTC', 'HBTC', 18);
        let hbtc = await TestERC20.at('0x52e669eb87fBF69027190a0ffb6e6fEd48451E04');
        console.log('hbtc: ' + hbtc.address);

        //let usdt = await TestERC20.new('USDT', "USDT", 6);
        let usdt = await TestERC20.at('0xBa2064BbD49454517A9dBba39005bf46d31971f8');
        console.log('usdt: ' + usdt.address);

        // 部署老版本合约
        //let nest = await IBNEST.new();
        let nest = await IBNEST.at('0x3145AF0F18759D7587F22278d965Cdf7e19d6437');
        console.log('nest: ' + nest.address);

        //let nn = await NNToken.new(1500, 'NN');
        let nn = await NNToken.at('0x8f89663562dDD4519566e590C18ec892134A0cdD');
        console.log('nn: ' + nn.address);

        // 部署3.6合约
        //let nestGovernance = await NestGovernance.new();
        let nestGovernance = await NestGovernance.at('0x74487D1a0FB2a70bb67e7D6c154d2ac71954a313');
        console.log('nestGovernance: ' + nestGovernance.address);
        //let nhbtc = await Nest_NToken.new('nHBTC', 'nHBTC', nestGovernance.address, account0); 
        let nhbtc = await Nest_NToken.at('0x7A4DAca8f91c94479A6F8DD00D4bBABCa1Ac174d');
        console.log('nhbtc: ' + nhbtc.address);
        
        //let nestLedger = await NestLedger.new(nest.address);
        let nestLedger = await NestLedger.at('0x82502A8f52BF186907BD0E12c8cEe612b4C203d1');
        console.log('nestLedger: ' + nestLedger.address);

        // TODO: 设置NEST的创世区块号
        //let nestMining = await NestMining.new(nest.address, 0);
        let nestMining = await NestMining.at('0xf94Af5800A4104aDEab67b3f5AA7A3a6E5bC64c3');
        console.log('nestMining: ' + nestMining.address);

        //let ntokenMining = await NestMining.new(nest.address, 0);
        let ntokenMining = await NestMining.at('0x0684746A347033436E77030a43891Ea4FDaBb78E');
        console.log('ntokenMining: ' + ntokenMining.address);

        //let nestPriceFacade = await NestPriceFacade.new();
        let nestPriceFacade = await NestPriceFacade.at('0x97F09D58a87B9a6f0cA1E69aCef77da3EFF8da0A');
        console.log('nestPriceFacade: ' + nestPriceFacade.address);

        //let nestRedeeming = await NestRedeeming.new(nest.address);
        let nestRedeeming = await NestRedeeming.at('0xC545b531e1A093E33ec7058b70E74eD3aD113a2A');
        console.log('nestRedeeming: ' + nestRedeeming.address);

        //let nestVote = await NestVote.new();
        let nestVote = await NestVote.at('0xD2BD52C52c0C2A220Ce2750e41Bc09b84526f26E');
        console.log('nestVote: ' + nestVote.address);

        //let nnIncome = await NNIncome.new(nn.address, nest.address, 0);
        let nnIncome = await NNIncome.at('0xD5A32f6de0997749cb6F2F5B6042e2f878688aE2');
        console.log('nnIncome: ' + nnIncome.address);

        //let nTokenController = await NTokenController.new(nest.address);
        let nTokenController = await NTokenController.at('0x57513Fc3133C7A4a930c345AB3aA9a4D21600Db9');
        console.log('nTokenController: ' + nTokenController.address);

        if (false) {
            // 设置内置合约地址
            console.log('设置内置合约地址');
            await nestGovernance.setBuiltinAddress(
                nest.address,
                nn.address, //nestNodeAddress,
                nestLedger.address,
                nestMining.address,
                ntokenMining.address,
                nestPriceFacade.address,
                nestVote.address,
                ntokenMining.address, //nestQueryAddress,
                nnIncome.address, //nnIncomeAddress,
                nTokenController.address //nTokenControllerAddress
            );
            // 添加redeeming合约映射
            console.log('添加redeeming合约映射');
            await nestGovernance.registerAddress('nest.dao.redeeming', nestRedeeming.address);

            // 更新合约地址
            console.log('更新合约地址: nestLedger');
            await nestLedger.update(nestGovernance.address);
            console.log('更新合约地址: nestMining');
            await nestMining.update(nestGovernance.address);
            console.log('更新合约地址: ntokenMining');
            await ntokenMining.update(nestGovernance.address);
            console.log('更新合约地址: nestPriceFacade');
            await nestPriceFacade.update(nestGovernance.address);
            console.log('更新合约地址: nestRedeeming');
            await nestRedeeming.update(nestGovernance.address);
            console.log('更新合约地址: nestVote');
            await nestVote.update(nestGovernance.address);
            console.log('更新合约地址: nTokenController');
            await nTokenController.update(nestGovernance.address);

            // 设置参数
            console.log('设置参数: nestLedger');
            await nestLedger.setConfig({
                // NEST分成（万分制）。2000
                nestRewardScale: 2000,
                // NTOKEN分成（万分制）。8000
                //ntokenRewardScale: 8000
            });
            
            console.log('设置参数: nestMining');
            await nestMining.setConfig({
            
                // 报价的eth单位。30
                // 可以通过将postEthUnit设置为0来停止报价和吃单（关闭和取回不受影响）
                postEthUnit: 3,
        
                // 报价的手续费（万分之一eth，DIMI_ETHER）。1000
                postFeeUnit: 1000,
        
                // 矿工挖到nest的比例（万分制）。8000
                minerNestReward: 8000,
                
                // 矿工挖到的ntoken比例，只对3.0版本创建的ntoken有效（万分制）。9500
                minerNTokenReward: 9500,
        
                // 双轨报价阈值，当ntoken的发行量超过此阈值时，禁止单轨报价（单位：10000 ether）。500
                doublePostThreshold: 500,
                
                // ntoken最多可以挖到多少区块。100
                ntokenMinedBlockLimit: 100,
        
                // -- 公共配置
                // 吃单资产翻倍次数。4
                maxBiteNestedLevel: 4,
                
                // 价格生效区块间隔。20
                priceEffectSpan: 20,
        
                // 报价抵押nest数量（单位千）。100
                pledgeNest: 100
            });

            console.log('设置参数: ntokenMining');
            await ntokenMining.setConfig({
            
                // 报价的eth单位。30
                // 可以通过将postEthUnit设置为0来停止报价和吃单（关闭和取回不受影响）
                postEthUnit: 1,
        
                // 报价的手续费（万分之一eth，DIMI_ETHER）。1000
                postFeeUnit: 1000,
        
                // 矿工挖到nest的比例（万分制）。8000
                minerNestReward: 8000,
                
                // 矿工挖到的ntoken比例，只对3.0版本创建的ntoken有效（万分制）。9500
                minerNTokenReward: 9500,
        
                // 双轨报价阈值，当ntoken的发行量超过此阈值时，禁止单轨报价（单位：10000 ether）。500
                doublePostThreshold: 500,
                
                // ntoken最多可以挖到多少区块。100
                ntokenMinedBlockLimit: 100,
        
                // -- 公共配置
                // 吃单资产翻倍次数。4
                maxBiteNestedLevel: 4,
                
                // 价格生效区块间隔。20
                priceEffectSpan: 20,
        
                // 报价抵押nest数量（单位千）。100
                pledgeNest: 100
            });

            console.log('设置参数: nestPriceFacade');
            await nestPriceFacade.setConfig({

                // 单轨询价费用（万分之一eth，DIMI_ETHER）。100
                singleFee: 100,
        
                // 双轨询价费用（万分之一eth，DIMI_ETHER）。100
                doubleFee: 100,
                
                // 调用地址的正常状态标记。0
                normalFlag: 0
            });

            console.log('设置参数: nestRedeeming');
            await nestRedeeming.setConfig({

                // 单轨询价费用。0.01ether
                // 调用价格改为在NestPriceFacade里面确定。需要考虑退回的情况
                //fee: '10000000000000000',
        
                // 激活回购阈值，当ntoken的发行量超过此阈值时，激活回购（单位：10000 ether）。500
                activeThreshold: 500,
        
                // 每区块回购nest数量。1000
                nestPerBlock: 1000,
        
                // 单次回购nest数量上限。300000
                nestLimit: 300000,
        
                // 每区块回购ntoken数量。10
                ntokenPerBlock: 10,
        
                // 单次回购ntoken数量上限。3000
                ntokenLimit: 3000,
        
                // 价格偏差上限，超过此上限停止回购（万分制）。500
                priceDeviationLimit: 500
            });

            console.log('设置参数: nestVote');
            await nestVote.setConfig({

                // 投票通过需要的比例（万分制）。5100
                acceptance: 5100,
        
                // 投票时间周期。5 * 86400秒
                voteDuration: 5 * 86400,
        
                // 投票需要抵押的nest数量。100000 nest
                proposalStaking: '100000000000000000000000'
            });

            console.log('设置参数: nTokenController');
            await nTokenController.setConfig({

                // 开通ntoken需要支付的nest数量。10000 ether
                openFeeNestAmount: '10000000000000000000000',

                // ntoken管理功能启用状态。0：未启用，1：已启用
                state: 1
            });

            // 添加ntoken映射
            console.log('添加ntoken映射: hbtc->nhbtc');
            await nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1);
            console.log('添加ntoken映射: usdt->nest');
            await nTokenController.setNTokenMapping(usdt.address, nest.address, 1);
            // 给投票合约授权
            console.log('setGovernance(nestVote.address)');
            await nestGovernance.setGovernance(nestVote.address, 1);
            console.log('setApplication(nestRedeeming.address)');
            await nestLedger.setApplication(nestRedeeming.address, 1);

            // 修改nHBTC信息
            console.log('registerAddress(nest.nToken.offerMain)');
            await nestGovernance.registerAddress('nest.nToken.offerMain', nestMining.address);
            console.log('nn.changeMapping()');
            await nhbtc.changeMapping(nestGovernance.address);
            console.log('nn.setContracts()');
            await nn.setContracts(nnIncome.address);

            // 禁止usdt报价
            console.log('禁止usdt报价');
            await ntokenMining.setNTokenAddress(usdt.address, usdt.address);
            console.log('setNestQuery(usdt)');
            await nestPriceFacade.setNestQuery(usdt.address, nestMining.address);
            console.log('setNestQuery(nest)');
            await nestPriceFacade.setNestQuery(nest.address, nestMining.address);

            // 转入nest
            console.log('nest.transfer(nestMining.address)');
            await nest.transfer(nestMining.address, ETHER(1000000000 * 0.8));
            console.log('nest.transfer(nestLedger.address)');
            await nest.transfer(nestLedger.address, ETHER(1000000000 * 0.05));
            console.log('nest.transfer(nnIncome.address)');
            await nest.transfer(nnIncome.address,   ETHER(1000000000 * 0.15));
        } else {
        }
    });
});
