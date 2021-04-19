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
        var i = 1;
        for (i = 1; i < 4; ++i) {
            let ethNum = 30;
            let usdtPrice = USDT(1714);
            let value = ETHER(30 + 30 + 0.1);
            let receipt = await nestMining.post2(usdt.address, ethNum, usdtPrice, ETHER(51200), { value: value });
            console.log('== post ' + i);
            console.log(receipt);
            LOG('nestMining: {nestMining}, nestLedger: {nestLedger}', {
                nestMining: await ethDouble(nestMining.address),
                nestLedger: await ethDouble(nestLedger.address)
            });
        }

        await skipBlocks(20);

        var arr = [];
        var index = 0;
        for (i = 1; i < 4; ++i) {
            arr.push(index++);
        }
        receipt = await nestMining.closeList2(usdt.address, arr, arr);
        console.log(receipt);
        LOG('nestMining: {nestMining}, nestLedger: {nestLedger}', {
            nestMining: await ethDouble(nestMining.address),
            nestLedger: await ethDouble(nestLedger.address)
        });
    });
});
