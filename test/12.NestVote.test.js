const SetQueryPrice = artifacts.require('SetQueryPrice');
const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance, skipBlocks } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming, nestGovernance } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const hbtc = await artifacts.require('HBTC').deployed();
        const nhbtc = await artifacts.require('NHBTC').deployed();
        const nestMining = await artifacts.require('NestMining').deployed();
        const nestPriceFacade = await artifacts.require('NestPriceFacade').deployed();
        const nestVote = await artifacts.require('NestVote').deployed();
        const nestGovernance = await artifacts.require('NestGovernance').deployed();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // Initialize usdt balance
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(nestMining.address, ETHER('8000000000'));

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

        let balance0 = await showBalance(account0, 'account0');
        let balance1 = await showBalance(account1, 'account1');
        assert.equal(0, balance1.balance.hbtc.cmp(HBTC('10000000')));

        // Balance of account0
        assert.equal(0, balance0.balance.hbtc.cmp(HBTC('10000000')));
        assert.equal(0, balance0.balance.nest.cmp(ETHER('1000000000')));
        assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
        assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

        // Balance of nestMining
        assert.equal(0, (await ethBalance(nestMining.address)).cmp(ETHER(0)));
        assert.equal(0, (await hbtc.balanceOf(nestMining.address)).cmp(HBTC(0)));
        assert.equal(0, (await nest.balanceOf(nestMining.address)).cmp(ETHER(8000000000)));

        await nest.approve(nestMining.address, ETHER('1000000000'));
        await hbtc.approve(nestMining.address, HBTC('10000000'));
        await nest.approve(nestMining.address, ETHER('1000000000'), { from: account1 });
        await hbtc.approve(nestMining.address, HBTC('10000000'), { from: account1 });

        // getConfig()
        let config = await nestPriceFacade.getConfig();
        console.log(config);
        // Start a proposal by account1
        await nest.approve(nestVote.address, ETHER('1000000000'));
        await nest.approve(nestVote.address, ETHER('1000000000'), { from: account1 });

        // propose(address contractAddress, string memory brief) override external noContract
        let setQueryPrice = await SetQueryPrice.new(nestGovernance.address, { from: account1 });
        await nestVote.propose(setQueryPrice.address, '修改配置', { from: account1 });

        // account0 vote

        let p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(0, ETHER('319999999'), { from: account0 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(0, ETHER('700000000'), { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(0, ETHER('1'), { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');

        // Execute by account1
        await nestVote.execute(0);

        await nestVote.withdraw(0);
        await nestVote.withdraw(0, { from: account1 });

        // getConfig()
        config = await nestPriceFacade.getConfig();
        console.log(config);

        // config
        console.log('Before setConfig()');
        console.log(await nestVote.getConfig());

        await nestVote.setConfig({
            // Proportion of votes required (10000 based). 5100
            acceptance: 8100,

            // Voting time cycle (seconds). 5 * 86400
            voteDuration: 86400,

            // The number of nest votes need to be staked. 100000 nest
            proposalStaking: '1234567890123'
        });
        console.log('After setConfig()');
        console.log(await nestVote.getConfig());

        // view
        console.log('getProposeCount() = ' + await nestVote.getProposeCount());
        let list = await nestVote.list(0, 2, 0);
        for (var i in list) {
            console.log(list[i]);
        }

        // vote2
        let setQueryPrice2 = await SetQueryPrice.new(nestGovernance.address, { from: account0 });
        await nestVote.propose(setQueryPrice2.address, 'Restore configuration', { from: account0 });
        
        await nest.approve(nestVote.address, ETHER('1000000000'));
        await nest.approve(nestVote.address, ETHER('1000000000'), { from: account1 });
        
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(1, ETHER('319999999'), { from: account0 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(1, ETHER('700000000'), { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(1, ETHER('1'), { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(1, ETHER('610000000'), { from: account0 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');

        await nestVote.execute(1);

        await nestVote.withdraw(1);
        await nestVote.withdraw(1, { from: account1 });

        // vote3
        await nestVote.setConfig({
            // Proportion of votes required (10000 based). 5100
            acceptance: 8100,

            // Voting time cycle (seconds). 5 * 86400
            voteDuration: 5,

            // The number of nest votes need to be staked. 100000 nest
            proposalStaking: '100000000000000000000000'
        });

        let setQueryPrice3 = await SetQueryPrice.new(nestGovernance.address, { from: account0 });
        await nestVote.propose(setQueryPrice3.address, 'Cancel propose', { from: account0 });
        
        await nest.approve(nestVote.address, ETHER('1000000000'));
        await nest.approve(nestVote.address, ETHER('1000000000'), { from: account1 });
        
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(2, ETHER('319999999'), { from: account0 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(2, ETHER('700000000'), { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(2, ETHER('1'), { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(2, ETHER('610000000'), { from: account0 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');

        await skipBlocks(200);
        await nestVote.cancel(2);

        await nestVote.withdraw(2);
        await nestVote.withdraw(2, { from: account1 });

        // vote4
        let setQueryPrice4 = await SetQueryPrice.new(nestGovernance.address, { from: account0 });
        await nestVote.propose(setQueryPrice3.address, 'Cancel propose', { from: account0 });
        
        await nest.approve(nestVote.address, ETHER('1000000000'));
        await nest.approve(nestVote.address, ETHER('1000000000'), { from: account1 });
        
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(3, ETHER('319999999'), { from: account0 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(3, ETHER('700000000'), { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(3, ETHER('1'), { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.vote(3, ETHER('610000000'), { from: account0 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');

        console.log('Cancel ...');
        await nestVote.withdraw(3);
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');
        await nestVote.withdraw(3, { from: account1 });
        p = (await nestVote.list(0, 1, 0))[0];
        console.log('Gain rate: ' + (100.0 * p.gainValue / p.nestCirculation) + '%');

        await skipBlocks(200);
        await nestVote.cancel(3);

        let plist = await nestVote.list(0, 5, 0);
        for (var i in plist) {
            console.log(plist[i]);
        }
    });
});
