
const BN = require("bn.js");
const $hcj = require("./hcore.js");

const NestMining = artifacts.require("NestMining");
const TestERC20 = artifacts.require("TestERC20");
const IBNEST = artifacts.require("IBNEST");
const NestDAO = artifacts.require("NestDAO");

const USDT = new BN('1000000');
const GWEI = new BN('1000000000');
const ETHER = new BN('1000000000000000000');

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
        // 创建nestdao合约
        let nestDao = await NestDAO.new(nest.address);
        // 创建nest挖矿合约
        let nestMining = await NestMining.new(nest.address, nestDao.address);
        
        // 添加ntoken映射
        await nestDao.addNTokenMapping(usdt.address, nest.address);
        // 初始化usdt余额
        await usdt.transfer(account0, new BN('10000000').mul(USDT), { from: account1 });
        await usdt.transfer(account1, new BN('10000000').mul(USDT), { from: account1 });
        await nest.transfer(nestMining.address, new BN('9000000000').mul(ETHER));

        // 显示余额
        const showBalance = async function(account, msg) {
            console.log(msg);
            let balances = {
                balance: {
                    eth: await ethBalance(account),
                    usdt: await usdt.balanceOf(account),
                    nest: await nest.balanceOf(account)
                },
                freezen: {
                    eth: new BN('0'),
                    usdt: await nestMining.balanceOf(usdt.address, account),
                    nest: await nestMining.balanceOf(nest.address, account)
                }
            };

            LOG('balance: {eth}eth, {nest}nest, {usdt}usdt', balances.balance);
            LOG('freezen: {eth}eth, {nest}nest, {usdt}usdt', balances.freezen);

            return balances;
        };

        let balance0 = await showBalance(account0, 'account0');
        let balance1 = await showBalance(account1, 'account1');
        assert.equal(balance0.balance.usdt.cmp(new BN('10000000').mul(USDT)), 0);
        assert.equal(balance0.balance.nest.cmp(new BN('1000000000').mul(ETHER)), 0);

        assert.equal(balance0.freezen.usdt.cmp(new BN('0').mul(USDT)), 0);
        assert.equal(balance0.freezen.nest.cmp(new BN('0').mul(ETHER)), 0);

        assert.equal(balance1.balance.usdt.cmp(new BN('10000000').mul(USDT)), 0);

        await nest.approve(nestMining.address, new BN('10000000000').mul(ETHER));
        await usdt.approve(nestMining.address, new BN('10000000').mul(USDT));

        let prevBlockNumber = 0;
        let minedNest = new BN(0);
        {
            // 发起报价
            console.log('发起报价');
            //let receipt = await nestMining.post(usdt.address, 30, new BN('1560').mul(USDT), new BN('1500000').mul(ETHER), { value: new BN('30099000000000000000') });
            let receipt = await nestMining.post(usdt.address, 30, new BN('1560').mul(USDT), { value: new BN('30099000000000000000') });
            console.log(receipt);
            prevBlockNumber = receipt.receipt.blockNumber;
            balance0 = await showBalance(account0, '发起一次报价后');
            assert.equal(balance0.balance.usdt.cmp(new BN('10000000').mul(USDT).sub(new BN('1560').mul(new BN('30')).mul(USDT))), 0);
            assert.equal(balance0.balance.nest.cmp(new BN('1000000000').mul(ETHER).sub(new BN('100000').mul(ETHER))), 0);

            assert.equal(balance0.freezen.usdt.cmp(new BN('0').mul(new BN('30')).mul(USDT)), 0);
            assert.equal(balance0.freezen.nest.cmp(minedNest), 0);
            
            minedNest = new BN('400').mul(new BN('10')).mul(ETHER);
            receipt = await nestMining.close(usdt.address, 0);
            console.log(receipt);
            balance0 = await showBalance(account0, '关闭报价单后');
            assert.equal(balance0.balance.usdt.cmp(new BN('10000000').mul(USDT).sub(new BN('1560').mul(new BN('30')).mul(USDT))), 0);
            assert.equal(balance0.balance.nest.cmp(new BN('1000000000').mul(ETHER).sub(new BN('100000').mul(ETHER))), 0);

            assert.equal(balance0.freezen.usdt.cmp(new BN('1560').mul(new BN('30')).mul(USDT)), 0);
            assert.equal(balance0.freezen.nest.cmp(new BN('100000').mul(ETHER).add(minedNest)), 0);
            assert.equal((await ethBalance(nestMining.address)).cmp(new BN('99000000000000000')), 0);
            assert.equal((await ethBalance(nestDao.address)).cmp(new BN('0')), 0);
        }

        for (var i = 1; i < 15; ++i) {
            // 发起报价
            console.log('发起报价' + i);
            //let receipt = await nestMining.post(usdt.address, 30, new BN('1560').mul(USDT), new BN('1500000').mul(ETHER), { value: new BN('30099000000000000000') });
            let receipt = await nestMining.post(usdt.address, 30, new BN('1560').mul(USDT), { value: new BN('30099000000000000000') });
            console.log(receipt);
            balance0 = await showBalance(account0, '发起一次报价后' + i);
            assert.equal(balance0.balance.usdt.cmp(new BN('10000000').mul(USDT).sub(new BN('1560').mul(new BN('30')).mul(USDT))), 0);
            assert.equal(balance0.balance.nest.cmp(new BN('1000000000').mul(ETHER).sub(new BN('100000').mul(ETHER))), 0);
    
            assert.equal(balance0.freezen.usdt.cmp(new BN('0').mul(new BN('30')).mul(USDT)), 0);
            assert.equal(balance0.freezen.nest.cmp(minedNest), 0);
            
            let minedInfo = await nestMining.getMinedBlocks(usdt.address, i);
            LOG('minedBlocks={minedBlocks}, count={count}', minedInfo);
            minedNest = minedNest.add(new BN(receipt.receipt.blockNumber - prevBlockNumber).mul(new BN('400')).mul(ETHER));
            prevBlockNumber = receipt.receipt.blockNumber;

            receipt = await nestMining.close(usdt.address, i);
            console.log(receipt);
            balance0 = await showBalance(account0, '关闭报价单后' + i);
            assert.equal(balance0.balance.usdt.cmp(new BN('10000000').mul(USDT).sub(new BN('1560').mul(new BN('30')).mul(USDT))), 0);
            assert.equal(balance0.balance.nest.cmp(new BN('1000000000').mul(ETHER).sub(new BN('100000').mul(ETHER))), 0);
    
            assert.equal(balance0.freezen.usdt.cmp(new BN('1560').mul(new BN('30')).mul(USDT)), 0);
            //console.log((balance0.freezen.nest.toString()));
            //console.log(minedNest.toString());
            assert.equal(balance0.freezen.nest.cmp(new BN('100000').mul(ETHER).add(minedNest)), 0);
            assert.equal((await ethBalance(nestMining.address)).cmp(new BN('99000000000000000').mul(new BN(i + 1))), 0);
            assert.equal((await ethBalance(nestDao.address)).cmp(new BN('0')), 0);
        }

        {
            // 发起报价
            console.log('发起报价');
            //let receipt = await nestMining.post(usdt.address, 30, new BN('1560').mul(USDT), new BN('1500000').mul(ETHER), { value: new BN('30099000000000000000') });
            let receipt = await nestMining.post(usdt.address, 30, new BN('1560').mul(USDT), { value: new BN('30099000000000000000') });
            console.log(receipt);
            balance0 = await showBalance(account0, '发起一次报价后');
            assert.equal(balance0.balance.usdt.cmp(new BN('10000000').mul(USDT).sub(new BN('1560').mul(new BN('30')).mul(USDT))), 0);
            assert.equal(balance0.balance.nest.cmp(new BN('1000000000').mul(ETHER).sub(new BN('100000').mul(ETHER))), 0);
    
            assert.equal(balance0.freezen.usdt.cmp(new BN('0').mul(new BN('30')).mul(USDT)), 0);
            assert.equal(balance0.freezen.nest.cmp(minedNest), 0);
            
            minedNest = minedNest.add(new BN(receipt.receipt.blockNumber - prevBlockNumber).mul(new BN('400')).mul(ETHER));
            prevBlockNumber = receipt.receipt.blockNumber;

            receipt = await nestMining.close(usdt.address, 15);
            console.log(receipt);
            balance0 = await showBalance(account0, '关闭报价单后');
            assert.equal(balance0.balance.usdt.cmp(new BN('10000000').mul(USDT).sub(new BN('1560').mul(new BN('30')).mul(USDT))), 0);
            assert.equal(balance0.balance.nest.cmp(new BN('1000000000').mul(ETHER).sub(new BN('100000').mul(ETHER))), 0);
    
            assert.equal(balance0.freezen.usdt.cmp(new BN('1560').mul(new BN('30')).mul(USDT)), 0);
            assert.equal(balance0.freezen.nest.cmp(new BN('100000').mul(ETHER).add(minedNest)), 0);
            assert.equal((await ethBalance(nestMining.address)).cmp(new BN('99000000000000000').mul(new BN(0))), 0);
            assert.equal((await ethBalance(nestDao.address)).cmp(new BN('99000000000000000').mul(new BN(16))), 0);

            assert.equal((await nestDao.totalRewards(nest.address)).cmp(new BN('99000000000000000').mul(new BN(16))), 0);
        }

        // 取回资产
        await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account0));
        await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account0));

        await showBalance(account0, 'account0');
        await showBalance(nestMining.address, 'nestMining');
    });
});
