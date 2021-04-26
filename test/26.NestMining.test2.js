const BN = require("bn.js");
const { expect } = require('chai');
const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        
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
            console.log('Configuration');

            console.log(await nestMining.getConfig());
            await nestMining.setConfig({
                // Eth number of each post. 30
                // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
                postEthUnit: 10,

                // Post fee(0.0001eth，DIMI_ETHER). 1000
                postFeeUnit: 1000,

                // Proportion of miners digging(10000 based). 8000
                minerNestReward: 8000,
                
                // The proportion of token dug by miners is only valid for the token created in version 3.0
                // (10000 based). 9500
                minerNTokenReward: 9500,

                // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
                doublePostThreshold: 500,
                
                // The limit of ntoken mined blocks. 100
                ntokenMinedBlockLimit: 100,

                // -- Public configuration
                // The number of times the sheet assets have doubled. 4
                maxBiteNestedLevel: 4,
                
                // Price effective block interval. 20
                priceEffectSpan: 20,

                // The amount of nest to pledge for each post（Unit: 1000). 100
                pledgeNest: 100
            });
            console.log(await nestMining.getConfig());
        }

        if (true) {
            console.log('Restore configuration');

            console.log(await nestMining.getConfig());
            await nestMining.setConfig({
                // Eth number of each post. 30
                // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
                postEthUnit: 30,

                // Post fee(0.0001eth，DIMI_ETHER). 1000
                postFeeUnit: 1000,

                // Proportion of miners digging(10000 based). 8000
                minerNestReward: 8000,
                
                // The proportion of token dug by miners is only valid for the token created in version 3.0
                // (10000 based). 9500
                minerNTokenReward: 9500,

                // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
                doublePostThreshold: 500,
                
                // The limit of ntoken mined blocks. 100
                ntokenMinedBlockLimit: 100,

                // -- Public configuration
                // The number of times the sheet assets have doubled. 4
                maxBiteNestedLevel: 4,
                
                // Price effective block interval. 20
                priceEffectSpan: 20,

                // The amount of nest to pledge for each post（Unit: 1000). 100
                pledgeNest: 100
            });
            console.log(await nestMining.getConfig());
        }

        if (true) {
            console.log('closeList()');
            console.log({
                account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                accountCount: (await nestMining.getAccountCount()).toString()
            });
            await nest.setTotalSupply(ETHER(5000000 - 1));
            await usdt.approve(nestMining.address, USDT(10000000));
            await nest.approve(nestMining.address, ETHER(10000000));
            await nestMining.post(usdt.address, 30, USDT(1600), { value: ETHER(30.7) });
            for (var i = 0; i < 30; ++i) {
                await nestMining.close(usdt.address, 0);
                let mi = await nestMining.getMinedBlocks(usdt.address, 0);
                console.log({
                    index: i,
                    usdt: (await nestMining.balanceOf(usdt.address, account0)).toString(),
                    nest: (await nestMining.balanceOf(nest.address, account0)).toString(),
                    mined: {
                        minedBlocks: mi.minedBlocks.toString(),
                        totalShares: mi.totalShares.toString()
                    }
                });
                console.log({
                    account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                    account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                    accountCount: (await nestMining.getAccountCount()).toString()
                });
                if (i < 20) {
                    assert.equal(0, new BN(await nestMining.balanceOf(usdt.address, account0)).cmp(USDT(0)));
                    assert.equal(0, new BN(await nestMining.balanceOf(nest.address, account0)).cmp(ETHER(0)));
                } else {
                    assert.equal(0, new BN(await nestMining.balanceOf(usdt.address, account0)).cmp(USDT(1600 * 30)));
                    assert.equal(0, new BN(await nestMining.balanceOf(nest.address, account0)).cmp(ETHER(100000 + 400 * 10 * 80 / 100)));
                }
            }
        }

        if (true) {
            console.log('closeList2()');
            await nest.setTotalSupply(ETHER('1000000000'));
            await usdt.approve(nestMining.address, USDT(10000000));
            await nest.approve(nestMining.address, ETHER(10000000));
            await nestMining.post2(usdt.address, 30, USDT(1570), ETHER(51200), { value: ETHER(60.3) });
            for (var i = 0; i < 30; ++i) {
                await nestMining.closeList2(usdt.address, [1], [0]);
                let mi = await nestMining.getMinedBlocks(usdt.address, 1);
                console.log({
                    index: i,
                    usdt: (await nestMining.balanceOf(usdt.address, account0)).toString(),
                    nest: (await nestMining.balanceOf(nest.address, account0)).toString(),
                    estimate: (await nestMining.estimate(usdt.address)).toString(),
                    mined: {
                        minedBlocks: mi.minedBlocks.toString(),
                        totalShares: mi.totalShares.toString()
                    }
                });
                console.log({
                    account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                    account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                    accountCount: (await nestMining.getAccountCount()).toString()
                });
                if (i < 20) {
                    assert.equal(0, new BN(await nestMining.balanceOf(usdt.address, account0)).cmp(USDT(1600 * 30 - 1570 * 30)));
                    assert.equal(0, new BN(await nestMining.balanceOf(nest.address, account0)).cmp(ETHER(0)));
                } else {
                    assert.equal(0, new BN(await nestMining.balanceOf(usdt.address, account0)).cmp(USDT(1600 * 30)));
                    assert.equal(0, new BN(await nestMining.balanceOf(nest.address, account0)).cmp(ETHER(200000 + 51200 * 30 + 400 * 34 * 80 / 100)));
                }
            }
        }

        if (true) {
            console.log('list');

            console.log('list1');
            let list = await nestMining.list(usdt.address, 0, 3, 0);
            for (var i in list) {
                console.log(list[i]);
            }

            console.log('list2');
            list = await nestMining.list(usdt.address, 0, 3, 1);
            for (var i in list) {
                console.log(list[i]);
            }

            console.log('list3');
            list = await nestMining.list(nest.address, 0, 3, 0);
            for (var i in list) {
                console.log(list[i]);
            }

            console.log('list4');
            list = await nestMining.list(nest.address, 0, 3, 1);
            for (var i in list) {
                console.log(list[i]);
            }
            console.log({
                account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                accountCount: (await nestMining.getAccountCount()).toString()
            });
        }

        if (false) {
            console.log('getAccountIndex');
            console.log({
                account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                accountCount: (await nestMining.getAccountCount()).toString()
            });
            await nestMining._addressIndex(account1);
            console.log({
                account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                accountCount: (await nestMining.getAccountCount()).toString()
            });
            await nestMining._addressIndex(accounts[2]);
            console.log({
                account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                accountCount: (await nestMining.getAccountCount()).toString()
            });
            await nestMining._addressIndex(accounts[3]);
            console.log({
                account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                accountCount: (await nestMining.getAccountCount()).toString()
            });
            await nestMining._addressIndex(accounts[4]);
            console.log({
                account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                accountCount: (await nestMining.getAccountCount()).toString()
            });
            await nestMining._addressIndex(accounts[5]);
            console.log({
                account0Index: (await nestMining.getAccountIndex(account0)).toString(),
                account1Index: (await nestMining.getAccountIndex(account1)).toString(),
                accountCount: (await nestMining.getAccountCount()).toString()
            });
        }
    });
});
