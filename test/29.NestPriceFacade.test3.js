const INestPriceFacade = artifacts.require('INestPriceFacade');
const INestQuery = artifacts.require('INestQuery');
const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance, skipBlocks } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //let { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const usdt = await artifacts.require('USDT').deployed();
        const hbtc = await artifacts.require('HBTC').deployed();
        const nhbtc = await artifacts.require('NHBTC').deployed();
        const nestLedger = await artifacts.require('NestLedger').deployed();
        const nestMining = await artifacts.require('NestMining').deployed();
        const ntokenMining = await artifacts.require('NTokenMining').deployed();
        let nestPriceFacade = await artifacts.require('NestPriceFacade').deployed();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await hbtc.transfer(account0, ETHER('10000000'), { from: account0 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account0 });
        await usdt.transfer(account1, USDT('10000000'), { from: account0 });
        await usdt.transfer(account0, USDT('10000000'), { from: account0 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

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

        let balance0 = await showBalance(account0, 'account0');
        let balance1 = await showBalance(account1, 'account1');

        await nest.approve(nestMining.address, ETHER('1000000000'));
        await hbtc.approve(nestMining.address, HBTC('10000000'));
        //await nest.approve(nestMining.address, ETHER('1000000000'), { from: account1 });
        //await hbtc.approve(nestMining.address, HBTC('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let mined = nHBTC(0);
        
        if (true) {
            // config
            console.log('getConfig()');
            console.log(await nestPriceFacade.getConfig());
            console.log('setConfig()');
            nestPriceFacade.setConfig({
                // Single query fee（0.0001 ether, DIMI_ETHER). 100
                singleFee: 137,

                // Double query fee（0.0001 ether, DIMI_ETHER). 100
                doubleFee: 247,

                // The normal state flag of the call address. 0
                normalFlag: 1
            });
            console.log(await nestPriceFacade.getConfig());
            LOG('usdtQuery: {usdtQuery}, nestQuery: {nestQuery}', {
                usdtQuery: await nestPriceFacade.getNestQuery(usdt.address),
                nestQuery: await nestPriceFacade.getNestQuery(nest.address),
            });
            await nestPriceFacade.setNestQuery(usdt.address, nestMining.address);
            await nestPriceFacade.setNestQuery(nest.address, nestMining.address);
            LOG('usdtQuery: {usdtQuery}, nestQuery: {nestQuery}', {
                usdtQuery: await nestPriceFacade.getNestQuery(usdt.address),
                nestQuery: await nestPriceFacade.getNestQuery(nest.address),
            });
        }

        nestPriceFacade = await INestPriceFacade.at(nestPriceFacade.address);
        if (true) {
            
            // Direct query price
            console.log('triggeredPrice()')
            let price = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: price.blockNumber.toString(),
                price: price.price.toString()
            });
            await nestPriceFacade.setAddressFlag(account0, 1);
            console.log('addressFlag: ' + await nestPriceFacade.getAddressFlag(account0));

            console.log('triggeredPrice()');
            let pi = await nestPriceFacade.triggeredPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            // console.log('findPrice()');
            // await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10, account1, { value: ETHER(0.0137) });

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address, account1, { value: ETHER(0.0247) });
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalETHRewards(usdt.address),
                balance: await ethBalance(nestLedger.address)
            });
            assert.equal(0, ETHER(0.0137 * 5 + 0.0247 * 3).cmp(await nestLedger.totalETHRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 5 + 0.0247 * 3).cmp(await ethBalance(nestLedger.address)));
        }

        nestPriceFacade = await INestQuery.at(nestPriceFacade.address);
        if (true) {
            // Post price sheet and query price
            console.log('Post price sheet and query price');
            await nest.approve(nestMining.address, ETHER(1000000000));
            await usdt.approve(nestMining.address, USDT(1000000000));
            let receipt = await nestMining.post2(usdt.address, 30, USDT(1600), ETHER(65536), { value: ETHER(60.1) });
            console.log(receipt);

            console.log('triggeredPrice()');
            let pi = await nestPriceFacade.triggeredPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString()
            });

            console.log('findPrice()');
            pi = await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber());
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                bn: await web3.eth.getBlockNumber()
            });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10);

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                pripice: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString()
            });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
                ntokenAvgPrice: pi.ntokenAvgPrice.toString(),
                ntokenSigmaSQ: pi.ntokenSigmaSQ.toString(),
            });

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
            });
        }

        if (true) {
            // Query price after wait 20 blocks
            console.log('Query price after wait 20 blocks');
            await skipBlocks(20);
            await nestMining.closeList2(usdt.address, [0], [0]);
            console.log('triggeredPrice()');
            let pi = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString()
            });

            console.log('findPrice()');
            pi = await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber());
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                bn: await web3.eth.getBlockNumber()
            });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10);

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                pripice: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString()
            });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
                ntokenAvgPrice: pi.ntokenAvgPrice.toString(),
                ntokenSigmaSQ: pi.ntokenSigmaSQ.toString(),
            });

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
            });
        }

        if (true) {
            // Post multi price sheets and query price
            console.log('Post multi price sheets and query price');
            
            let arr = [];
            let avgUsdtPrice = USDT(1600);
            let avgNestPrice = ETHER(65536);
            let usdtSigmaSQ = new BN(0);
            let nestSigmaSQ = new BN(0);

            let d = new BN(22);
            let prevUsdtPrice = new USDT(1600);
            let prevNestPrice = new ETHER(65535);
            for (var i = 0; i < 10; ++i) {
                let receipt = await nestMining.post2(usdt.address, 30, USDT(1600 + i * 10), ETHER(65536 + i * 655.36), { value: ETHER(60.1) });
                console.log('Post' + i + ': ' + (1600 + i * 10));
                console.log(receipt);
                arr.push(i + 1);

                avgUsdtPrice = avgUsdtPrice.mul(new BN(95)).add(USDT(1600 + i * 10).mul(new BN(5))).div(new BN(100));
                avgNestPrice = avgNestPrice.mul(new BN(95)).add(ETHER(65536 + i * 655.36).mul(new BN(5))).div(new BN(100));

                let earn = USDT(1600 + i * 10).mul(new BN('281474976710656')).div(prevUsdtPrice).sub(new BN('281474976710656'));
                usdtSigmaSQ = usdtSigmaSQ.mul(new BN(95)).add(
                    earn.mul(earn).div(new BN(14).mul(d)).mul(new BN(5)).div(new BN('281474976710656'))
                ).div(new BN(100));
                prevUsdtPrice = USDT(1600 + i * 10);

                earn = ETHER(65536 + i * 655.36).mul(new BN('281474976710656')).div(prevNestPrice).sub(new BN('281474976710656'));
                nestSigmaSQ = nestSigmaSQ.mul(new BN(95)).add(
                    earn.mul(earn).div(new BN(14).mul(d)).mul(new BN(5)).div(new BN('281474976710656'))
                ).div(new BN(100));
                prevNestPrice = ETHER(65536 + i * 655.36);

                d = new BN(1);
            }

            usdtSigmaSQ = usdtSigmaSQ.mul(ETHER(1)).div(new BN('281474976710656'));
            nestSigmaSQ = nestSigmaSQ.mul(ETHER(1)).div(new BN('281474976710656'));
            await skipBlocks(20);
            await nestMining.closeList2(usdt.address, arr, arr);

            console.log('triggeredPrice()');
            let pi = await nestPriceFacade.triggeredPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString()
            });
            assert.equal(0, avgUsdtPrice.cmp(pi.avgPrice));
            LOG('usdtSigmaSQ: {usdtSigmaSQ}, sigmaSQ: {sigmaSQ}', {
                usdtSigmaSQ: usdtSigmaSQ.toString(),
                sigmaSQ: pi.sigmaSQ.toString()
            });
            assert.equal(0, usdtSigmaSQ.cmp(pi.sigmaSQ));
            
            let list = await nestPriceFacade.lastPriceList(usdt.address, 5);
            for (var i in list) {
                console.log(list[i].toString());
            }

            console.log('findPrice()');
            pi = await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber());
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                bn: await web3.eth.getBlockNumber()
            });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString()
            });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10);

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });
            assert.equal(0, avgUsdtPrice.cmp(pi.triggeredAvgPrice));
            assert.equal(0, usdtSigmaSQ.cmp(pi.triggeredSigmaSQ));

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                pripice: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString()
            });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                avgPrice: pi.avgPrice.toString(),
                sigmaSQ: pi.sigmaSQ.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
                ntokenAvgPrice: pi.ntokenAvgPrice.toString(),
                ntokenSigmaSQ: pi.ntokenSigmaSQ.toString(),
            });
            assert.equal(0, avgUsdtPrice.cmp(pi.avgPrice));
            LOG('avgNestPrice: {avgNestPrice}, ntokenAvgPrice: {ntokenAvgPrice}', {
                avgNestPrice: avgNestPrice,
                ntokenAvgPrice: pi.ntokenAvgPrice
            });
            assert.equal(0, usdtSigmaSQ.cmp(pi.sigmaSQ));
            assert.equal(0, avgNestPrice.div(new BN('10000000000')).cmp(pi.ntokenAvgPrice.div(new BN('10000000000'))));

            LOG('nestSigmaSQ: {nestSigmaSQ}, ntokenSigmaSQ: {ntokenSigmaSQ}', { 
                nestSigmaSQ: nestSigmaSQ,
                ntokenSigmaSQ: pi.ntokenSigmaSQ
            });
            assert.equal(0, nestSigmaSQ.div(new BN(1000000)).cmp(pi.ntokenSigmaSQ.div(new BN(1000000))));

            LOG('avgNestPrice: {avgNestPrice}, ntokenAvgPrice: {ntokenAvgPrice}', { 
                avgNestPrice: avgNestPrice.toString(), 
                ntokenAvgPrice: pi.ntokenAvgPrice.toString() 
            });
            assert.equal(0, avgNestPrice.div(new BN('10000000000')).cmp(pi.ntokenAvgPrice.div(new BN('10000000000'))));

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address);
            console.log({
                blockNumber: pi.blockNumber.toString(),
                price: pi.price.toString(),
                ntokenBlockNumber: pi.ntokenBlockNumber.toString(),
                ntokenPrice: pi.ntokenPrice.toString(),
            });
        }

        nestPriceFacade = await INestPriceFacade.at(nestPriceFacade.address);
        if (true) {
            
            // Direct query price
            console.log('triggeredPrice()')
            let price = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: price.blockNumber.toString(),
                price: price.price.toString()
            });
            await nestPriceFacade.setAddressFlag(account0, 1);

            console.log('triggeredPrice()');
            let pi = await nestPriceFacade.triggeredPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('findPrice()');
            await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10, account1, { value: ETHER(0.0137) });

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalETHRewards(nest.address),
                balance: await ethBalance(nestLedger.address)
            });

            assert.equal(0, ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1).cmp(await nestLedger.totalETHRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1).cmp(await ethBalance(nestLedger.address)));

            await nestMining.settle(usdt.address);
            console.log('Balances:');
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalETHRewards(nest.address),
                balance: await ethBalance(nestLedger.address)
            });
            console.log('Poor expectations:');
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1 * 11).sub(await nestLedger.totalETHRewards(nest.address)).toString(),
                balance: ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1 * 11).sub(await ethBalance(nestLedger.address)).toString()
            });

            assert.equal(0, ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1 * 11).cmp(await nestLedger.totalETHRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 11 + 0.0247 * 6 + 0.1 * 11).cmp(await ethBalance(nestLedger.address)));
        }

        if (true) {
            
            await nestPriceFacade.setConfig({
                // Single query fee（0.0001 ether, DIMI_ETHER). 100
                singleFee: 137,

                // Double query fee（0.0001 ether, DIMI_ETHER). 100
                doubleFee: 247,

                // The normal state flag of the call address. 0
                normalFlag: 0
            });
            await nestPriceFacade.setAddressFlag(account0, 0);
            
            // Direct query price
            console.log('triggeredPrice()')
            let price = await nestMining.triggeredPrice(usdt.address);
            console.log({
                blockNumber: price.blockNumber.toString(),
                price: price.price.toString()
            });
            await nestPriceFacade.setAddressFlag(account0, 0);

            console.log('triggeredPrice()');
            let pi = await nestPriceFacade.triggeredPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPriceInfo()');
            pi = await nestPriceFacade.triggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('findPrice()');
            await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });

            console.log('latestPrice()');
            pi = await nestPriceFacade.latestPrice(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('lastPriceList()');
            await nestPriceFacade.lastPriceList(usdt.address, 10, account1, { value: ETHER(0.0137) });

            console.log('latestPriceAndTriggeredPriceInfo()');
            pi = await nestPriceFacade.latestPriceAndTriggeredPriceInfo(usdt.address, account1, { value: ETHER(0.0137) });

            console.log('triggeredPrice2()');
            pi = await nestPriceFacade.triggeredPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('triggeredPriceInfo2()');
            pi = await nestPriceFacade.triggeredPriceInfo2(usdt.address, account1, { value: ETHER(0.0247) });

            console.log('latestPrice2()');
            pi = await nestPriceFacade.latestPrice2(usdt.address, account1, { value: ETHER(0.0247) });

            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalETHRewards(nest.address),
                balance: await ethBalance(nestLedger.address)
            });

            assert.equal(0, ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).cmp(await nestLedger.totalETHRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).cmp(await ethBalance(nestLedger.address)));

            await nestMining.settle(usdt.address);
            console.log('Balances:');
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: await nestLedger.totalETHRewards(nest.address),
                balance: await ethBalance(nestLedger.address)
            });
            console.log('Poor expectations:');
            LOG('rewards: {rewards}, balance: {balance}', {
                rewards: ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).sub(await nestLedger.totalETHRewards(nest.address)).toString(),
                balance: ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).sub(await ethBalance(nestLedger.address)).toString()
            });

            assert.equal(0, ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).cmp(await nestLedger.totalETHRewards(nest.address)));
            assert.equal(0, ETHER(0.0137 * 17 + 0.0247 * 9 + 0.1 * 11).cmp(await ethBalance(nestLedger.address)));
            console.log('addressFlag: ' + await nestPriceFacade.getAddressFlag(account0));
        }

        if (true) {

            console.log(await nestPriceFacade.getConfig());
            LOG('usdtQuery: {usdtQuery}, nestQuery: {nestQuery}', {
                usdtQuery: await nestPriceFacade.getNestQuery(usdt.address),
                nestQuery: await nestPriceFacade.getNestQuery(nest.address),
            });
            await nestPriceFacade.setNestQuery(usdt.address, ntokenMining.address);
            await nestPriceFacade.setNestQuery(nest.address, ntokenMining.address);
            LOG('usdtQuery: {usdtQuery}, nestQuery: {nestQuery}', {
                usdtQuery: await nestPriceFacade.getNestQuery(usdt.address),
                nestQuery: await nestPriceFacade.getNestQuery(nest.address),
            });

            console.log('findPrice()');
            //await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });

            await nest.approve(ntokenMining.address, ETHER(100000000));
            await usdt.approve(ntokenMining.address, ETHER(100000000));
            //await ntokenMining.setNTokenAddress(usdt.address, usdt.address);
            await ntokenMining.post2(usdt.address, 10, USDT(512), ETHER(32768), { value: ETHER(20.1) });
            await skipBlocks(20);

            console.log('findPrice()');
            await nestPriceFacade.findPrice(usdt.address, await web3.eth.getBlockNumber(), account1, { value: ETHER(0.0137) });
        }
    });
});
