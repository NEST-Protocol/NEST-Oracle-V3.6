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

        // 1. config
        let config = await nestMining.getConfig();
        console.log('Before setConfig()');
        console.log(config);
        await nestMining.setConfig({
            // Eth number of each post. 30
            // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
            postEthUnit: 10,

            // Post fee(0.0001eth，DIMI_ETHER). 1000
            postFeeUnit: 990,

            // Proportion of miners digging(10000 based). 8000
            minerNestReward: 8500,
            
            // The proportion of token dug by miners is only valid for the token created in version 3.0
            // (10000 based). 9500
            minerNTokenReward: 9000,

            // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
            doublePostThreshold: 200,
            
            // The limit of ntoken mined blocks. 100
            ntokenMinedBlockLimit: 300,

            // -- Public configuration
            // The number of times the sheet assets have doubled. 4
            maxBiteNestedLevel: 4,
            
            // Price effective block interval. 20
            priceEffectSpan: 25,

            // The amount of nest to pledge for each post（Unit: 1000). 100
            pledgeNest: 200
        });
        config = await nestMining.getConfig();
        console.log('After setConfig()');
        console.log(config);

        // 2. token cache
        console.log('usdt: ' + usdt.address);
        console.log('nest: ' + nest.address);
        console.log('ntoken for usdt: ' + await nestMining.getNTokenAddress(usdt.address));
        await nest.approve(nestMining.address, ETHER(10000000));
        await usdt.approve(nestMining.address, USDT(10000000));

        await nestMining.setNTokenAddress(usdt.address, usdt.address);
        console.log('ntoken for usdt: ' + await nestMining.getNTokenAddress(usdt.address));
        await nestMining.resetNTokenCache(usdt.address);
        await nestMining.post2(usdt.address, 10, USDT(1600), ETHER(51200), { value: ETHER(20.099) });
        console.log('ntoken for usdt: ' + await nestMining.getNTokenAddress(usdt.address));
        await skipBlocks(20);
        await nestMining.closeList2(usdt.address, [0], [0]);
    });
});
