const BN = require("bn.js");
const { expect } = require('chai');
const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // 初始化usdt余额
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(ntokenMining.address, ETHER('8000000000'));

        //await web3.eth.sendTransaction({ from: account0, to: account1, value: new BN('200').mul(ETHER)});
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
                    hbtc: await ntokenMining.balanceOf(hbtc.address, account),
                    nhbtc: await ntokenMining.balanceOf(nhbtc.address, account),
                    nest: await ntokenMining.balanceOf(nest.address, account)
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
        assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0)));
        assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(0)));
        assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000)));

        await nest.approve(ntokenMining.address, ETHER('1000000000'));
        await hbtc.approve(ntokenMining.address, HBTC('10000000'));
        await nest.approve(ntokenMining.address, ETHER('1000000000'), { from: account1 });
        await hbtc.approve(ntokenMining.address, HBTC('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let mined = nHBTC(0);
        
        {
            // 1. 发起报价
            console.log('1. 发起报价');
            let receipt = await ntokenMining.post(hbtc.address, 30, HBTC(256), { value: ETHER(30.1) });

            console.log(receipt);
            balance0 = await showBalance(account0, '发起一次报价后');
            
            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nhbtc.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

            // nestMining余额
            assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(30.0)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(ETHER(0)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000 + 100000)));

            // nestLedger余额
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await hbtc.balanceOf(nestLedger.address)).cmp(HBTC(0)));
            assert.equal(0, (await nhbtc.balanceOf(nestLedger.address)).cmp(ETHER(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));

            // 检查ntoken账本
            console.log('nest reward: ' + (await nestLedger.totalRewards(nest.address)).toString());
            console.log('nhbtc reward: ' + (await nestLedger.totalRewards(nhbtc.address)).toString());
            assert.equal(0, (await nestLedger.totalRewards(nest.address)).cmp(ETHER(0.1 * 0.2)));
            assert.equal(0, (await nestLedger.totalRewards(nhbtc.address)).cmp(ETHER(0.1 * 0.8)));
            
            mined = nHBTC(10 * 4 * 0.95);
            prevBlockNumber = receipt.receipt.blockNumber;

            await skipBlocks(20);

            // 2. 关闭报价单
            console.log('2. 关闭报价单');
            receipt = await ntokenMining.close(hbtc.address, 0);
            console.log(receipt);

            balance0 = await showBalance(account0, '关闭报价单后');

            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(256 * 30)));
            assert.equal(0, balance0.pool.nhbtc.cmp(mined));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000)));

            // nestMining余额
            assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(256 * 30)));
            //assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(nHBTC(10 * 4 * 1.00)));
            assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(nHBTC(0)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000 + 100000)));

            // nestLedger余额
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await hbtc.balanceOf(nestLedger.address)).cmp(HBTC(0)));
            assert.equal(0, (await nhbtc.balanceOf(nestLedger.address)).cmp(ETHER(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));

            // 检查ntoken账本
            assert.equal(0, (await nestLedger.totalRewards(nest.address)).cmp(ETHER(0.1 * 0.2)));
            assert.equal(0, (await nestLedger.totalRewards(nhbtc.address)).cmp(ETHER(0.1 * 0.8)));

            // 3. 取回
            await ntokenMining.withdraw(hbtc.address, await ntokenMining.balanceOf(hbtc.address, account0));
            await ntokenMining.withdraw(nest.address, await ntokenMining.balanceOf(nest.address, account0));
            await ntokenMining.withdraw(nhbtc.address, await ntokenMining.balanceOf(nhbtc.address, account0));
            
            balance0 = await showBalance(account0, '取回后');

            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(mined));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nhbtc.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

            // nestMining余额
            assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(0)));
            //assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(nHBTC(10 * 4 * 0.05)));
            assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(nHBTC(0)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000)));

            // nestLedger余额
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await hbtc.balanceOf(nestLedger.address)).cmp(HBTC(0)));
            assert.equal(0, (await nhbtc.balanceOf(nestLedger.address)).cmp(ETHER(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));

            // 检查ntoken账本
            assert.equal(0, (await nestLedger.totalRewards(nest.address)).cmp(ETHER(0.1 * 0.2)));
            assert.equal(0, (await nestLedger.totalRewards(nhbtc.address)).cmp(ETHER(0.1 * 0.8)));

            LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            await skipBlocks(18);
            LOG('blockNumber: ' + await web3.eth.getBlockNumber());

            // 查看价格
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, avgPrice={avgPrice}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }
            await ntokenMining.stat(hbtc.address);
            // 查看价格
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, avgPrice={avgPrice}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            console.log('3. 第二次报价');
            receipt = await ntokenMining.post(hbtc.address, 30, HBTC(258), { value: ETHER(30.1) });
            console.log(receipt);

            await skipBlocks(20);
            await ntokenMining.stat(hbtc.address);
            // 查看价格
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, avgPrice={avgPrice}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            console.log('4. 第三次报价');
            receipt = await ntokenMining.post(hbtc.address, 30, HBTC(234), { value: ETHER(30.1) });
            console.log(receipt);

            await skipBlocks(20);
            await ntokenMining.stat(hbtc.address);
            
            // 查看价格
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, avgPrice={avgPrice}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            console.log('5. 第二次关闭');
            receipt = await ntokenMining.close(hbtc.address, 1);
            console.log(receipt);

            console.log('blockNumber: ' + (await web3.eth.getBlockNumber() - 0));
            let pi = await ntokenMining.findPrice(hbtc.address, await web3.eth.getBlockNumber() - 0);
            LOG('blockNumber: {blockNumber}, price: {price}', pi);

            LOG('------------------------');
            let arr = await ntokenMining.lastPriceList(hbtc.address, 3);
            for (var i in arr) {
                console.log(arr[i].toString());
            }

            LOG('------------------------');
            arr = await ntokenMining.lastPriceList(hbtc.address, 4);
            for (var i in arr) {
                console.log(arr[i].toString());
            }

            LOG('------------------------');
            arr = await ntokenMining.lastPriceList(hbtc.address, 5);
            for (var i in arr) {
                console.log(arr[i].toString());
            }
        }
    });
});
