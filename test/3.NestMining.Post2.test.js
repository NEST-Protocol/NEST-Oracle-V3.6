const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, ETHER, LOG, ethBalance } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const usdt = await artifacts.require('USDT').deployed();
        const nestLedger = await artifacts.require('NestLedger').deployed();
        const nestMining = await artifacts.require('NestMining').deployed();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await usdt.transfer(account0, USDT('10000000'), { from: account1 });
        await usdt.transfer(account1, USDT('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

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

        // Balance of account0
        assert.equal(0, balance0.balance.usdt.cmp(USDT('10000000')));
        assert.equal(0, balance0.balance.nest.cmp(ETHER('1000000000')));
        assert.equal(0, balance0.pool.usdt.cmp(USDT(0)));
        assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

        // Balance of nestMining
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
            // 1. Post a price sheet
            console.log('Post as price sheet');
            let receipt = await nestMining.post2(usdt.address, 30, USDT(1560), ETHER(51200), { value: ETHER(60.1) });
            console.log(receipt);
            balance0 = await showBalance(account0, 'After price posted');
            
            // Balance of account0
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000 - 100000 - 51200 * 30)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

            // Balance of nestMining
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(60.0)));
            assert.equal(0, (await usdt.balanceOf(nestMining.address)).cmp(USDT(1560 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000 + 100000 + 51200 * 30)));

            // Balance of nestLedger
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await usdt.balanceOf(nestLedger.address)).cmp(USDT(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));

            // Check ledger for ntoken
            assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(ETHER(0.1)));
            
            minedNest = ETHER(10 * 400 * 80 / 100);
            prevBlockNumber = receipt.receipt.blockNumber;

            await skipBlocks(20);

            // 2. Close usdt price sheet
            receipt = await nestMining.close(usdt.address, 0);
            balance0 = await showBalance(account0, 'After usdt price sheet closed');
            
            // Balance of account0
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000 - 100000 - 51200 * 30)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(1560 * 30)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000).add(minedNest)));

            // Balance of nestMining
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(30.0)));
            assert.equal(0, (await usdt.balanceOf(nestMining.address)).cmp(USDT(1560 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000 + 100000 + 51200 * 30)));

            // Balance of nestLedger
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await usdt.balanceOf(nestLedger.address)).cmp(USDT(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));

            // Check ledger for ntoken
            assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(ETHER(0.1)));

            // 3. Close nest price sheet
            await nestMining.close(nest.address, 0);
            console.log(receipt);
            balance0 = await showBalance(account0, 'After nest price sheet closed');

            // Balance of account0
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000 - 100000 - 51200 * 30)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(1560 * 30)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000 + 100000 + 51200 * 30).add(minedNest)));
            // Balance of nestMining
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0)));
            assert.equal(0, (await usdt.balanceOf(nestMining.address)).cmp(USDT(1560 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000 + 100000 + 51200 * 30)));
 
            // Balance of nestLedger
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await usdt.balanceOf(nestLedger.address)).cmp(USDT(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));
            
            // Check ledger for ntoken
            assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(ETHER(0.1)));

            // 4. Withdraw
            await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account0));
            await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account0));
            balance0 = await showBalance(account0, 'After withdrawn');

            // Balance of account0
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000).add(minedNest)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));
            // Balance of nestMining
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0)));
            assert.equal(0, (await usdt.balanceOf(nestMining.address)).cmp(USDT(0)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000).sub(minedNest)));
 
            // Balance of nestLedger
            assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0.1)));
            assert.equal(0, (await usdt.balanceOf(nestLedger.address)).cmp(USDT(0)));
            assert.equal(0, (await nest.balanceOf(nestLedger.address)).cmp(ETHER(0)));
            
            // Check ledger for ntoken
            assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(ETHER(0.1)));

            LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            await skipBlocks(18);
            LOG('blockNumber: ' + await web3.eth.getBlockNumber());

            // Show price
            {
                let latestPrice = await nestMining.latestPrice(usdt.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPrice = await nestMining.triggeredPrice(usdt.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}', triggeredPrice);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }
            await nestMining.stat(usdt.address);
            // Show price
            {
                let latestPrice = await nestMining.latestPrice(usdt.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPrice = await nestMining.triggeredPrice(usdt.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}', triggeredPrice);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }
        }

        //receipt = await nestMining.post(usdt.address, 30, USDT(1560), { value: ETHER(30.1) });
        // list(address tokenAddress, uint offset, uint count, uint order)
        let sheets = await nestMining.list(usdt.address, 0, 1, 1);

        for (const i in sheets) {
            console.log(sheets[i]);
        }

        let es = await nestMining.estimate(usdt.address);
        console.log(es);
    });
});
