const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.utils.js");
const IBNEST = artifacts.require('IBNEST');
const UpdateProxyPropose = artifacts.require('UpdateProxyPropose');
const IProxyAdmin = artifacts.require('IProxyAdmin');
const NestMining2 = artifacts.require('NestMining2');
const NestMining = artifacts.require('NestMining');
const BN = require("bn.js");
const { expect } = require('chai');
const { deployProxy, upgradeProxy, admin } = require('@openzeppelin/truffle-upgrades');

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        const account0 = accounts[0];

        {
            //let nest = await IBNEST.at('0x6158Ebb8022Ab0Cea5Ee507eDa9648A5f96538fE');
            // 0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681
            console.log('balance: ' + await nest.balanceOf(accounts[0]));
            console.log('balance: ' + await nest.balanceOf('0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681'));
            return;

            await nest.transfer('0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681', new BN('7000000000000000000000000000'));

            console.log('balance: ' + await nest.balanceOf(accounts[0]));
            console.log('balance: ' + await nest.balanceOf('0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681'));
        }

        // Initialize usdt balance
        //await usdt.transfer(account0, USDT('10000000'), { from: account0 });
        //await nest.transfer(nestMining.address, ETHER('1000000000'));

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

        //await nest.approve(nestMining.address, ETHER('1000000000'));
        //await usdt.approve(nestMining.address, USDT('10000000'));

        {
            //let nestMiningNew = await NestMining.new();
            //let newNestMining = await upgradeProxy(nestMining.address, NestMining);
            //console.log('newNestMining: ' + newNestMining.address);

            if (false) {
                let proxyAdmin = await IProxyAdmin.at('0xe4113d1e7e0054A01b0b72Ec754294E2E1670f81');
                let nestMiningNew = await NestMining.new();
                let receipt = await proxyAdmin.upgrade(nestMining.address, nestMiningNew.address);
                console.log(receipt);
                return;
            }
            //await nestMining.closeList2(usdt.address, [4], [4]);
            console.log('Post as price sheet');
            let receipt = await nestMining.post2(usdt.address, 30, USDT(1500), ETHER(51200 - 512), { value: ETHER(60.1) });
            console.log(receipt);

            let pi = await nestMining.latestPriceAndTriggeredPriceInfo(usdt.address);
            pi = {
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            };
            console.log(pi);

            let list = await nestMining.lastPriceList(usdt.address, 5);
            for (var i in list) {
                console.log(list[i].toString());
            }

            let arr = [8414801, 8414725, 8414663];
            console.log('========== +0 ==========');
            for (var i in arr) {
                let height = arr[i];
                let price = await nestMining.findPrice(usdt.address, height);
                console.log({
                    height: height.toString(),
                    blockNumber: price.blockNumber.toString(),
                    price: price.price.toString()
                });
            }

            console.log('========== +1 ==========');
            for (var i in arr) {
                let height = arr[i] + 1;
                let price = await nestMining.findPrice(usdt.address, height);
                console.log({
                    height: height.toString(),
                    blockNumber: price.blockNumber.toString(),
                    price: price.price.toString()
                });
            }

            console.log('========== +5 ==========');
            for (var i in arr) {
                let height = arr[i] + 5;
                let price = await nestMining.findPrice(usdt.address, height);
                console.log({
                    height: height.toString(),
                    blockNumber: price.blockNumber.toString(),
                    price: price.price.toString()
                });
            }

        }
    });
});
