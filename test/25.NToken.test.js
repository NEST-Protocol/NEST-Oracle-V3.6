const NToken = artifacts.require('NToken');
const TestERC20 = artifacts.require('TestERC20');
const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.utils.js");

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
            let yfi = await TestERC20.new('YFI', 'YFI', 18);
            console.log('yfi info:')
            console.log({
                name: await yfi.name(),
                symbol: await yfi.symbol(),
                decimals: (await yfi.decimals()).toString(),
                totalSupply: (await yfi.totalSupply()).toString(),
                balance0: (await yfi.balanceOf(account0)).toString(),
                balance1: (await yfi.balanceOf(account1)).toString()
            });

            let nyfi = await NToken.new('nYFI', 'nyfi');
            await nyfi.initialize(account0);
            await nyfi.update(nestGovernance.address);
            let checkBlockInfo = await nyfi.checkBlockInfo();
            let bidder = await nyfi.checkBidder();
            console.log('nyfi info: ');
            console.log({
                name: await nyfi.name(),
                symbol: await nyfi.symbol(),
                decimals: (await nyfi.decimals()).toString(),
                totalSupply: (await nyfi.totalSupply()).toString(),
                balance0: (await nyfi.balanceOf(account0)).toString(),
                balance1: (await nyfi.balanceOf(account1)).toString(),
                createBlock: checkBlockInfo.createBlock.toString(),
                recentlyUsedBlock: checkBlockInfo.recentlyUsedBlock.toString(),
                bidder: bidder
            });

            await nestGovernance.setBuiltinAddress(
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                account0,
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000'
            );
            await nyfi.update(nestGovernance.address);
            await nyfi.increaseTotal(12345);
            checkBlockInfo = await nyfi.checkBlockInfo();
            bidder = await nyfi.checkBidder();
            console.log('nyfi info: ');
            console.log({
                name: await nyfi.name(),
                symbol: await nyfi.symbol(),
                decimals: (await nyfi.decimals()).toString(),
                totalSupply: (await nyfi.totalSupply()).toString(),
                balance0: (await nyfi.balanceOf(account0)).toString(),
                balance1: (await nyfi.balanceOf(account1)).toString(),
                createBlock: checkBlockInfo.createBlock.toString(),
                recentlyUsedBlock: checkBlockInfo.recentlyUsedBlock.toString(),
                bidder: bidder
            });

            
            await nestGovernance.setBuiltinAddress(
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                account1,
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000'
            );
            await nyfi.update(nestGovernance.address);
            await nyfi.increaseTotal(9527, { from: account1 });
            checkBlockInfo = await nyfi.checkBlockInfo();
            bidder = await nyfi.checkBidder();
            console.log('nyfi info: ');
            console.log({
                name: await nyfi.name(),
                symbol: await nyfi.symbol(),
                decimals: (await nyfi.decimals()).toString(),
                totalSupply: (await nyfi.totalSupply()).toString(),
                balance0: (await nyfi.balanceOf(account0)).toString(),
                balance1: (await nyfi.balanceOf(account1)).toString(),
                createBlock: checkBlockInfo.createBlock.toString(),
                recentlyUsedBlock: checkBlockInfo.recentlyUsedBlock.toString(),
                bidder: bidder,
                allowance: (await nyfi.allowance(account0, account1)).toString()
            });


            await nyfi.approve(account1, 88999);
            checkBlockInfo = await nyfi.checkBlockInfo();
            bidder = await nyfi.checkBidder();
            console.log('nyfi info: ');
            console.log({
                name: await nyfi.name(),
                symbol: await nyfi.symbol(),
                decimals: (await nyfi.decimals()).toString(),
                totalSupply: (await nyfi.totalSupply()).toString(),
                balance0: (await nyfi.balanceOf(account0)).toString(),
                balance1: (await nyfi.balanceOf(account1)).toString(),
                createBlock: checkBlockInfo.createBlock.toString(),
                recentlyUsedBlock: checkBlockInfo.recentlyUsedBlock.toString(),
                bidder: bidder,
                allowance: (await nyfi.allowance(account0, account1)).toString()
            });
        }

    });
});
