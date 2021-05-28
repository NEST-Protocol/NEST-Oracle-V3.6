const PostInOneBlock = artifacts.require('PostInOneBlock');
const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance, skipBlocks } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming, nestGovernance } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const usdt = await artifacts.require('USDT').deployed();
        const nestMining = await artifacts.require('NestMining').deployed();
        const nestGovernance = await artifacts.require('NestGovernance').deployed();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await usdt.transfer(account0, USDT('10000000'), { from: account1 });
        await usdt.transfer(account1, USDT('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

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
        
        let postInOneBlock = await PostInOneBlock.new(nestGovernance.address);
        await usdt.transfer(postInOneBlock.address, USDT(10000000));
        await nest.transfer(postInOneBlock.address, ETHER(10000000));

        let receipt = await postInOneBlock.batchPost(usdt.address, 30, USDT(1600), 3, { value: ETHER(30 * 3 + 10) });
        console.log(receipt);

        await skipBlocks(20);
        {
            // Check nest balance of postInOneBlock
            let balances0 = await showBalance(postInOneBlock.address, 'Before closed');

            await nestMining.close(usdt.address, 0);
            let balances1 = await showBalance(postInOneBlock.address, 'Close 0');

            await nestMining.close(usdt.address, 1);
            let balances2 = await showBalance(postInOneBlock.address, 'Close 1');
            
            await nestMining.close(usdt.address, 2);
            let balances3 = await showBalance(postInOneBlock.address, 'Close 2');
            await postInOneBlock.transfer('0x0000000000000000000000000000000000000000', account0, new BN(await web3.eth.getBalance(postInOneBlock.address)));

            let mined1 = balances1.pool.nest.sub(balances0.pool.nest).sub(ETHER(100000));
            let mined2 = balances2.pool.nest.sub(balances1.pool.nest).sub(ETHER(100000));
            let mined3 = balances3.pool.nest.sub(balances2.pool.nest).sub(ETHER(100000));

            let TOTAL = ETHER(400 * 0.8 * 10);
            assert.equal(0, TOTAL.mul(new BN(1)).div(new BN(6)).cmp(mined1));
            assert.equal(0, TOTAL.mul(new BN(2)).div(new BN(6)).cmp(mined2));
            assert.equal(0, TOTAL.mul(new BN(3)).div(new BN(6)).cmp(mined3));
        }

        // Second post

        receipt = await postInOneBlock.batchPost(usdt.address, 30, USDT(1800), 3, { value: ETHER(30 * 3 + 10) });
        console.log(receipt);
        await skipBlocks(20);
        {
            // Check nest balance of postInOneBlock
            let balances0 = await showBalance(postInOneBlock.address, 'Before closed');

            await nestMining.close(usdt.address, 3);
            let balances1 = await showBalance(postInOneBlock.address, 'Close 3');

            await nestMining.close(usdt.address, 4);
            let balances2 = await showBalance(postInOneBlock.address, 'Close 4');
            
            await nestMining.close(usdt.address, 5);
            let balances3 = await showBalance(postInOneBlock.address, 'Close 5');
            await postInOneBlock.transfer('0x0000000000000000000000000000000000000000', account0, new BN(await web3.eth.getBalance(postInOneBlock.address)));

            let mined1 = balances1.pool.nest.sub(balances0.pool.nest).sub(ETHER(100000));
            let mined2 = balances2.pool.nest.sub(balances1.pool.nest).sub(ETHER(100000));
            let mined3 = balances3.pool.nest.sub(balances2.pool.nest).sub(ETHER(100000));

            let TOTAL = ETHER(400 * 0.8 * (25));
            assert.equal(0, TOTAL.mul(new BN(1)).div(new BN(6)).cmp(mined1));
            assert.equal(0, TOTAL.mul(new BN(2)).div(new BN(6)).cmp(mined2));
            assert.equal(0, TOTAL.mul(new BN(3)).div(new BN(6)).cmp(mined3));
        }

        // List price sheets
        let list = await nestMining.list(usdt.address, 1, 2, 0);
        for (var i in list) {
            console.log(list[i]);
        }
    });
});
