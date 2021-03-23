
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
const Nest_3_VoteFactory = artifacts.require("Nest_3_VoteFactory");
const SetQueryPrice = artifacts.require("SetQueryPrice");

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
        let nest = await IBNEST.at('0xBaa792bba02D82Ebf3569E01f142fc80F72D9b8f');
        console.log('nest: ' + nest.address);

        //let nest_3_VoteFactory = await Nest_3_VoteFactory.new();
        let nest_3_VoteFactory = await Nest_3_VoteFactory.at('0xF4061985d6854965d443c09bE09f29f51708446F');
        console.log('nest_3_VoteFactory: ' + nest_3_VoteFactory.address);

        //let nhbtc = await Nest_NToken.new('nHBTC', 'nHBTC', nest_3_VoteFactory.address, account0); //(string memory _name, string memory _symbol, address voteFactory, address bidder)
        let nhbtc = await Nest_NToken.at('0x4269Fee5d9aAC83F1A9a81Cd17Bf71A01240765a');
        console.log('nhbtc: ' + nhbtc.address);

        //let nn = await NNToken.new(1500, 'NN');
        let nn = await NNToken.at('0xF6298cc65E84F6a6D67Fa2890fbD2AD8735e3c29');
        console.log('nn: ' + nn.address);

        // 部署3.6合约
        // const NestGovernance = artifacts.require("NestGovernance");
        //let nestGovernance = await NestGovernance.new();
        let nestGovernance = await NestGovernance.at('0xad33e1B199265dEAE3dfe4eB49B9FcaB824268E3');
        console.log('nestGovernance: ' + nestGovernance.address);

        // const NestLedger = artifacts.require("NestLedger");
        //let nestLedger = await NestLedger.new(nest.address);
        let nestLedger = await NestLedger.at('0x239C1421fEC5cc00695584803F52188A9eD92ef2');
        console.log('nestLedger: ' + nestLedger.address);

        // const NestMining = artifacts.require("NestMining");
        // TODO: 设置NEST的创世区块号
        //let nestMining = await NestMining.new(nest.address, 0);
        let nestMining = await NestMining.at('0x7d919aaC07Ec3a7330a0C940F711abb6a6599E23');
        console.log('nestMining: ' + nestMining.address);

        // const NestPriceFacade = artifacts.require("NestPriceFacade");
        //let nestPriceFacade = await NestPriceFacade.new();
        let nestPriceFacade = await NestPriceFacade.at('0x0d3Be4D8F602469BbdF9CDEA3fA59293EFeB223B');
        console.log('nestPriceFacade: ' + nestPriceFacade.address);

        // const NestRedeeming = artifacts.require("NestRedeeming");
        //let nestRedeeming = await NestRedeeming.new(nest.address);
        let nestRedeeming = await NestRedeeming.at('0x146Af6aE0c93e9Aca1a39A644Ee7728bA9ddFA7c');
        console.log('nestRedeeming: ' + nestRedeeming.address);

        // const NestVote = artifacts.require("NestVote");
        //let nestVote = await NestVote.new();
        let nestVote = await NestVote.at('0xC75bd10B11E498083075876B3D6e1e6df1427De6');
        console.log('nestVote: ' + nestVote.address);

        //let nnIncome = await NNIncome.new(nn.address, nest.address, 0);
        let nnIncome = await NNIncome.at('0x3DA5c9aafc6e6D6839E62e2fB65825869019F291');
        console.log('nnIncome: ' + nnIncome.address);

        // const NToken = artifacts.require("NToken");
        // const NTokenController = artifacts.require("NTokenController");
        //let nTokenController = await NTokenController.new(nest.address);
        let nTokenController = await NTokenController.at('0xc39dC1385a44fBB895991580EA55FC10e7451cB3');
        console.log('nTokenController: ' + nTokenController.address);

        // 设置内置合约地址
        await nestGovernance.setBuiltinAddress(
            nest.address,
            nn.address, //nestNodeAddress,
            nestLedger.address,
            nestMining.address,
            nestPriceFacade.address,
            nestVote.address,
            nestMining.address, //nestQueryAddress,
            nnIncome.address, //nnIncomeAddress,
            nTokenController.address //nTokenControllerAddress
        );
        // 添加redeeming合约映射
        await nestGovernance.registerAddress("nest.dao.redeeming", nestRedeeming.address);

        // 更新合约地址
        await nestLedger.update(nestGovernance.address);
        await nestMining.update(nestGovernance.address);
        await nestPriceFacade.update(nestGovernance.address);
        await nestRedeeming.update(nestGovernance.address);
        await nestVote.update(nestGovernance.address);
        await nTokenController.update(nestGovernance.address);

        // 设置参数
        await nestLedger.setConfig({
            // NEST分成（万分制）。2000
            nestRewardScale: 2000,
            // NTOKEN分成（万分制）。8000
            ntokenRedardScale: 8000
        });
        
        await nestMining.setConfig({
        
            // 报价的eth单位。30
            // 可以通过将postEthUnit设置为0来停止报价和吃单（关闭和取回不受影响）
            postEthUnit: 30,
    
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

        await nestPriceFacade.setConfig({

            // 单轨询价费用（万分之一eth，DIMI_ETHER）。100
            singleFee: 100,
    
            // 双轨询价费用（万分之一eth，DIMI_ETHER）。100
            doubleFee: 100,
            
            // 调用地址的正常状态标记。0
            normalFlag: 0
        });

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

        await nestVote.setConfig({

            // 投票通过需要的比例（万分制）。5100
            acceptance: 5100,
    
            // 投票时间周期。5 * 86400秒
            voteDuration: 5 * 86400,
    
            // 投票需要抵押的nest数量。100000 nest
            proposalStaking: 100000
        });

        await nTokenController.setConfig({

            // 开通ntoken需要支付的nest数量。10000 ether
            openFeeNestAmount: 10000,

            // ntoken管理功能启用状态。0：未启用，1：已启用
            state: 1
        });

        // 添加ntoken映射
        await nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1);
        await nTokenController.setNTokenMapping(usdt.address, nest.address, 1);
        // 给投票合约授权
        await nestGovernance.setGovernance(nestVote.address, 1);
        await nestLedger.setApplication(nestRedeeming.address, 1);

        // 修改nHBTC信息
        await nest_3_VoteFactory.addContractAddress("nest.nToken.offerMain", nestMining.address);
        await nhbtc.changeMapping(nest_3_VoteFactory.address);
        await nn.setContracts(nnIncome.address);

        // await nestMining.setConfig({
        
        //     // 报价的eth单位。30
        //     // 可以通过将postEthUnit设置为0来停止报价和吃单（关闭和取回不受影响）
        //     postEthUnit: 3,
    
        //     // 报价的手续费（万分之一eth，DIMI_ETHER）。1000
        //     postFeeUnit: 1000,
    
        //     // 矿工挖到nest的比例（万分制）。8000
        //     minerNestReward: 8000,
            
        //     // 矿工挖到的ntoken比例，只对3.0版本创建的ntoken有效（万分制）。9500
        //     minerNTokenReward: 9500,
    
        //     // 双轨报价阈值，当ntoken的发行量超过此阈值时，禁止单轨报价（单位：10000 ether）。500
        //     doublePostThreshold: 500,
            
        //     // ntoken最多可以挖到多少区块。100
        //     ntokenMinedBlockLimit: 100,
    
        //     // -- 公共配置
        //     // 吃单资产翻倍次数。4
        //     maxBiteNestedLevel: 4,
            
        //     // 价格生效区块间隔。20
        //     priceEffectSpan: 10,
    
        //     // 报价抵押nest数量（单位千）。100
        //     pledgeNest: 100
        // });
    });
});
