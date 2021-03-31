
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
        const account1 = accounts[1];

        // 部署测试币
        let hbtc = await TestERC20.new('HBTC', 'HBTC', 18);
        let usdt = await TestERC20.new('USDT', "USDT", 6);

        // 部署老版本合约
        let nest = await IBNEST.new();
        let nn = await NNToken.new(1500, 'NN');

        // 部署3.6合约
        // const NestGovernance = artifacts.require("NestGovernance");
        let nestGovernance = await NestGovernance.new();
        let nhbtc = await Nest_NToken.new('nHBTC', 'nHBTC', nestGovernance.address, account1); 

        // const NestLedger = artifacts.require("NestLedger");
        let nestLedger = await NestLedger.new(nest.address);

        // const NestMining = artifacts.require("NestMining");
        let nestMining = await NestMining.new(nest.address, 0);

        // const NestPriceFacade = artifacts.require("NestPriceFacade");
        let nestPriceFacade = await NestPriceFacade.new();

        // const NestRedeeming = artifacts.require("NestRedeeming");
        let nestRedeeming = await NestRedeeming.new(nest.address);

        // const NestVote = artifacts.require("NestVote");
        let nestVote = await NestVote.new();

        let nnIncome = await NNIncome.new(nn.address, nest.address, 0);

        // const NToken = artifacts.require("NToken");
        // const NTokenController = artifacts.require("NTokenController");
        let nTokenController = await NTokenController.new(nest.address);

        // 设置内置合约地址
        await nestGovernance.setBuiltinAddress(
            nest.address,
            nn.address, //nestNodeAddress,
            nestLedger.address,
            nestMining.address,
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
            proposalStaking: '100000000000000000000000'
        });

        await nTokenController.setConfig({

            // 开通ntoken需要支付的nest数量。10000 ether
            openFeeNestAmount: '10000000000000000000000',

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
        await nestGovernance.registerAddress("nest.nToken.offerMain", nestMining.address);
        await nhbtc.changeMapping(nestGovernance.address);
        await nn.setContracts(nnIncome.address);

        // 初始化usdt余额
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await usdt.transfer(account0, USDT('10000000'), { from: account1 });
        await usdt.transfer(account1, USDT('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('6000000000'));
        await nest.transfer(nnIncome.address, ETHER('2000000000'));
        await nn.transfer(account1, 300);

        const skipBlocks = async function(blockCount) {
            for (var i = 0; i < blockCount; ++i) {
                await web3.eth.sendTransaction({ from: account0, to: account0, value: ETHER(1)});
            }
        };

        // 显示余额
        const getBalance = async function(account) {
            let balances = {
                balance: {
                    eth: await ethBalance(account),
                    hbtc: await hbtc.balanceOf(account),
                    nhbtc: await nhbtc.balanceOf(account),
                    nest: await nest.balanceOf(account)
                },
                pool: {
                    eth: ETHER(0),
                    hbtc: await nestMining.balanceOf(hbtc.address, account),
                    nhbtc: await nestMining.balanceOf(nhbtc.address, account),
                    nest: await nestMining.balanceOf(nest.address, account)
                }
            };

            return balances;
        };
        const showBalance = async function(account, msg) {
            console.log(msg);
            let balances = await getBalance(account);

            LOG('balance: {eth}eth, {nest}nest, {hbtc}hbtc, {nhbtc}nhbtc', balances.balance);
            LOG('pool: {eth}eth, {nest}nest, {hbtc}hbtc, {nhbtc}nhbtc', balances.pool);

            return balances;
        };

        await usdt.approve(nestMining.address, USDT(100000000));
        await nest.approve(nestMining.address, ETHER(100000000));
        {
            // 1. 报价
            await nestMining.post2(usdt.address, 30, USDT(1600), ETHER(51200 + 512 * 0), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1700), ETHER(51200 + 512 * 1), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1800), ETHER(51200 + 512 * 2), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1900), ETHER(51200 + 512 * 3), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(2000), ETHER(51200 + 512 * 4), { value: ETHER(60 + 10) });

            await skipBlocks(20);
            await nestMining.stat(usdt.address);
            await nestMining.stat(nest.address);

            let latestPriceAndTriggeredPriceInfo = await nestMining.latestPriceAndTriggeredPriceInfo(nest.address);
            LOG('latestPriceBlockNumber: {latestPriceBlockNumber}\n'
                + 'latestPriceValue: {latestPriceValue}\n'
                + 'triggeredPriceBlockNumber: {triggeredPriceBlockNumber}\n'
                + 'triggeredPriceValue: {triggeredPriceValue}\n'
                + 'triggeredAvgPrice: {triggeredAvgPrice}\n'
                + 'triggeredSigmaSQ: {triggeredSigmaSQ}\n'
                , latestPriceAndTriggeredPriceInfo);

            // 2. 累计佣金
            console.log('feeUnit: ' + (await nestMining.getFeeUnit(usdt.address)).toString());
            console.log('nest rewards: ' + await nestLedger.totalRewards(nest.address));
            await nestMining.settle(usdt.address);
            console.log('nest rewards: ' + await nestLedger.totalRewards(nest.address));

            // 3. 检查回购额度
            console.log('nest quota: ' + await nestRedeeming.quotaOf(nest.address));

            // 4. 第一次回购
            await nest.approve(nestRedeeming.address, ETHER(10000000));
            await nestRedeeming.redeem(nest.address, ETHER(100000), account0, { value: ETHER(0.1) });
            console.log('nest rewards: ' + await nestLedger.totalRewards(nest.address));

            // 5. 检查回购额度
            console.log('nest quota: ' + await nestRedeeming.quotaOf(nest.address));
            
            // 6. 报价
            await nestMining.post2(usdt.address, 30, USDT(1600), ETHER(51200 + 512 * 0), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1700), ETHER(51200 + 512 * 1), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1800), ETHER(51200 + 512 * 2), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1900), ETHER(51200 + 512 * 3), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(2000), ETHER(51200 + 512 * 4), { value: ETHER(60 + 10) });

            await skipBlocks(20);
            await nestMining.stat(usdt.address);
            await nestMining.stat(nest.address);
            
            latestPriceAndTriggeredPriceInfo = await nestMining.latestPriceAndTriggeredPriceInfo(nest.address);
            LOG('latestPriceBlockNumber: {latestPriceBlockNumber}\n'
                + 'latestPriceValue: {latestPriceValue}\n'
                + 'triggeredPriceBlockNumber: {triggeredPriceBlockNumber}\n'
                + 'triggeredPriceValue: {triggeredPriceValue}\n'
                + 'triggeredAvgPrice: {triggeredAvgPrice}\n'
                + 'triggeredSigmaSQ: {triggeredSigmaSQ}\n'
                , latestPriceAndTriggeredPriceInfo);

            let quota = await nestRedeeming.quotaOf(nest.address);
            console.log('nest quota: ' + quota);
            assert.equal(0, quota.cmp(ETHER(200000 + 1000 * 27)));

            // 7. 第二次回购
            await nestRedeeming.redeem(nest.address, ETHER(100000), account0, { value: ETHER(0.01) });

            // 8. 检查回购额度
            console.log('nest quota: ' + await nestRedeeming.quotaOf(nest.address));

            let arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
            let receipt = await nestMining.closeList2(usdt.address, arr, arr);
            console.log(receipt);
        }
    });
});
