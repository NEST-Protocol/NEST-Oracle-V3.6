// Load compiled artifacts
const IBNEST = artifacts.require('IBNEST');
const NNToken = artifacts.require('NNToken');
const TestERC20 = artifacts.require('TestERC20');
const Nest_NToken = artifacts.require('Nest_NToken');
const NToken = artifacts.require('NToken');
const NestGovernance = artifacts.require('NestGovernance');
const NestLedger = artifacts.require('NestLedger');
const NestPriceFacade = artifacts.require('NestPriceFacade');
const NTokenController = artifacts.require('NTokenController');
const NestVote = artifacts.require('NestVote');
const NestMining = artifacts.require('NestMining');
const NestRedeeming = artifacts.require('NestRedeeming');
const NNIncome = artifacts.require('NNIncome');

module.exports = async function() {
    
    console.log('***** normal mode *****');
    let nest = await IBNEST.new();
    let nn = await NNToken.new(1500, 'NN');
    //let nest = await IBNEST.at('0xBC68a55ADBAEAA1303D341BBE4EF9d4768940FC8');
    //let nn = await NNToken.at('0xB4ca64C3820E3B837bA3f1475fc871FD1C3f232a');
    let usdt = await TestERC20.new('USDT', 'USDT', 6);
    let hbtc = await TestERC20.new('HBTC', 'HBTC', 18);
    let nestGovernance = await NestGovernance.new();
    let nestLedger = await NestLedger.new();
    let nTokenController = await NTokenController.new();
    let nestVote = await NestVote.new();
    let nestMining = await NestMining.new();
    let ntokenMining = await NestMining.new();
    let nestPriceFacade = await NestPriceFacade.new();
    let nestRedeeming = await NestRedeeming.new();
    let nnIncome = await NNIncome.new();

    await nestGovernance.initialize('0x0000000000000000000000000000000000000000');
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

    await nestLedger.initialize(nestGovernance.address);
    await nTokenController.initialize(nestGovernance.address);
    await nestVote.initialize(nestGovernance.address);
    await nestMining.initialize(nestGovernance.address);
    await ntokenMining.initialize(nestGovernance.address);
    await nestPriceFacade.initialize(nestGovernance.address);
    await nestRedeeming.initialize(nestGovernance.address);
    await nnIncome.initialize(nestGovernance.address);

    await nestGovernance.update(nestGovernance.address);
    await nestLedger.update(nestGovernance.address);
    await nTokenController.update(nestGovernance.address);
    await nestVote.update(nestGovernance.address);
    await nestMining.update(nestGovernance.address);
    await ntokenMining.update(nestGovernance.address);
    await nestPriceFacade.update(nestGovernance.address);
    await nestRedeeming.update(nestGovernance.address);
    await nnIncome.update(nestGovernance.address);

    await nestGovernance.registerAddress('nest.dao.redeeming', nestRedeeming.address);
    await nestGovernance.registerAddress('nest.nToken.offerMain', ntokenMining.address);
    let nhbtc = await Nest_NToken.new('NHBTC', 'NToken0001', nestGovernance.address, (await web3.eth.getAccounts())[1]);

    // 添加ntoken映射
    await nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1);
    await nTokenController.setNTokenMapping(usdt.address, nest.address, 1);

    await nestPriceFacade.setNestQuery(usdt.address, nestMining.address);
    await nestPriceFacade.setNestQuery(nest.address, nestMining.address);

    // 给投票合约授权
    await nestGovernance.setGovernance(nestVote.address, 1);
    await nestLedger.setApplication(nestRedeeming.address, 1);
    await nn.setContracts(nnIncome.address);

    let contracts = {
        nest: nest,
        nn: nn,
        usdt: usdt,
        hbtc: hbtc,
        nhbtc: nhbtc,
        nestLedger: nestLedger,
        nestMining: nestMining,
        ntokenMining: ntokenMining,
        nestPriceFacade: nestPriceFacade,
        nestVote: nestVote,
        nnIncome: nnIncome,
        nTokenController: nTokenController,
        nestRedeeming: nestRedeeming,
        nestGovernance: nestGovernance
    };
    
    await setConfig(contracts);
    return contracts;
};

async function setConfig(contracts) {

    // 设置参数
    await contracts.nestLedger.setConfig({
        // NEST分成（万分制）。2000
        nestRewardScale: 2000,
        // NTOKEN分成（万分制）。8000
        //ntokenRewardScale: 8000
    });

    await contracts.nestMining.setConfig({

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

    await contracts.ntokenMining.setConfig({

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

    await contracts.nestPriceFacade.setConfig({

        // 单轨询价费用（万分之一eth，DIMI_ETHER）。100
        singleFee: 100,

        // 双轨询价费用（万分之一eth，DIMI_ETHER）。100
        doubleFee: 100,
        
        // 调用地址的正常状态标记。0
        normalFlag: 0
    });

    await contracts.nestRedeeming.setConfig({

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

    await contracts.nestVote.setConfig({

        // 投票通过需要的比例（万分制）。5100
        acceptance: 5100,

        // 投票时间周期。5 * 86400秒
        voteDuration: 5 * 86400,

        // 投票需要抵押的nest数量。100000 nest
        proposalStaking: '100000000000000000000000'
    });

    await contracts.nTokenController.setConfig({

        // 开通ntoken需要支付的nest数量。10000 ether
        openFeeNestAmount: '10000000000000000000000',

        // ntoken管理功能启用状态。0：未启用，1：已启用
        state: 1
    });  
}

