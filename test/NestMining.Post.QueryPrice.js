
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
const Nest_NToken = artifacts.require("Nest_NToken");
const Nest_3_VoteFactory = artifacts.require("Nest_3_VoteFactory");
const SetQueryPrice = artifacts.require("SetQueryPrice");

//const USDT = function(value) { return new BN('1000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
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

        // 部署老版本合约
        let nest = await IBNEST.new();
        let nest_3_VoteFactory = await Nest_3_VoteFactory.new();
        let nhbtc = await Nest_NToken.new('nHBTC', 'nHBTC', nest_3_VoteFactory.address, account1); //(string memory _name, string memory _symbol, address voteFactory, address bidder)

        // 部署3.6合约
        // const NestGovernance = artifacts.require("NestGovernance");
        let nestGovernance = await NestGovernance.new();

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

        // const NNIncome = artifacts.require("NNIncome");
        //let nnIncome = await NNIncome.new();

        // const NToken = artifacts.require("NToken");
        // const NTokenController = artifacts.require("NTokenController");
        let nTokenController = await NTokenController.new(nest.address);

        // 设置内置合约地址
        await nestGovernance.setBuiltinAddress(
            nest.address,
            '0x0000000000000000000000000000000000000000', //nestNodeAddress,
            nestLedger.address,
            nestMining.address,
            nestPriceFacade.address,
            nestVote.address,
            nestMining.address, //nestQueryAddress,
            '0x0000000000000000000000000000000000000000', //nnIncomeAddress,
            nTokenController.address //nTokenControllerAddress
        );
        // 添加redeeming合约映射
        await nestGovernance.register("nest.dao.redeeming", nestRedeeming.address);

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
            // -- nest相关配置
            // nest报价的eth单位。30
            // 可以通过将postEthUnit设置为0来停止报价和吃单（关闭和取回不受影响）
            postEthUnit: 30,

            // nest报价的手续费比例（万分制，DIMI_ETHER）。33
            postFeeRate: 33,

            // nest吃单的手续费比例（万分制，DIMI_ETHER）。0
            biteFeeRate: 0,
            
            // -- ntoken相关配置
            // ntoken报价的eth单位。30
            // 可以通过将postEthUnit设置为0来停止报价和吃单（关闭和取回不受影响）
            ntokenPostEthUnit: 30,

            // ntoken报价的手续费比例（万分制，DIMI_ETHER）。33
            ntokenPostFeeRate: 33,

            // ntoken吃单的手续费比例（万分制，DIMI_ETHER）。0
            ntokenBiteFeeRate: 0,

            // 矿工挖到nest的比例（万分制）。8000
            minerNestReward: 8000, // MINER_NEST_REWARD_PERCENTAGE
            
            // 矿工挖到的ntoken比例，只对3.0版本创建的ntoken有效（万分之）。9500
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
            nestPledgeNest: 100
        });

        await nestPriceFacade.setConfig({
            // 单轨询价费用。0.01ether
            singleFee: '10000000000000000',
            // 双轨询价费用。0.01ether
            doubleFee: '10000000000000000',
            // 调用地址的正常状态标记。0
            normalFlag: 0
        });

        await nestRedeeming.setConfig({

            // 单轨询价费用。0.01ether
            fee: '10000000000000000',
    
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
        // 给投票合约授权
        await nestGovernance.setGovernance(nestVote.address, 1);

        // 修改nHBTC信息
        await nest_3_VoteFactory.addContractAddress("nest.nToken.offerMain", nestMining.address);
        await nhbtc.changeMapping(nest_3_VoteFactory.address);

        // 添加ntoken映射
        // 初始化usdt余额
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
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
        assert.equal(0, balance1.balance.hbtc.cmp(HBTC('10000000')));

        // account0余额
        assert.equal(0, balance0.balance.hbtc.cmp(HBTC('10000000')));
        assert.equal(0, balance0.balance.nest.cmp(ETHER('1000000000')));
        assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
        assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

        // nestMining余额
        assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0)));
        assert.equal(0, (await hbtc.balanceOf(nestMining.address)).cmp(HBTC(0)));
        assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000)));

        await nest.approve(nestMining.address, ETHER('1000000000'));
        await hbtc.approve(nestMining.address, HBTC('10000000'));
        await nest.approve(nestMining.address, ETHER('1000000000'), { from: account1 });
        await hbtc.approve(nestMining.address, HBTC('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let mined = nHBTC(0);
        
        {
            // 发起报价
            console.log('发起报价');
            let receipt = await nestMining.post(hbtc.address, 30, HBTC(256), { value: ETHER(30.099) });
            console.log(receipt);
            balance0 = await showBalance(account0, '发起一次报价后');
            
            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nest.cmp(mined));

            // nestMining余额
            //assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(30.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(nestMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000)));
            
            mined = nHBTC(10 * 4 * 0.95);
            prevBlockNumber = receipt.receipt.blockNumber;

            await skipBlocks(20);

            // 关闭报价单
            receipt = await nestMining.close(hbtc.address, 0);

            console.log(receipt);
            balance0 = await showBalance(account0, '关闭报价单后');

            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(256 * 30)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000)));
            assert.equal(0, balance0.pool.nhbtc.cmp(mined));

            // nestMining余额
            //assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(nestMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000)));

            // nestLedger余额
            //assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0 + 0.099)));

            // 取回
            await nestMining.withdraw(hbtc.address, await nestMining.balanceOf(hbtc.address, account0));
            await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account0));
            await nestMining.withdraw(nhbtc.address, await nestMining.balanceOf(nhbtc.address, account0));
            
            balance0 = await showBalance(account0, '取回后');

            //assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(nestMining.address)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000)));
            
            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(mined));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.nhbtc.cmp(nHBTC(0)));

            LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            await skipBlocks(18);
            LOG('blockNumber: ' + await web3.eth.getBlockNumber());

            // 查看价格
            {
                let latestPrice = await nestMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPrice = await nestMining.triggeredPrice(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}', triggeredPrice);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }
            await nestMining.stat(hbtc.address);
            // 查看价格
            {
                let latestPrice = await nestMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await nestMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            receipt = await nestMining.post(hbtc.address, 30, HBTC(2570), { value: ETHER(30.099) });
            console.log(receipt);

            await skipBlocks(20);
            await nestMining.stat(hbtc.address);
            // 查看价格
            {
                let latestPrice = await nestMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await nestMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            receipt = await nestMining.close(hbtc.address, 1);
            console.log(receipt);

            // 调用价格
            console.log('调用价格：');
            let callPrice = await nestPriceFacade.triggeredPriceInfo(hbtc.address, { value: new BN('10000000000000000') });
            console.log(callPrice)
        }
    });
});
