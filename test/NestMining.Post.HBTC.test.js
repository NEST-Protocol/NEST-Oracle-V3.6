
const BN = require("bn.js");
const $hcj = require("./hcore.js");

const NestMining = artifacts.require("NestMining");
const NTokenController = artifacts.require("NTokenController");
const TestERC20 = artifacts.require("TestERC20");
const IBNEST = artifacts.require("IBNEST");
const Nest_NToken = artifacts.require("Nest_NToken");
const Nest_3_VoteFactory = artifacts.require("Nest_3_VoteFactory");
const NestGovernance = artifacts.require("NestGovernance");
const NestLedger = artifacts.require("NestLedger");

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

        // 创建Nest_3_VoteFactory合约
        let nest_3_VoteFactory = await Nest_3_VoteFactory.new();
        // 创建nest代币合约
        let nest = await IBNEST.new();
        // 创建usdt代币合约
        let hbtc = await TestERC20.new('HBTC', 'HBTC', 18);
        // 创建nhbtc合约
        let nhbtc = await Nest_NToken.new('nHBTC', 'nHBTC', nest_3_VoteFactory.address, account1); //(string memory _name, string memory _symbol, address voteFactory, address bidder)
        // 创建NestDAO合约
        //let nestDao = await NestDAO.new(nest.address);
        // 创建NestGovernance合约
        let nestGovernance = await NestGovernance.new();
        // 创建NestGovernance合约
        let nestLedger = await NestLedger.new(nest.address);
        
        // 创建NTokenController合约
        let nTokenController = await NTokenController.new(nest.address);
        // 创建nest挖矿合约
        let nestMining = await NestMining.new(nest.address);
        //await nTokenController.initialize(nestDao.address);
        //await nestMining.initialize(nestDao.address);
        
        await nestGovernance.setBuiltinAddress(
            nest.address,
            nestLedger.address,
            nestMining.address,
            '0x0000000000000000000000000000000000000000', //nestPriceFacadeAddress,
            '0x0000000000000000000000000000000000000000', //nestVoteAddress,
            nestMining.address, //nestQueryAddress,
            '0x0000000000000000000000000000000000000000', //nnIncomeAddress,
            nTokenController.address //nTokenControllerAddress
        );
        /*
                address nestTokenAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress*/

        await nTokenController.update(nestGovernance.address);
        await nestMining.update(nestGovernance.address);

        await nest_3_VoteFactory.addContractAddress("nest.nToken.offerMain", nestMining.address);
        await nhbtc.changeMapping(nest_3_VoteFactory.address);

        await nestMining.setConfig({
            // 报价的eth单位。30
            postEthUnit: 30, 
            // 报价的手续费比例（万分之）。33
            postFeeRate: 33,
            // 报价抵押nest数量单位（千）。100
            nestPledgeNest: 100,
            // 吃单资产翻倍次数。4
            maxBiteNestedLevel: 4,
            // 价格生效区块间隔。20
            priceEffectSpan: 20,
            // 矿工挖到nest的比例（万分制）。8000
            minerNestReward: 8000, // MINER_NEST_REWARD_PERCENTAGE
            // 矿工挖到的ntoken比例，只对3.0版本创建的ntoken有效（万分之）。9500
            minerNTokenReward: 9500
        });

        console.log(await nestMining.getConfig());

        // 添加ntoken映射
        await nTokenController.addNTokenMapping(hbtc.address, nhbtc.address);
        // 初始化usdt余额
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

        //await web3.eth.sendTransaction({ from: account0, to: account1, value: new BN('200').mul(ETHER)});

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
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(30.099)));
            assert.equal(0, (await hbtc.balanceOf(nestMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000)));
            
            mined = nHBTC(10 * 4 * 0.95);
            prevBlockNumber = receipt.receipt.blockNumber;

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
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0.099)));
            assert.equal(0, (await hbtc.balanceOf(nestMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000)));

            // nestLedger余额
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0)));

            // 取回
            await nestMining.withdraw(hbtc.address, await nestMining.balanceOf(hbtc.address, account0));
            await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account0));
            await nestMining.withdraw(nhbtc.address, await nestMining.balanceOf(nhbtc.address, account0));
            
            balance0 = await showBalance(account0, '取回后');

            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0.099)));
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
            for (var i = 0; i < 18; ++i) {
                await web3.eth.sendTransaction({ from: account0, to: account0, value: ETHER(1)});
            }
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
                let triggeredPrice = await nestMining.triggeredPrice(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}', triggeredPrice);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }
        }
    });
});
