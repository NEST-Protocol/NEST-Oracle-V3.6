
const BN = require("bn.js");
const $hcj = require("./hcore.js");

const NestMining = artifacts.require("NestMining");
const NTokenController = artifacts.require("NTokenController");
const TestERC20 = artifacts.require("TestERC20");
const IBNEST = artifacts.require("IBNEST");
const NestDAO = artifacts.require("NestDAO");

const USDT = function(value) { return new BN('1000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const GWEI = function(value) { return new BN('1000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const ETHER = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }

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

        // 创建nest代币合约
        let nest = await IBNEST.new();
        // 创建usdt代币合约
        let usdt = await TestERC20.new('usdt', 'usdt', 6);
        // 创建NestDAO合约
        let nestDao = await NestDAO.new(nest.address);
        // 创建NTokenController合约
        let nTokenController = await NTokenController.new();
        // 创建nest挖矿合约
        let nestMining = await NestMining.new(nest.address, nestDao.address, nTokenController.address);
        await nTokenController.initialize(nestDao.address);
        await nestMining.initialize(nestDao.address);
        await nTokenController.setAddress(nestMining.address);
        
        // 添加ntoken映射
        await nTokenController.addNTokenMapping(usdt.address, nest.address);
        // 初始化usdt余额
        await usdt.transfer(account0, USDT('10000000'), { from: account1 });
        await usdt.transfer(account1, USDT('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

        //await web3.eth.sendTransaction({ from: account0, to: account1, value: new BN('200').mul(ETHER)});

        // 显示余额
        const getBalance = async function(account) {
            let balances = {
                balance: {
                    eth: await ethBalance(account),
                    usdt: await usdt.balanceOf(account),
                    nest: await nest.balanceOf(account)
                },
                pool: {
                    eth: ETHER(0),
                    usdt: await nestMining.balanceOf(usdt.address, account),
                    nest: await nestMining.balanceOf(nest.address, account)
                }
            };

            return balances;
        };
        const showBalance = async function(account, msg) {
            console.log(msg);
            let balances = await getBalance(account);

            LOG('balance: {eth}eth, {nest}nest, {usdt}usdt', balances.balance);
            LOG('pool: {eth}eth, {nest}nest, {usdt}usdt', balances.pool);

            return balances;
        };

        let balance0 = await showBalance(account0, 'account0');
        let balance1 = await showBalance(account1, 'account1');
        assert.equal(0, balance1.balance.usdt.cmp(USDT('10000000')));

        // account0余额
        assert.equal(0, balance0.balance.usdt.cmp(USDT('10000000')));
        assert.equal(0, balance0.balance.nest.cmp(ETHER('1000000000')));
        assert.equal(0, balance0.pool.usdt.cmp(USDT(0)));
        assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

        // nestMining余额
        assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0)));
        assert.equal(0, (await usdt.balanceOf(nestMining.address)).cmp(USDT(0)));
        assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000)));

        await nest.approve(nestMining.address, ETHER('1000000000'));
        await usdt.approve(nestMining.address, USDT('10000000'));
        await nest.approve(nestMining.address, ETHER('1000000000'), { from: account1 });
        await usdt.approve(nestMining.address, USDT('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let minedNest = ETHER(0);
        
        {
            // 发起报价
            console.log('发起报价');
            let receipt = await nestMining.post(usdt.address, 30, USDT(1560), { value: ETHER(30.099) });
            console.log(receipt);
            balance0 = await showBalance(account0, '发起一次报价后');
            
            // account0余额
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(0)));
            assert.equal(0, balance0.pool.nest.cmp(minedNest));

            // nestMining余额
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(30.099)));
            assert.equal(0, (await usdt.balanceOf(nestMining.address)).cmp(USDT(1560 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000)));
            
            minedNest = ETHER(10 * 400);
            prevBlockNumber = receipt.receipt.blockNumber;

            // 关闭报价单
            receipt = await nestMining.close(usdt.address, 0);

            console.log(receipt);
            balance0 = await showBalance(account0, '关闭报价单后');

            // account0余额
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(1560 * 30)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000).add(minedNest)));

            // nestMining余额
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0.099)));
            assert.equal(0, (await usdt.balanceOf(nestMining.address)).cmp(USDT(1560 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000)));

            // nestDao余额
            assert.equal(0, (await ethBalance(nestDao.address)).cmp(ETHER(0)));

            // 取回
            await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account0));
            await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account0));
            balance0 = await showBalance(account0, '取回后');

            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0.099)));
            assert.equal(0, (await usdt.balanceOf(nestMining.address)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000).sub(minedNest)));

            LOG('blockNumber: ' + await nestMining.getBlockNumber());
            for (var i = 0; i < 18; ++i) {
                await web3.eth.sendTransaction({ from: account0, to: account0, value: ETHER(1)});
            }
            LOG('blockNumber: ' + await nestMining.getBlockNumber());

            // 查看价格
            {
                let latestPrice = await nestMining.latestPrice(usdt.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPrice = await nestMining.triggeredPrice(usdt.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}', triggeredPrice);
                LOG('blockNumber: ' + await nestMining.getBlockNumber());
            }
            await nestMining.stat(usdt.address);
            // 查看价格
            {
                let latestPrice = await nestMining.latestPrice(usdt.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPrice = await nestMining.triggeredPrice(usdt.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}', triggeredPrice);
                LOG('blockNumber: ' + await nestMining.getBlockNumber());
            }
        }
    });
});
