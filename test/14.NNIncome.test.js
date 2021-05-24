const BN = require("bn.js");
//const { expect } = require('chai');
const {  USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const nn = await artifacts.require('NNToken').deployed();
        const usdt = await artifacts.require('USDT').deployed();
        const hbtc = await artifacts.require('HBTC').deployed();
        const nhbtc = await artifacts.require('NHBTC').deployed();
        const nestMining = await artifacts.require('NestMining').deployed();
        const nnIncome = await artifacts.require('NNIncome').deployed();

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
        await nn.transfer(account1, 300);// 30

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

        if (false) {
            // Post a price sheet
            await usdt.approve(nestMining.address, USDT('10000000'));
            await nest.approve(nestMining.address, ETHER('1000000000'));
            await nestMining.post2(usdt.address, 30, USDT(1560), ETHER(1000000), { value: ETHER(60.1)});
            //await nestMining.post(usdt.address, 30, USDT(1560), { value: ETHER(30.099) });
            await skipBlocks(20);
            await nestMining.close(usdt.address, 0);
            await nestMining.close(nest.address, 0);

            //console.log('miningNest: ' + await nnIncome.miningNest());
            let earned = await nnIncome.earned(account0);
            console.log("account1 earned nest: " + earned);

            earned = await nnIncome.earned(account1);
            console.log("account1 earned nest: " + earned);
        }

        if (true) {
            console.log('nn of account0: ' + await nn.balanceOf(account0));
            console.log('nn of account1: ' + await nn.balanceOf(account1));

            console.log('earned of account0: ' + await nnIncome.earned(account0));
            console.log('earned of account1: ' + await nnIncome.earned(account1));

            console.log('getBlockCursor(): ' + await nnIncome.getBlockCursor());
            console.log('blockNumber: ' + await web3.eth.getBlockNumber());

            console.log('nest of account0: ' + await nest.balanceOf(account0));
            console.log('nest of account1: ' + await nest.balanceOf(account1));

            await nnIncome.claim({ from: account0 });
            await nnIncome.claim({ from: account1 });

            let nestBalance0 = await nest.balanceOf(account0);
            let nestBalance1 = await nest.balanceOf(account1);

            console.log('nest of account0: ' + await nest.balanceOf(account0));
            console.log('nest of account1: ' + await nest.balanceOf(account1));

            await skipBlocks(100);

            await nnIncome.claim({ from: account1 });
            await nnIncome.claim({ from: account0 });
        
            console.log('nest of account0: ' + await nest.balanceOf(account0));
            console.log('nest of account1: ' + await nest.balanceOf(account1));

            assert.equal(0, ETHER(103 * 60 * 1200/1500).add(nestBalance0).cmp(await nest.balanceOf(account0)));
            assert.equal(0, ETHER(101 * 60 * 300/1500).add(nestBalance1).cmp(await nest.balanceOf(account1)));
        }

        if (false) {
            
            for (var bn = new BN(800000); bn.cmp(new BN(24000000 * 1.5)) < 0; bn = bn.add(new BN(800000))) {

                let r = await nnIncome._redution(bn); 
                console.log(bn.toString() + ": " + r.toString());

                let b = new BN(400);
                //let z = new BN(1);
                let m = new BN(1);
                let n = bn.div(new BN(2400000));
                if (n.cmp(new BN(10)) < 0) {
                    for (var i = new BN(0); i.cmp(n) < 0; i = i.add(new BN(1))) {
                        //b = b.mul(new BN(80)).div(new BN(100));
                        b = b.mul(new BN(80));
                        m = m.mul(new BN(100));
                    }
                    b = b.div(m);
                    LOG('r: {r}, b: {b}', {r,b});
                    assert.equal(0, r.cmp(b));
                } else {
                    assert.equal(0, r.cmp(new BN(40)));
                }
            }
        }

        if (false) {

            for (var bn = new BN(800000); bn.cmp(new BN(24000000 * 1.5)) < 0; bn = bn.add(new BN(800000))) {

                let r = await nestMining._redution(bn); 
                console.log(bn.toString() + ": " + r.toString());

                let b = new BN(400);
                //let z = new BN(1);
                let m = new BN(1);
                let n = bn.div(new BN(2400000));
                if (n.cmp(new BN(10)) < 0) {
                    for (var i = new BN(0); i.cmp(n) < 0; i = i.add(new BN(1))) {
                        //b = b.mul(new BN(80)).div(new BN(100));
                        b = b.mul(new BN(80));
                        m = m.mul(new BN(100));
                    }
                    b = b.div(m);
                    LOG('r: {r}, b: {b}', {r,b});
                    assert.equal(0, r.cmp(b));
                } else {
                    assert.equal(0, r.cmp(new BN(40)));
                }
            }
        }
    });
});
