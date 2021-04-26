const BN = require("bn.js");
const { expect } = require('chai');
const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        
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

        if (false) {
            console.log('collect');
            
            await nest.setTotalSupply(ETHER(5000000 - 1));
            await nest.approve(nestMining.address, ETHER(2000000000));
            await usdt.approve(nestMining.address, USDT(2000000000));

            let arr = [];
            let total = ETHER(0);
            for (var i = 1; i < 100; ++i) {
                await nestMining.post(usdt.address, 30, USDT(1000 + i * 10), { value: ETHER(30).add(ETHER(0.1).mul(new BN(i))) });
                console.log({
                    index: i,
                    nestMining: (await ethBalance(nestMining.address)).toString(),
                    nestLedger: (await ethBalance(nestLedger.address)).toString(),
                    nestReward: (await nestLedger.totalETHRewards(nest.address)).toString(),
                    nhbtcReward: (await nestLedger.totalETHRewards(nhbtc.address)).toString()
                });
                total = total.add(ETHER(0.1).mul(new BN(i)));
                assert.equal(0, (await ethBalance(nestLedger.address)).cmp(total));
                assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(total));
                arr.push(i - 1);
            }

            await skipBlocks(20);
            await nestMining.closeList(usdt.address, arr);
        }

        if (true) {
            console.log('collect');
            
            await nest.setTotalSupply(ETHER(5000000 - 1));
            await nest.approve(nestMining.address, ETHER(9000000000));
            await usdt.approve(nestMining.address, USDT(9000000000));

            let total = ETHER(0);
            let N = 700;
            for (var i = 1; i < N; ++i) {
                let d = ETHER(0);
                if (i % 100 == 0) {
                    d = ETHER(7);
                }
                await nestMining.post(usdt.address, 30, USDT(1000 + i * 10), { value: ETHER(30).add(d).add(ETHER(0.1).mul(new BN(1))) });
                if (i % 7 == 0) {
                    await nestMining.settle(usdt.address);
                }
                if (i % 47 == 0) {
                    let n = 16;
                    for (var j = 1; j < n; ++j) {
                        let eth = 60;
                        if (j > 4) {
                            eth = 30;
                        }
                        let receipt = await nestMining.takeToken(usdt.address, i + j + (n - 1) * (i / 47 - 1) - 2, 30, USDT(1000), { value : ETHER(eth + 30) });
                        console.log(receipt);
                        console.log({
                            index: 'takeToken-' + j,
                            nestMining: (await ethBalance(nestMining.address)).toString(),
                            nestLedger: (await ethBalance(nestLedger.address)).toString(),
                            nestReward: (await nestLedger.totalETHRewards(nest.address)).toString(),
                            nhbtcReward: (await nestLedger.totalETHRewards(nhbtc.address)).toString()
                        });
                    }
                }
                console.log({
                    index: i,
                    nestMining: (await ethBalance(nestMining.address)).toString(),
                    nestLedger: (await ethBalance(nestLedger.address)).toString(),
                    nestReward: (await nestLedger.totalETHRewards(nest.address)).toString(),
                    nhbtcReward: (await nestLedger.totalETHRewards(nhbtc.address)).toString()
                });
                // let getSettleInfo = await nestMining.getSettleInfo(usdt.address);
                // console.log({
                //     length: getSettleInfo.length.toString(),
                //     fl: getSettleInfo.fl.toString()
                // });
                total = total.add(ETHER(0.1).mul(new BN(i)));
                //assert.equal(0, (await ethBalance(nestLedger.address)).cmp(total));
                //assert.equal(0, (await nestLedger.totalETHRewards(nest.address)).cmp(total));
            }
            //arr.push(99);
            //arr.push(100);
            await nestMining.settle(usdt.address);
            console.log({
                index: '-',
                nestMining: (await ethBalance(nestMining.address)).toString(),
                nestLedger: (await ethBalance(nestLedger.address)).toString(),
                nestReward: (await nestLedger.totalETHRewards(nest.address)).toString(),
                nhbtcReward: (await nestLedger.totalETHRewards(nhbtc.address)).toString()
            });

            await skipBlocks(20);
            
            let arr = [];
            for (var i = 0; i < N - 1; ++i) {
                arr.push(i);
                if (i % 100 == 99 || i == N - 2) {
                    await nestMining.closeList(usdt.address, arr);
                    arr = [];
                }
            }
        }
    });
});
