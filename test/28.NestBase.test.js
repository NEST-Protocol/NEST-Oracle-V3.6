const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.utils.js");

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
        await usdt.transfer(account0, USDT('100000000'), { from: account1 });
        await usdt.transfer(account1, USDT('100000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('800000000'));

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

        if (true) {
            console.log('collect');
            
            await nest.setTotalSupply(ETHER(5000000 - 1));
            await nest.approve(nestMining.address, ETHER(2000000000));
            await usdt.approve(nestMining.address, USDT(2000000000));

            let arr = [];
            let total = ETHER(0);
            await nestMining.post(usdt.address, 30, USDT(1000), { value: ETHER(30).add(ETHER(0.1).mul(new BN(1))) });
            //await skipBlocks(20);
            //await nestMining.closeList(usdt.address, arr);

            await nestMining.migrate('0x0000000000000000000000000000000000000000', ETHER(30));
            await nestMining.migrate(usdt.address, USDT(1000 * 30));

            await nestLedger.setApplication(account0, 1);
            console.log('Before migrate');
            console.log({
                eth: (await ethBalance(account0)).toString(),
                usdt: (await usdt.balanceOf(account0)).toString()
            });
            console.log({
                eth: (await ethBalance(account1)).toString(),
                usdt: (await usdt.balanceOf(account1)).toString()
            });
            await nestLedger.pay('0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000', account1, ETHER(30));
            await nestLedger.pay('0x0000000000000000000000000000000000000000', usdt.address, account1, USDT(1000 * 30));
            console.log('After migrate');
            console.log({
                eth: (await ethBalance(account0)).toString(),
                usdt: (await usdt.balanceOf(account0)).toString()
            });
            console.log({
                eth: (await ethBalance(account1)).toString(),
                usdt: (await usdt.balanceOf(account1)).toString()
            });
        }
    });
});
