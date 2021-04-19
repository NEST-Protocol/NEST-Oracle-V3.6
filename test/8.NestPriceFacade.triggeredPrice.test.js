const BN = require("bn.js");
const { expect } = require('chai');
const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(ntokenMining.address, ETHER('8000000000'));

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
            // Post a price sheet
            console.log('Post as price sheet');
            let receipt = await ntokenMining.post(hbtc.address, 30, HBTC(256), { value: ETHER(30.1) });
            console.log(receipt);
            balance0 = await showBalance(account0, 'After price posted');
            
            // Balance of account0
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nest.cmp(mined));

            // Balance of nestMining
            //assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(30.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000 + 100000)));
            
            mined = nHBTC(10 * 4 * 0.95);
            prevBlockNumber = receipt.receipt.blockNumber;

            await skipBlocks(20);

            // Close price sheet
            receipt = await ntokenMining.close(hbtc.address, 0);

            console.log(receipt);
            balance0 = await showBalance(account0, 'After price sheet closed');

            // Balance of account0
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(256 * 30)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000)));
            assert.equal(0, balance0.pool.nhbtc.cmp(mined));

            // Balance of nestMining
            //assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000 + 100000)));

            // Balance of nestLedger
            //assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0 + 0.099)));

            // Withdraw
            await ntokenMining.withdraw(hbtc.address, await ntokenMining.balanceOf(hbtc.address, account0));
            await ntokenMining.withdraw(nest.address, await ntokenMining.balanceOf(nest.address, account0));
            await ntokenMining.withdraw(nhbtc.address, await ntokenMining.balanceOf(nhbtc.address, account0));
            
            balance0 = await showBalance(account0, 'After withdrawn');

            //assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000)));
            
            // Balance of account0
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(mined));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.nhbtc.cmp(nHBTC(0)));

            LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            await skipBlocks(18);
            LOG('blockNumber: ' + await web3.eth.getBlockNumber());

            // Show price
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPrice = await ntokenMining.triggeredPrice(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}', triggeredPrice);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }
            await ntokenMining.stat(hbtc.address);
            // Show price
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            receipt = await ntokenMining.post(hbtc.address, 30, HBTC(2570), { value: ETHER(30.1) });
            console.log(receipt);

            await skipBlocks(20);
            await ntokenMining.stat(hbtc.address);
            // Show price
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            receipt = await ntokenMining.close(hbtc.address, 1);
            console.log(receipt);

            // Call the price
            console.log('Call the price：');
            let callPrice = await nestPriceFacade.triggeredPriceInfo(hbtc.address, account0, { value: new BN('10000000000000000') });
            console.log(callPrice)
        }
    });
});
