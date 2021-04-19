const BN = require("bn.js");
const { expect } = require('chai');
const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        
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

        let balanceM = await getBalance(nestMining.address);
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

        // Approve usdt and nest
        await nest.approve(nestMining.address, ETHER('1000000000'));
        await usdt.approve(nestMining.address, USDT('10000000'));
        await nest.approve(nestMining.address, ETHER('1000000000'), { from: account1 });
        await usdt.approve(nestMining.address, USDT('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let minedNest = ETHER(0);
        
        await nest.setTotalSupply(ETHER(5000000).sub(ETHER(1)));
        {
            // Post a price sheet
            console.log('Post as price sheet');
            let receipt = await nestMining.post(usdt.address, 30, USDT(1560), { value: ETHER(30.1) });
            console.log(receipt);
            balance0 = await showBalance(account0, 'After price posted');
            
            // Balance of account0
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(0)));
            assert.equal(0, balance0.pool.nest.cmp(minedNest));

            // Balance of nestMining
            assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(30.0)));
            assert.equal(0, (await usdt.balanceOf(nestMining.address)).cmp(USDT(1560 * 30)));
            assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000 + 100000)));
            
            minedNest = ETHER(10 * 400 * 8 / 10);
            prevBlockNumber = receipt.receipt.blockNumber;

            // Bite by account1
            receipt = await nestMining.biteEth(usdt.address, 0, 30, USDT(2000), {
                from: account1,
                value: ETHER(30)
            })

            balance0 = await showBalance(account0, 'After bite by account1');
            balance1 = await showBalance(account1, 'After bite by account1');

            // Balance of account0
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(0)));
            assert.equal(0, balance0.pool.nest.cmp(USDT(0)));
            
            // Balance of account1
            assert.equal(0, balance1.balance.usdt.cmp(USDT(10000000 - 30 * 2 * 2000 - 1560 * 30)));
            assert.equal(0, balance1.balance.nest.cmp(ETHER(1000000000 - 200000)));
            assert.equal(0, balance1.pool.usdt.cmp(USDT(0)));
            assert.equal(0, balance1.pool.nest.cmp(ETHER(0)));
            
            await skipBlocks(20);
            // Close price sheet
            receipt = await nestMining.close(usdt.address, 0);
            console.log(receipt);
            receipt = await nestMining.close(usdt.address, 1);
            console.log(receipt);

            balance0 = await showBalance(account0, 'After price sheet closed');
            balance1 = await showBalance(account1, 'After price sheet closed');

            // Balance of account0
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(1560 * 30 * 2)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000).add(minedNest)));
            
            // Balance of account1
            assert.equal(0, balance1.balance.usdt.cmp(USDT(10000000 - 30 * 2 * 2000 - 1560 * 30)));
            assert.equal(0, balance1.balance.nest.cmp(ETHER(1000000000 - 200000)));
            assert.equal(0, balance1.pool.usdt.cmp(USDT(30 * 2 * 2000)));
            assert.equal(0, balance1.pool.nest.cmp(ETHER(200000)));

            // Balance of nestMining
            //assert.equal(0, balanceM.balance.usdt.cmp());

            // Withdraw
            await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account0));
            await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account0));
            await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account1), { from: account1 });
            await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account1), { from: account1 });

            balance0 = await showBalance(account0, 'After withdrawn');
            balance1 = await showBalance(account1, 'After withdrawn');

            // Balance of account0
            assert.equal(0, balance0.balance.usdt.cmp(USDT(10000000 + 1560 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000).add(minedNest)));
            assert.equal(0, balance0.pool.usdt.cmp(USDT(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));
            
            // Balance of account1
            assert.equal(0, balance1.balance.usdt.cmp(USDT(10000000 - 1560 * 30)));
            assert.equal(0, balance1.balance.nest.cmp(ETHER(1000000000)));
            assert.equal(0, balance1.pool.usdt.cmp(USDT(0)));
            assert.equal(0, balance1.pool.nest.cmp(ETHER(0)));

            return;
        }
    });
});
