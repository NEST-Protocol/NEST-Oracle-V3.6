const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const usdt = await artifacts.require('USDT').deployed();
        const nestMining = await artifacts.require('NestMining').deployed();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await usdt.transfer(account0, USDT('10000000'), { from: account1 });
        await usdt.transfer(account1, USDT('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

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
        
        const ethDouble = async function(addr) {
            let balance = await ethBalance(addr);
            let val = balance.div(new BN('1000000000000'));
            return val.toNumber() / 1000000.0;
        };

        await nest.setTotalSupply(ETHER(5000000).sub(ETHER(1)));

        {
            // 1. Post price sheet
            let receipt = await nestMining.post(usdt.address, 30, USDT(1600), { value: ETHER(30.1) });
            console.log(receipt);
        }

        {
            // 2. Bite 1
            let receipt = await nestMining.takeToken(usdt.address, 0, 30, USDT(1500), { value: ETHER(90), from: account1 });
            console.log(receipt);
        }

        {
            // 3. Bite 2
            let receipt = await nestMining.takeToken(usdt.address, 1, 60, USDT(1400), { value: ETHER(180) });
            console.log(receipt);
        }

        {
            // 4. Bite 3
            let receipt = await nestMining.takeToken(usdt.address, 2, 120, USDT(1300), { value: ETHER(360), from: account1 });
            console.log(receipt);
        }

        {
            // 5. Bite 4
            let receipt = await nestMining.takeToken(usdt.address, 3, 240, USDT(1200), { value: ETHER(720) });
            console.log(receipt);
        }

        {
            // 6. Bite 5
            let receipt = await nestMining.takeToken(usdt.address, 4, 480, USDT(1100), { value: ETHER(960), from: account1 });
            console.log(receipt);
        }

        {
            // 7. Bite 6
            let receipt = await nestMining.takeToken(usdt.address, 5, 480, USDT(1000), { value: ETHER(960) });
            console.log(receipt);
        }

        {
            // 8. Bite 7
            let receipt = await nestMining.takeToken(usdt.address, 6, 480, USDT(900), { value: ETHER(960), from: account1 });
            console.log(receipt);
        }

        // List price sheets
        let list = await nestMining.list(usdt.address, 0, 8, 1);
        for (var i in list) {
            console.log(list[i]);
        }

        await skipBlocks(20);
        await nestMining.closeList(usdt.address, [0, 2, 4, 6]);
        await nestMining.closeList(usdt.address, [1, 3, 5, 7]);

        // Check balance of usdt
        {
            let balance = await showBalance(account0, 'After closeList(), account0');

            let pooled = 30 * 1600 + 120 * 1400 + 480 * 1200 + 480 * 1000;
            let bite = 60 * 1500 + 240 * 1300 + 480 * 1100;
            let lost = 30 * 1600 + 120 * 1400 + 480 * 1200 + 480 * 1000;

            LOG(USDT(pooled + bite - lost).toString());
            //assert.equal(0, balance.pool.usdt.cmp(USDT(pooled + bite - lost)));
            assert.equal(0, balance.pool.nest.cmp(ETHER(100000 * (1 + 4 + 16 + 64) + 400 * 10 * 0.8)));
        }
        {
            let balance = await showBalance(account1, 'After closeList(), account1');
            let pooled = 60 * 1500 + 240 * 1300 + 480 * 1100 + 480 * 900;
            let bite = 30 * 1600 + 120 * 1400 + 480 * 1200 + 480 * 1000;
            let lost = 60 * 1500 + 240 * 1300 + 480 * 1100;
        
            LOG(USDT(pooled + bite - lost).toString());
            //assert.equal(0, balance.pool.usdt.cmp(USDT(pooled + bite - lost)));
            assert.equal(0, balance.pool.nest.cmp(ETHER(100000 * (2 + 8 + 32 + 128))));
        }

        {
            await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account0), { from: account0 });
            let balance = await showBalance(account0, 'After withdrawn, account0');
            let bite = 60 * 1500 + 240 * 1300 + 480 * 1100;
            let lost = 30 * 1600 + 120 * 1400 + 480 * 1200 + 480 * 1000;
            LOG('lost: ' + USDT(lost - bite).toString());
            assert.equal(0, balance.balance.usdt.cmp(USDT(10000000 + bite - lost)));
        }

        {
            await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account1), { from: account1 });
            let balance = await showBalance(account1, 'After withdrawn, account1');
            let bite = 30 * 1600 + 120 * 1400 + 480 * 1200 + 480 * 1000;
            let lost = 60 * 1500 + 240 * 1300 + 480 * 1100;
            LOG('bite: ' + USDT(bite - lost).toString());
            assert.equal(0, balance.balance.usdt.cmp(USDT(10000000 + bite - lost)));
        }
    });
});
