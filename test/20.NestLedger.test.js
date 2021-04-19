const NToken = artifacts.require('NToken');
const ERC20 = artifacts.require('ERC20');
const BN = require("bn.js");
const { expect } = require('chai');
const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc,/* nhbtc,*/ nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

        // Open nhbtc
        await hbtc.approve(nTokenController.address, 1, { from: account1 });
        await nest.approve(nTokenController.address, ETHER(10000), { from: account1 });
        await nTokenController.setNTokenMapping(hbtc.address, '0x0000000000000000000000000000000000000000', 0);
        await nTokenController.open(hbtc.address, { from: account1 });
        let nhbtcAddress = await nTokenController.getNTokenAddress(hbtc.address);
        let nhbtc = await NToken.at(nhbtcAddress);

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
                    hbtc: await nestMining.balanceOf(hbtc.address, account),
                    nhbtc: await nestMining.balanceOf(nhbtc.address, account),
                    nest: await nestMining.balanceOf(nest.address, account)
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

        // 1. getConfig() and setConfig()
        console.log(await nestLedger.getConfig());
        let receipt = await nestLedger.setConfig({
            // nest reward scale(10000 based). 2000
            nestRewardScale: 3000,

            // ntoken reward scale(10000 based). 8000
            //ntokenRewardScale: 7000
        });
        console.log(receipt);
        console.log(await nestLedger.getConfig());

        // 2. setApplication
        await nestLedger.addETHReward(nest.address, { value: ETHER(10) });
        assert.equal(0, ETHER(10).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(10).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));
        await nestLedger.carveETHReward(nest.address, { value: ETHER(10) });
        assert.equal(0, ETHER(20).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(20).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        await nestLedger.setApplication(account0, 1);
        await nestLedger.pay(nest.address, '0x0000000000000000000000000000000000000000', account1, ETHER(20));
        assert.equal(0, ETHER(0).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        // carveReward
        await nestLedger.carveETHReward(nhbtc.address, { value: ETHER(20) });
        assert.equal(0, ETHER(20).cmp(await ethBalance(nestLedger.address)));
        console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
        console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
        assert.equal(0, ETHER(20 * 3 / 10).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(20 * 7 / 10).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        await nestLedger.setConfig({
            // nest reward scale(10000 based). 2000
            nestRewardScale: 2000,

            // ntoken reward scale(10000 based). 8000
            //ntokenRewardScale: 8000
        });

        await nestLedger.carveETHReward(nhbtc.address, { value: ETHER(40) });
        assert.equal(0, ETHER(60).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(20 * 3 / 10 + 40 * 2 / 10).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(20 * 7 / 10 + 40 * 8 / 10).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        await nestLedger.pay(nest.address, '0x0000000000000000000000000000000000000000', account1, ETHER(20 * 3 / 10 + 40 * 2 / 10));
        await nestLedger.pay(nhbtc.address, '0x0000000000000000000000000000000000000000', account1, ETHER(20 * 7 / 10 + 40 * 8 / 10));
        assert.equal(0, ETHER(0).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        // addReward
        await nestLedger.setConfig({
            // nest reward scale(10000 based). 2000
            nestRewardScale: 3000,

            // ntoken reward scale(10000 based). 8000
            //ntokenRewardScale: 7000
        });
        await nestLedger.addETHReward(nhbtc.address, { value: ETHER(20) });
        assert.equal(0, ETHER(20).cmp(await ethBalance(nestLedger.address)));
        console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
        console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(20).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        await nestLedger.setConfig({
            // nest reward scale(10000 based). 2000
            nestRewardScale: 2000,

            // ntoken reward scale(10000 based). 8000
            //ntokenRewardScale: 8000
        });

        await nestLedger.addETHReward(nhbtc.address, { value: ETHER(40) });
        assert.equal(0, ETHER(60).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(60).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        await nestLedger.pay(nest.address, '0x0000000000000000000000000000000000000000', account1, ETHER(0));
        await nestLedger.pay(nhbtc.address, '0x0000000000000000000000000000000000000000', account1, ETHER(60));
        assert.equal(0, ETHER(0).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        // settle
        await nestLedger.setConfig({
            // nest reward scale(10000 based). 2000
            nestRewardScale: 3000,

            // ntoken reward scale(10000 based). 8000
            //ntokenRewardScale: 7000
        });

        // 2. setApplication
        await nestLedger.addETHReward(nest.address, { value: ETHER(10) });
        assert.equal(0, ETHER(10).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(10).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));
        await nestLedger.carveETHReward(nest.address, { value: ETHER(10) });
        assert.equal(0, ETHER(20).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(20).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        await nestLedger.setApplication(account0, 1);
        await nestLedger.settle(nest.address, '0x0000000000000000000000000000000000000000', account1, ETHER(20), { value: ETHER(1)});
        assert.equal(0, ETHER(1).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(1).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(0).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        // carveReward
        await nestLedger.carveETHReward(nhbtc.address, { value: ETHER(20) });
        assert.equal(0, ETHER(21).cmp(await ethBalance(nestLedger.address)));
        console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
        console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
        assert.equal(0, ETHER(1 + 20 * 3 / 10).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(20 * 7 / 10).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        await nestLedger.setConfig({
            // nest reward scale(10000 based). 2000
            nestRewardScale: 2000,

            // ntoken reward scale(10000 based). 8000
            //ntokenRewardScale: 8000
        });

        await nestLedger.carveETHReward(nhbtc.address, { value: ETHER(40) });
        assert.equal(0, ETHER(61).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(1 + 20 * 3 / 10 + 40 * 2 / 10).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(20 * 7 / 10 + 40 * 8 / 10).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));

        await nestLedger.settle(nest.address, '0x0000000000000000000000000000000000000000', account1, ETHER(20 * 3 / 10 + 40 * 2 / 10), { value: ETHER(2) });
        await nestLedger.settle(nhbtc.address, '0x0000000000000000000000000000000000000000', account1, ETHER(20 * 7 / 10 + 40 * 8 / 10), { value: ETHER(3) });
        assert.equal(0, ETHER(6).cmp(await ethBalance(nestLedger.address)));
        assert.equal(0, ETHER(3).cmp(new BN(await nestLedger.totalETHRewards(nest.address))));
        assert.equal(0, ETHER(3).cmp(new BN(await nestLedger.totalETHRewards(nhbtc.address))));
    });
});
