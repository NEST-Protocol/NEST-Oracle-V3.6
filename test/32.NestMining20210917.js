const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const INestPriceFacade = artifacts.require('INestPriceFacade');
const INestQuery = artifacts.require('INestQuery');
const ProxyAdminTest = artifacts.require('ProxyAdminTest');
const IProxyAdmin = artifacts.require('IProxyAdmin');
const NestMining = artifacts.require('NestMining');

const BN = require("bn.js");
const { expect } = require('chai');
const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        let { 
            nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, 
            nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming,
            nestGovernance
        } = await deploy();
        let proxyAdminTest = await deployProxy(ProxyAdminTest, [nestGovernance.address], { initializer: 'initialize' });
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await hbtc.transfer(account0, ETHER('10000000'), { from: account0 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account0 });
        await usdt.transfer(account1, USDT('10000000'), { from: account0 });
        await usdt.transfer(account0, USDT('10000000'), { from: account0 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

        const skipBlocks = async function(blockCount) {
            for (var i = 0; i < blockCount; ++i) {
                await web3.eth.sendTransaction({ from: account0, to: account0, value: ETHER(1)});
            }
        };

        const getAccountInfo = async function(account) {
            account = account.address || account;
            return {
                eth: (await web3.eth.getBalance(account)).toString(),
                usdt: (await usdt.balanceOf(account)).toString(),
                nest: (await nest.balanceOf(account)).toString(),
            };
        }

        const getStatus = async function() {
            return {
                account0: await getAccountInfo(account0),
                account1: await getAccountInfo(account1),
                nestMining: await getAccountInfo(nestMining),
                nestLedger: await getAccountInfo(nestLedger),
            }
        };

        await nest.approve(nestMining.address, ETHER('1000000000'));
        await hbtc.approve(nestMining.address, HBTC('10000000'));
        await usdt.approve(nestMining.address, USDT('10000000'));
        //await nest.approve(nestMining.address, ETHER('1000000000'), { from: account1 });
        //await hbtc.approve(nestMining.address, HBTC('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let mined = nHBTC(0);
        
        console.log(await getStatus());

        if (true) {
            console.log('1. 使用NestMining20210805报价');

            for (var i = 0; i < 3; ++i) {
                let receipt = await nestMining.post2(usdt.address, 30, USDT(3600), ETHER(100000), {
                    value: ETHER(60.1)
                });
                console.log(await getStatus());
            }
        }

        if (true) {
            console.log('2. 修改NestMining实现');
            const proxyAdmin = await IProxyAdmin.at(await proxyAdminTest.getAdmin());
            const newNestMining = await NestMining.new();
            await proxyAdmin.upgrade(nestMining.address, newNestMining.address);
            // nestMining = await NestMining.at(nestMining.address);
            // console.log('feeInfo: ' + await nestMining.getFeeInfo(usdt.address));
            // console.log('U255: ' + await nestMining.getU255());
        }

        if (true) {
            console.log('3. 使用NestMining报价');

            for (var i = 0; i < 3; ++i) {
                let receipt = await nestMining.post2(usdt.address, 30, USDT(3600), ETHER(100000), {
                    value: ETHER(60.49727)
                });
                console.log(await getStatus());
            }

            {
                console.log('*** P1:')
                let receipt = await nestMining.post2(usdt.address, 30, USDT(3600), ETHER(100000), {
                    value: ETHER(60 + 0.1 + 0.096)
                });
                console.log(await getStatus());
            }

            // {
            //     console.log('*** P2:')
            //     let receipt = await nestMining.post2(usdt.address, 30, USDT(3600), ETHER(100000), {
            //         value: ETHER(60 + 0.1 + 0.095)
            //     });
            //     console.log(await getStatus());
            // }
        }
    });
});
