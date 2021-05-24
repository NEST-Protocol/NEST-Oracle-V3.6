const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.utils.js");

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

        // Post a price sheet
        await usdt.approve(nestMining.address, USDT('10000000'));
        await nest.approve(nestMining.address, ETHER('1000000000'));
        await nestMining.post2(usdt.address, 30, USDT(1560), ETHER(1000000), { value: ETHER(60.1)});
        //await nestMining.post(usdt.address, 30, USDT(1560), { value: ETHER(30.099) });
        await skipBlocks(20);
        await nestMining.close(usdt.address, 0);
        await nestMining.close(nest.address, 0);

        let quota = await nestRedeeming.quotaOf(nest.address);
        console.log('quota=' + quota);

        //let priceInfo = await nestMining.latestPrice(usdt.address);
        //LOG("price: {price}", priceInfo);
        let latestPrice = await nestMining.latestPrice(usdt.address);
        LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);

        await nest.approve(nestRedeeming.address, ETHER(1000000000));
        await nestLedger.addETHReward (nest.address, { value: ETHER(20) });

        let receipt = await nestRedeeming.redeem(nest.address, ETHER(30000), account0, { value : ETHER(0.1)});
        console.log(receipt);

        quota = await nestRedeeming.quotaOf(nest.address);
        console.log('quota=' + quota);

        let earned = await nnIncome.earned(account0);
        console.log("account1 earned nest: " + earned);

        earned = await nnIncome.earned(account1);
        console.log("account1 earned nest: " + earned);

        // config
        console.log(await nestRedeeming.getConfig());
        await nestRedeeming.setConfig({
    
            // Redeem activate threshold, when the circulation of token exceeds this threshold, 
            // activate redeem (Unit: 10000 ether). 500 
            activeThreshold: 200,
    
            // The number of nest redeem per block. 1000
            nestPerBlock: 800,
    
            // The maximum number of nest in a single redeem. 300000
            nestLimit: 240000,
    
            // The number of ntoken redeem per block. 10
            ntokenPerBlock: 12,
    
            // The maximum number of ntoken in a single redeem. 3000
            ntokenLimit: 3600,
    
            // Price deviation limit, beyond this upper limit stop redeem (10000 based). 500
            priceDeviationLimit: 200
        });
        console.log(await nestRedeeming.getConfig());
    });
});
