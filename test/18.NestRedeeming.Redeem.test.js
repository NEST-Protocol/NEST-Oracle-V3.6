const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance, skipBlocks } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const nn = await artifacts.require('NNToken').deployed();
        const usdt = await artifacts.require('USDT').deployed();
        const hbtc = await artifacts.require('HBTC').deployed();
        const nhbtc = await artifacts.require('NHBTC').deployed();
        const nestLedger = await artifacts.require('NestLedger').deployed();
        const nestMining = await artifacts.require('NestMining').deployed();
        const nnIncome = await artifacts.require('NNIncome').deployed();
        const nestRedeeming = await artifacts.require('NestRedeeming').deployed();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await usdt.transfer(account0, USDT('10000000'), { from: account1 });
        await usdt.transfer(account1, USDT('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('6000000000'));
        await nest.transfer(nnIncome.address, ETHER('2000000000'));
        await nn.transfer(account1, 300);

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

        await usdt.approve(nestMining.address, USDT(100000000));
        await nest.approve(nestMining.address, ETHER(100000000));
        {
            // 1. Post price sheet
            await nestMining.post2(usdt.address, 30, USDT(1600), ETHER(51200 + 512 * 0), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1700), ETHER(51200 + 512 * 1), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1800), ETHER(51200 + 512 * 2), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1900), ETHER(51200 + 512 * 3), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(2000), ETHER(51200 + 512 * 4), { value: ETHER(60 + 10) });

            await skipBlocks(20);
            await nestMining.stat(usdt.address);
            await nestMining.stat(nest.address);

            let latestPriceAndTriggeredPriceInfo = await nestMining.latestPriceAndTriggeredPriceInfo(nest.address);
            LOG('latestPriceBlockNumber: {latestPriceBlockNumber}\n'
                + 'latestPriceValue: {latestPriceValue}\n'
                + 'triggeredPriceBlockNumber: {triggeredPriceBlockNumber}\n'
                + 'triggeredPriceValue: {triggeredPriceValue}\n'
                + 'triggeredAvgPrice: {triggeredAvgPrice}\n'
                + 'triggeredSigmaSQ: {triggeredSigmaSQ}\n'
                , latestPriceAndTriggeredPriceInfo);

            // 2. Total eth rewards
            //console.log('feeUnit: ' + (await nestMining.getFeeUnit(usdt.address)).toString());
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
            await nestMining.settle(usdt.address);
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));

            // 3. Check quota of redeeming
            console.log('nest quota: ' + await nestRedeeming.quotaOf(nest.address));

            // 4. First redeem
            await nest.approve(nestRedeeming.address, ETHER(10000000));
            await nestRedeeming.redeem(nest.address, ETHER(100000), account0, { value: ETHER(0.1) });
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));

            // 5. Check quota of redeeming
            console.log('nest quota: ' + await nestRedeeming.quotaOf(nest.address));
            
            // 6. Post price sheet
            await nestMining.post2(usdt.address, 30, USDT(1600), ETHER(51200 + 512 * 0), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1700), ETHER(51200 + 512 * 1), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1800), ETHER(51200 + 512 * 2), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(1900), ETHER(51200 + 512 * 3), { value: ETHER(60 + 10) });
            await nestMining.post2(usdt.address, 30, USDT(2000), ETHER(51200 + 512 * 4), { value: ETHER(60 + 10) });

            await skipBlocks(20);
            await nestMining.stat(usdt.address);
            await nestMining.stat(nest.address);
            
            latestPriceAndTriggeredPriceInfo = await nestMining.latestPriceAndTriggeredPriceInfo(nest.address);
            LOG('latestPriceBlockNumber: {latestPriceBlockNumber}\n'
                + 'latestPriceValue: {latestPriceValue}\n'
                + 'triggeredPriceBlockNumber: {triggeredPriceBlockNumber}\n'
                + 'triggeredPriceValue: {triggeredPriceValue}\n'
                + 'triggeredAvgPrice: {triggeredAvgPrice}\n'
                + 'triggeredSigmaSQ: {triggeredSigmaSQ}\n'
                , latestPriceAndTriggeredPriceInfo);

            let quota = await nestRedeeming.quotaOf(nest.address);
            console.log('nest quota: ' + quota);
            assert.equal(0, quota.cmp(ETHER(200000 + 1000 * 27)));

            // 7. Second redeem
            await nestRedeeming.redeem(nest.address, ETHER(100000), account0, { value: ETHER(0.01) });

            // 8. Check quota of redeeming
            console.log('nest quota: ' + await nestRedeeming.quotaOf(nest.address));

            let arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
            let receipt = await nestMining.closeList2(usdt.address, arr, arr);
            console.log(receipt);
        }
    });
});
