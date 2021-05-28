const NToken = artifacts.require('NToken');
const ERC20 = artifacts.require('ERC20');

const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance, skipBlocks } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc, /*nhbtc,*/ nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming, nestGovernance } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const nn = await artifacts.require('NNToken').deployed();
        const hbtc = await artifacts.require('HBTC').deployed();
        const nestLedger = await artifacts.require('NestLedger').deployed();
        const ntokenMining = await artifacts.require('NTokenMining').deployed();
        const nestPriceFacade = await artifacts.require('NestPriceFacade').deployed();
        const nTokenController = await artifacts.require('NTokenController').deployed();
        const nestVote = await artifacts.require('NestVote').deployed();
        const nnIncome = await artifacts.require('NNIncome').deployed();
        const nestGovernance = await artifacts.require('NestGovernance').deployed();
        const nestRedeeming = await artifacts.require('NestRedeeming').deployed();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(ntokenMining.address, ETHER('8000000000'));

        // Open nhbtc
        await hbtc.approve(nTokenController.address, 1, { from: account1 });
        await nest.approve(nTokenController.address, ETHER(10000), { from: account1 });
        await nTokenController.setNTokenMapping(hbtc.address, '0x0000000000000000000000000000000000000000', 0);
        await nTokenController.open(hbtc.address, { from: account1 });
        let nhbtcAddress = await nTokenController.getNTokenAddress(hbtc.address);
        let nhbtc = await NToken.at(nhbtcAddress);

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
                    hbtc: await ntokenMining.balanceOf(hbtc.address, account),
                    nhbtc: await ntokenMining.balanceOf(nhbtc.address, account),
                    nest: await ntokenMining.balanceOf(nest.address, account)
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
        assert.equal(0, balance1.balance.hbtc.cmp(HBTC('10000000')));

        // Balance of account0
        assert.equal(0, balance0.balance.hbtc.cmp(HBTC('10000000')));
        assert.equal(0, balance0.balance.nest.cmp(ETHER('1000000000')));
        assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
        assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

        // Balance of nestMining
        assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0)));
        assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(0)));
        assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000)));

        await nest.approve(ntokenMining.address, ETHER('1000000000'));
        await hbtc.approve(ntokenMining.address, HBTC('10000000'));
        await nhbtc.approve(ntokenMining.address, HBTC('10000000'));
        await nest.approve(ntokenMining.address, ETHER('1000000000'), { from: account1 });
        await hbtc.approve(ntokenMining.address, HBTC('10000000'), { from: account1 });
        await nhbtc.approve(ntokenMining.address, HBTC('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let mined = nHBTC(0);
        
        {
            // 1. post
            await ntokenMining.post(hbtc.address, 10, ETHER(256), { value: ETHER(10.1) });
            await ntokenMining.settle(hbtc.address);
            //await ntokenMining.post(nhbtc.address, 10, ETHER(256), { value: ETHER(10.1) });
            console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
            console.log('nestLedger eth: ' + await web3.eth.getBalance(nestLedger.address));
            console.log('');
        }

        {
            // 1. Increase nhbtc
            // Set Builtin Address
            await nestGovernance.setBuiltinAddress(
                nest.address,
                nn.address, //nestNodeAddress,
                nestLedger.address,
                ntokenMining.address,
                account0,
                nestPriceFacade.address,
                nestVote.address,
                ntokenMining.address, //nestQueryAddress,
                nnIncome.address, //nnIncomeAddress,
                nTokenController.address //nTokenControllerAddress
            );
            await nhbtc.update(nestGovernance.address);
            await nhbtc.increaseTotal(ETHER(8000000));
            // Set Builtin Address
            await nestGovernance.setBuiltinAddress(
                nest.address,
                nn.address, //nestNodeAddress,
                nestLedger.address,
                ntokenMining.address,
                ntokenMining.address,
                nestPriceFacade.address,
                nestVote.address,
                ntokenMining.address, //nestQueryAddress,
                nnIncome.address, //nnIncomeAddress,
                nTokenController.address //nTokenControllerAddress
            );
            await nhbtc.update(nestGovernance.address);

            // 2. List all ntoken information
            let list = await nTokenController.list(0, 3, 0);
            for (var i in list) {
                let tag = list[i];
                if (tag.tokenAddress == '0x0000000000000000000000000000000000000000'
                || tag.ntokenAddress == '0x0000000000000000000000000000000000000000') {
                    continue;
                }
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                });
            }
        }

        {
            // 1. post
            await ntokenMining.post2(hbtc.address, 10, ETHER(256), ETHER(51200 + 512 * 4), { value: ETHER(20 + 10) });

            console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
            console.log('nestLedger eth: ' + await web3.eth.getBalance(nestLedger.address));

            await ntokenMining.post2(hbtc.address, 10, ETHER(256), ETHER(51200 + 512 * 3), { value: ETHER(20 + 10) });
            await ntokenMining.post2(hbtc.address, 10, ETHER(256), ETHER(51200 + 512 * 2), { value: ETHER(20 + 10) });
            await ntokenMining.post2(hbtc.address, 10, ETHER(256), ETHER(51200 + 512 * 1), { value: ETHER(20 + 10) });
            await ntokenMining.post2(hbtc.address, 10, ETHER(256), ETHER(51200 + 512 * 0), { value: ETHER(20 + 10) });
            // 2. Show quota of redeeming
            await skipBlocks(20);
            console.log('nhbtc quota: ' + await nestRedeeming.quotaOf(nhbtc.address));
            console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
            console.log('nestLedger eth: ' + await web3.eth.getBalance(nestLedger.address));
            await ntokenMining.settle(hbtc.address);
            console.log();
            console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
            console.log('nestLedger eth: ' + await web3.eth.getBalance(nestLedger.address));

            let arr = [0, 1, 2, 3, 4];
            await ntokenMining.closeList2(hbtc.address, arr, arr);
            await ntokenMining.close(hbtc.address, 5);

            // 3. redeem
            await nhbtc.approve(nestRedeeming.address, ETHER(10000000));
            await nestRedeeming.redeem(nhbtc.address, ETHER(100), account0, { value: ETHER(0.01) });

            // 4. Show quota of redeeming
            console.log('');
            console.log('nhbtc quota: ' + await nestRedeeming.quotaOf(nhbtc.address));
            console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
            await ntokenMining.settle(hbtc.address);
            console.log('nhbtc rewards: ' + await nestLedger.totalETHRewards(nhbtc.address));
            console.log('nest rewards: ' + await nestLedger.totalETHRewards(nest.address));
        }
    });
});
