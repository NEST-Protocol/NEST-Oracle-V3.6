const BN = require("bn.js");
//const { expect } = require('chai');
const { ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const hbtc = await artifacts.require('HBTC').deployed();
        const nhbtc = await artifacts.require('NHBTC').deployed();
        const nestLedger = await artifacts.require('NestLedger').deployed();
        const ntokenMining = await artifacts.require('NTokenMining').deployed();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
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
        // Show balances
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

        // Balance of account0
        assert.equal(0, balance0.balance.hbtc.cmp(HBTC('10000000')));
        assert.equal(0, balance0.balance.nest.cmp(ETHER('1000000000')));
        assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
        assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

        // Balance of nestMining
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
            // 1. Post a price sheet
            console.log('1. Post a price sheet');
            let receipt = await ntokenMining.post(hbtc.address, 10, HBTC(256), { value: ETHER(10.1) });

            console.log(receipt);
            balance0 = await showBalance(account0, 'After price posted');
            
            // Balance of account0
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 10)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nhbtc.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

            // Balance of nestMining
            assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(10.0)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(256 * 10)));
            assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(ETHER(0)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000 + 100000)));

            // Balance of nestLedger
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await hbtc.balanceOf(nestLedger.address)).cmp(HBTC(0)));
            assert.equal(0, (await nhbtc.balanceOf(nestLedger.address)).cmp(ETHER(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));

            // Check ledger for ntoken
            console.log('nest reward: ' + (await nestLedger.totalETHRewards(nest.address)).toString());
            console.log('nhbtc reward: ' + (await nestLedger.totalETHRewards(nhbtc.address)).toString());
            assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(ETHER(0.1 * 0.2)));
            assert.equal(0, (await nestLedger.totalETHRewards(nhbtc.address)).cmp(ETHER(0.1 * 0.8)));
            
            mined = nHBTC(10 * 4 * (0.95 + 0.05));
            prevBlockNumber = receipt.receipt.blockNumber;

            await skipBlocks(20);

            // 2. Close price sheet
            console.log('2. Close price sheet');
            receipt = await ntokenMining.close(hbtc.address, 0);
            console.log(receipt);

            balance0 = await showBalance(account0, 'After price sheet closed');

            // Balance of account0
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 10)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(256 * 10)));
            assert.equal(0, balance0.pool.nhbtc.cmp(mined));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000)));

            // Balance of nestMining
            assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(256 * 10)));
            //assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(nHBTC(10 * 4 * 1.00)));
            assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(nHBTC(0)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000 + 100000)));

            // Balance of nestLedger
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await hbtc.balanceOf(nestLedger.address)).cmp(HBTC(0)));
            assert.equal(0, (await nhbtc.balanceOf(nestLedger.address)).cmp(ETHER(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));

            // Check ledger for ntoken
            assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(ETHER(0.1 * 0.2)));
            assert.equal(0, (await nestLedger.totalETHRewards(nhbtc.address)).cmp(ETHER(0.1 * 0.8)));

            // 3. withdraw
            await ntokenMining.withdraw(hbtc.address, await ntokenMining.balanceOf(hbtc.address, account0));
            await ntokenMining.withdraw(nest.address, await ntokenMining.balanceOf(nest.address, account0));
            await ntokenMining.withdraw(nhbtc.address, await ntokenMining.balanceOf(nhbtc.address, account0));
            
            balance0 = await showBalance(account0, 'After withdrawn');

            // Balance of account0
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(mined));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nhbtc.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

            // Balance of nestMining
            assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(0)));
            //assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(nHBTC(10 * 4 * 0.05)));
            assert.equal(0, (await nhbtc.balanceOf(ntokenMining.address)).cmp(nHBTC(0)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000)));

            // Balance of nestLedger
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await hbtc.balanceOf(nestLedger.address)).cmp(HBTC(0)));
            assert.equal(0, (await nhbtc.balanceOf(nestLedger.address)).cmp(ETHER(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));

            // Check ledger for ntoken
            assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(ETHER(0.1 * 0.2)));
            assert.equal(0, (await nestLedger.totalETHRewards(nhbtc.address)).cmp(ETHER(0.1 * 0.8)));

            LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            await skipBlocks(18);
            LOG('blockNumber: ' + await web3.eth.getBlockNumber());

            // Show price
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, avgPrice={avgPrice}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }
            await ntokenMining.stat(hbtc.address);
            // Show price
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, avgPrice={avgPrice}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            console.log('3. Post a price sheet 2');
            receipt = await ntokenMining.post(hbtc.address, 10, HBTC(258), { value: ETHER(10.1) });
            console.log(receipt);

            await skipBlocks(20);
            await ntokenMining.stat(hbtc.address);
            // Show price
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, avgPrice={avgPrice}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            console.log('4. Post a price sheet 3');
            receipt = await ntokenMining.post(hbtc.address, 10, HBTC(234), { value: ETHER(10.1) });
            console.log(receipt);

            await skipBlocks(20);
            await ntokenMining.stat(hbtc.address);
            
            // Show price
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, avgPrice={avgPrice}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            console.log('5. Close price sheet 2');
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
