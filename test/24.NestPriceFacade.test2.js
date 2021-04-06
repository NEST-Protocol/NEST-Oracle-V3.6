
const BN = require("bn.js");
const $hcj = require("./hcore.js");

const NestGovernance = artifacts.require("NestGovernance");
const NestLedger = artifacts.require("NestLedger");
const NestMining = artifacts.require("NestMining");
const INestPriceFacade = artifacts.require("INestPriceFacade");
const INestQuery = artifacts.require("INestQuery");
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

        let ntokenMining = await NestMining.new(nest.address, 0);

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
            ntokenMining.address,
            nestPriceFacade.address,
            nestVote.address,
            ntokenMining.address, //nestQueryAddress,
            nnIncome.address, //nnIncomeAddress,
            nTokenController.address //nTokenControllerAddress
        );
        // 添加redeeming合约映射
        await nestGovernance.registerAddress('nest.dao.redeeming', nestRedeeming.address);

        // 更新合约地址
        await nestLedger.update(nestGovernance.address);
        await nestMining.update(nestGovernance.address);
        await ntokenMining.update(nestGovernance.address);
        await nestPriceFacade.update(nestGovernance.address);
        await nestRedeeming.update(nestGovernance.address);
        await nestVote.update(nestGovernance.address);
        await nTokenController.update(nestGovernance.address);

        // 设置参数
        await nestLedger.setConfig({
            // NEST分成（万分制）。2000
            nestRewardScale: 2000,
            // NTOKEN分成（万分制）。8000
            //ntokenRewardScale: 8000
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

        await ntokenMining.setConfig({
        
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
        await nestGovernance.registerAddress('nest.nToken.offerMain', ntokenMining.address);
        await nhbtc.changeMapping(nestGovernance.address);
        await nn.setContracts(nnIncome.address);

        // 添加ntoken映射
        // 初始化usdt余额
        await hbtc.transfer(account0, ETHER('10000000'), { from: account0 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account0 });
        await usdt.transfer(account1, USDT('10000000'), { from: account0 });
        await usdt.transfer(account0, USDT('10000000'), { from: account0 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

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

        let balance0 = await showBalance(account0, 'account0');
        let balance1 = await showBalance(account1, 'account1');

        await nest.approve(nestMining.address, ETHER('1000000000'));
        await hbtc.approve(nestMining.address, HBTC('10000000'));
        //await nest.approve(nestMining.address, ETHER('1000000000'), { from: account1 });
        //await hbtc.approve(nestMining.address, HBTC('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let mined = nHBTC(0);
        
        if (true) {
            // config
            console.log('读取配置');
            console.log(await nestPriceFacade.getConfig());
            console.log('修改配置');
            nestPriceFacade.setConfig({
                // Single query fee（0.0001 ether, DIMI_ETHER). 100
                singleFee: 137,

                // Double query fee（0.0001 ether, DIMI_ETHER). 100
                doubleFee: 247,

                // The normal state flag of the call address. 0
                normalFlag: 1
            });
            console.log(await nestPriceFacade.getConfig());
            LOG('usdtQuery: {usdtQuery}, nestQuery: {nestQuery}', {
                usdtQuery: await nestPriceFacade.getNestQuery(usdt.address),
                nestQuery: await nestPriceFacade.getNestQuery(nest.address),
            });
            await nestPriceFacade.setNestQuery(usdt.address, nestMining.address);
            await nestPriceFacade.setNestQuery(nest.address, nestMining.address);
            LOG('usdtQuery: {usdtQuery}, nestQuery: {nestQuery}', {
                usdtQuery: await nestPriceFacade.getNestQuery(usdt.address),
                nestQuery: await nestPriceFacade.getNestQuery(nest.address),
            });
        }

        nestPriceFacade = await INestPriceFacade.at(nestPriceFacade.address);
        if (true) {
            
            // 直接调用价格
            console.log('triggeredPrice()')
            let price = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: price.blockNumber.toString(),
                price: price.price.toString()
            });
            await nestPriceFacade.setAddressFlag(account0, 1);
            console.log('addressFlag: ' + await nestPriceFacade.getAddressFlag(account0));

            console.log('triggeredPrice()');
            let pi = await nestPriceFacade.triggeredPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            // console.log('findPrice()');
            // await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10, account1, { value: ETHER(0.0137) });

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address, account1, { value: ETHER(0.0247) });
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalRewards(usdt.address),
                balance: await ethBalance(nestLedger.address)
            });
            assert.equal(0, ETHER(0.0137 * 5 + 0.0247 * 3).cmp(await nestLedger.totalRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 5 + 0.0247 * 3).cmp(await ethBalance(nestLedger.address)));
        }

        if (true) {
            // 报价后调用价格
            console.log('报价后调用价格');
            await nest.approve(nestMining.address, ETHER(1000000000));
            await usdt.approve(nestMining.address, USDT(1000000000));
            let receipt = await nestMining.post2(usdt.address, 30, USDT(1600), ETHER(65536), { value: ETHER(60.1) });
            console.log(receipt);

            console.log('triggeredPrice()');
            let pi = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('triggeredPriceInfo()');
            pi = await nestMining.triggeredPriceInfo(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString()
            });

            console.log('findPrice()');
            pi = await nestMining.findPrice(usdt.address, await web3.eth.getBlockNumber());
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                bn: await web3.eth.getBlockNumber()
            });

            console.log('latestPrice()');
            pi = await nestMining.latestPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('lastPriceList()');
            await nestMining.lastPriceList(usdt.address, 10);

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestMining.latestPriceAndTriggeredPriceInfo(usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });

            console.log('triggeredPrice2()');
            pi = await nestMining.triggeredPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                pripice: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString()
            });

            console.log('triggeredPriceInfo2()');
            pi = await nestMining.triggeredPriceInfo2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
                ntokenAvgPrice: pi.ntokenAvgPrice.toString(),
                ntokenSigmaSQ: pi.ntokenSigmaSQ.toString(),
            });

            console.log('latestPrice2()');
            pi = await nestMining.latestPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
            });
        }

        if (true) {
            // 等待后调用价格
            console.log('等待后调用价格');
            await skipBlocks(20);
            await nestMining.closeList2(usdt.address, [0], [0]);
            console.log('triggeredPrice()');
            let pi = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('triggeredPriceInfo()');
            pi = await nestMining.triggeredPriceInfo(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString()
            });

            console.log('findPrice()');
            pi = await nestMining.findPrice(usdt.address, await web3.eth.getBlockNumber());
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                bn: await web3.eth.getBlockNumber()
            });

            console.log('latestPrice()');
            pi = await nestMining.latestPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('lastPriceList()');
            await nestMining.lastPriceList(usdt.address, 10);

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestMining.latestPriceAndTriggeredPriceInfo(usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });

            console.log('triggeredPrice2()');
            pi = await nestMining.triggeredPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                pripice: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString()
            });

            console.log('triggeredPriceInfo2()');
            pi = await nestMining.triggeredPriceInfo2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
                ntokenAvgPrice: pi.ntokenAvgPrice.toString(),
                ntokenSigmaSQ: pi.ntokenSigmaSQ.toString(),
            });

            console.log('latestPrice2()');
            pi = await nestMining.latestPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
            });
        }

        if (true) {
            // 多次报价后调用价格
            console.log('多次报价后调用价格');
            
            let arr = [];
            let avgUsdtPrice = USDT(1600);
            let avgNestPrice = ETHER(65536);
            let usdtSigmaSQ = new BN(0);
            let nestSigmaSQ = new BN(0);

            let d = new BN(22);
            let prevUsdtPrice = new USDT(1600);
            let prevNestPrice = new ETHER(65535);
            for (var i = 0; i < 10; ++i) {
                let receipt = await nestMining.post2(usdt.address, 30, USDT(1600 + i * 10), ETHER(65536 + i * 655.36), { value: ETHER(60.1) });
                console.log('报价' + i + ': ' + (1600 + i * 10));
                console.log(receipt);
                arr.push(i + 1);

                avgUsdtPrice = avgUsdtPrice.mul(new BN(95)).add(USDT(1600 + i * 10).mul(new BN(5))).div(new BN(100));
                avgNestPrice = avgNestPrice.mul(new BN(95)).add(ETHER(65536 + i * 655.36).mul(new BN(5))).div(new BN(100));

                let earn = USDT(1600 + i * 10).mul(new BN('281474976710656')).div(prevUsdtPrice).sub(new BN('281474976710656'));
                usdtSigmaSQ = usdtSigmaSQ.mul(new BN(95)).add(
                    earn.mul(earn).div(new BN(14).mul(d)).mul(new BN(5)).div(new BN('281474976710656'))
                ).div(new BN(100));
                prevUsdtPrice = USDT(1600 + i * 10);

                earn = ETHER(65536 + i * 655.36).mul(new BN('281474976710656')).div(prevNestPrice).sub(new BN('281474976710656'));
                nestSigmaSQ = nestSigmaSQ.mul(new BN(95)).add(
                    earn.mul(earn).div(new BN(14).mul(d)).mul(new BN(5)).div(new BN('281474976710656'))
                ).div(new BN(100));
                prevNestPrice = ETHER(65536 + i * 655.36);

                d = new BN(1);
            }

            usdtSigmaSQ = usdtSigmaSQ.mul(ETHER(1)).div(new BN('281474976710656'));
            nestSigmaSQ = nestSigmaSQ.mul(ETHER(1)).div(new BN('281474976710656'));
            await skipBlocks(20);
            await nestMining.closeList2(usdt.address, arr, arr);

            console.log('triggeredPrice()');
            let pi = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('triggeredPriceInfo()');
            pi = await nestMining.triggeredPriceInfo(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString()
            });
            assert.equal(0, avgUsdtPrice.cmp(pi.avgPrice));
            LOG('usdtSigmaSQ: {usdtSigmaSQ}, sigmaSQ: {sigmaSQ}', {
                usdtSigmaSQ: usdtSigmaSQ.toString(),
                sigmaSQ: pi.sigmaSQ.toString()
            });
            assert.equal(0, usdtSigmaSQ.cmp(pi.sigmaSQ));
            
            let list = await nestMining.lastPriceList(usdt.address, 5);
            for (var i in list) {
                console.log(list[i].toString());
            }

            console.log('findPrice()');
            pi = await nestMining.findPrice(usdt.address, await web3.eth.getBlockNumber());
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                bn: await web3.eth.getBlockNumber()
            });

            console.log('latestPrice()');
            pi = await nestMining.latestPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('lastPriceList()');
            await nestMining.lastPriceList(usdt.address, 10);

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestMining.latestPriceAndTriggeredPriceInfo(usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });
            assert.equal(0, avgUsdtPrice.cmp(pi.triggeredAvgPrice));
            assert.equal(0, usdtSigmaSQ.cmp(pi.triggeredSigmaSQ));

            console.log('triggeredPrice2()');
            pi = await nestMining.triggeredPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                pripice: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString()
            });

            console.log('triggeredPriceInfo2()');
            pi = await nestMining.triggeredPriceInfo2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
                ntokenAvgPrice: pi.ntokenAvgPrice.toString(),
                ntokenSigmaSQ: pi.ntokenSigmaSQ.toString(),
            });
            assert.equal(0, avgUsdtPrice.cmp(pi.avgPrice));
            LOG('avgNestPrice: {avgNestPrice}, ntokenAvgPrice: {ntokenAvgPrice}', {
                avgNestPrice: avgNestPrice,
                ntokenAvgPrice: pi.ntokenAvgPrice
            });
            assert.equal(0, usdtSigmaSQ.cmp(pi.sigmaSQ));
            assert.equal(0, avgNestPrice.div(new BN('10000000000')).cmp(pi.ntokenAvgPrice.div(new BN('10000000000'))));

            LOG('nestSigmaSQ: {nestSigmaSQ}, ntokenSigmaSQ: {ntokenSigmaSQ}', { 
                nestSigmaSQ: nestSigmaSQ,
                ntokenSigmaSQ: pi.ntokenSigmaSQ
            });
            assert.equal(0, nestSigmaSQ.div(new BN(1000000)).cmp(pi.ntokenSigmaSQ.div(new BN(1000000))));

            LOG('avgNestPrice: {avgNestPrice}, ntokenAvgPrice: {ntokenAvgPrice}', { 
                avgNestPrice: avgNestPrice.toString(), 
                ntokenAvgPrice: pi.ntokenAvgPrice.toString() 
            });
            assert.equal(0, avgNestPrice.div(new BN('10000000000')).cmp(pi.ntokenAvgPrice.div(new BN('10000000000'))));

            console.log('latestPrice2()');
            pi = await nestMining.latestPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
            });
        }

        if (true) {
            
            // 直接调用价格
            console.log('triggeredPrice()')
            let price = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: price.blockNumber.toString(),
                price: price.price.toString()
            });
            await nestPriceFacade.setAddressFlag(account0, 1);

            console.log('triggeredPrice()');
            let pi = await nestPriceFacade.triggeredPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('findPrice()');
            await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10, account1, { value: ETHER(0.0137) });

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalRewards(nest.address),
                balance: await ethBalance(nestLedger.address)
            });

            assert.equal(0, ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1).cmp(await nestLedger.totalRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1).cmp(await ethBalance(nestLedger.address)));

            await nestMining.settle(usdt.address);
            console.log('余额:');
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalRewards(nest.address),
                balance: await ethBalance(nestLedger.address)
            });
            console.log('预期差:');
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1 * 11).sub(await nestLedger.totalRewards(nest.address)).toString(),
                balance: ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1 * 11).sub(await ethBalance(nestLedger.address)).toString()
            });

            assert.equal(0, ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1 * 11).cmp(await nestLedger.totalRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1 * 11).cmp(await ethBalance(nestLedger.address)));
        }

        if (true) {
            
            await nestPriceFacade.setConfig({
                // Single query fee（0.0001 ether, DIMI_ETHER). 100
                singleFee: 137,

                // Double query fee（0.0001 ether, DIMI_ETHER). 100
                doubleFee: 247,

                // The normal state flag of the call address. 0
                normalFlag: 0
            });
            await nestPriceFacade.setAddressFlag(account0, 0);
            
            // 直接调用价格
            console.log('triggeredPrice()')
            let price = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: price.blockNumber.toString(),
                price: price.price.toString()
            });
            await nestPriceFacade.setAddressFlag(account0, 0);

            console.log('triggeredPrice()');
            let pi = await nestPriceFacade.triggeredPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('findPrice()');
            await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10, account1, { value: ETHER(0.0137) });

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalRewards(nest.address),
                balance: await ethBalance(nestLedger.address)
            });

            assert.equal(0, ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).cmp(await nestLedger.totalRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).cmp(await ethBalance(nestLedger.address)));

            await nestMining.settle(usdt.address);
            console.log('余额:');
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalRewards(nest.address),
                balance: await ethBalance(nestLedger.address)
            });
            console.log('预期差:');
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).sub(await nestLedger.totalRewards(nest.address)).toString(),
                balance: ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).sub(await ethBalance(nestLedger.address)).toString()
            });

            assert.equal(0, ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).cmp(await nestLedger.totalRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).cmp(await ethBalance(nestLedger.address)));
            console.log('addressFlag: ' + await nestPriceFacade.getAddressFlag(account0));
        }

        if (true) {

            console.log(await nestPriceFacade.getConfig());
            LOG('usdtQuery: {usdtQuery}, nestQuery: {nestQuery}', {
                usdtQuery: await nestPriceFacade.getNestQuery(usdt.address),
                nestQuery: await nestPriceFacade.getNestQuery(nest.address),
            });
            await nestPriceFacade.setNestQuery(usdt.address, ntokenMining.address);
            await nestPriceFacade.setNestQuery(nest.address, ntokenMining.address);
            LOG('usdtQuery: {usdtQuery}, nestQuery: {nestQuery}', {
                usdtQuery: await nestPriceFacade.getNestQuery(usdt.address),
                nestQuery: await nestPriceFacade.getNestQuery(nest.address),
            });

            console.log('findPrice()');
            //await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });

            await nest.approve(ntokenMining.address, ETHER(100000000));
            await usdt.approve(ntokenMining.address, ETHER(100000000));
            //await ntokenMining.setNTokenAddress(usdt.address, usdt.address);
            await ntokenMining.post2(usdt.address, 30, USDT(512), ETHER(32768), { value: ETHER(60.1) });
            await skipBlocks(20);

            console.log('findPrice()');
            await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });
        }
    });
});
