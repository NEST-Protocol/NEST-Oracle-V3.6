const NToken = artifacts.require('NToken');
const ERC20 = artifacts.require('ERC20');
const BN = require("bn.js");
//const { expect } = require('chai');
const { USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.utils.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        //const { nest, nn, usdt, hbtc,/* nhbtc,*/ nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming, nestGovernance } = await deploy();
        const nest = await artifacts.require('IBNEST').deployed();
        const nn = await artifacts.require('NNToken').deployed();
        const hbtc = await artifacts.require('HBTC').deployed();
        const nestLedger = await artifacts.require('NestLedger').deployed();
        const nestMining = await artifacts.require('NestMining').deployed();
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
        await nest.transfer(nestMining.address, ETHER('8000000000'));

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

        // 1. Get buitin address
        let addresses = await nestGovernance.getBuiltinAddress();
        console.log(addresses);
        
        assert.equal(addresses.nestTokenAddress, await nestGovernance.getNestTokenAddress());
        assert.equal(addresses.nestNodeAddress, await nestGovernance.getNestNodeAddress());
        assert.equal(addresses.nestLedgerAddress, await nestGovernance.getNestLedgerAddress());
        assert.equal(addresses.nestMiningAddress, await nestGovernance.getNestMiningAddress());
        assert.equal(addresses.ntokenMiningAddress, await nestGovernance.getNTokenMiningAddress());
        assert.equal(addresses.nestPriceFacadeAddress, await nestGovernance.getNestPriceFacadeAddress());
        assert.equal(addresses.nestVoteAddress, await nestGovernance.getNestVoteAddress());
        assert.equal(addresses.nestQueryAddress, await nestGovernance.getNestQueryAddress());
        assert.equal(addresses.nnIncomeAddress, await nestGovernance.getNnIncomeAddress());
        assert.equal(addresses.nTokenControllerAddress, await nestGovernance.getNTokenControllerAddress());

        assert.equal(nest.address, await nestGovernance.getNestTokenAddress());
        assert.equal(nn.address, await nestGovernance.getNestNodeAddress());
        assert.equal(nestLedger.address, await nestGovernance.getNestLedgerAddress());
        assert.equal(nestMining.address, await nestGovernance.getNestMiningAddress());
        assert.equal(ntokenMining.address, await nestGovernance.getNTokenMiningAddress());
        assert.equal(nestPriceFacade.address, await nestGovernance.getNestPriceFacadeAddress());
        assert.equal(nestVote.address, await nestGovernance.getNestVoteAddress());
        assert.equal(ntokenMining.address, await nestGovernance.getNestQueryAddress());
        assert.equal(nnIncome.address, await nestGovernance.getNnIncomeAddress());
        assert.equal(nTokenController.address, await nestGovernance.getNTokenControllerAddress());

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

        addresses = await nestGovernance.getBuiltinAddress();
        assert.equal(addresses.nestTokenAddress, await nestGovernance.getNestTokenAddress());
        assert.equal(addresses.nestNodeAddress, await nestGovernance.getNestNodeAddress());
        assert.equal(addresses.nestLedgerAddress, await nestGovernance.getNestLedgerAddress());
        assert.equal(addresses.nestMiningAddress, await nestGovernance.getNestMiningAddress());
        assert.equal(addresses.ntokenMiningAddress, await nestGovernance.getNTokenMiningAddress());
        assert.equal(addresses.nestPriceFacadeAddress, await nestGovernance.getNestPriceFacadeAddress());
        assert.equal(addresses.nestVoteAddress, await nestGovernance.getNestVoteAddress());
        assert.equal(addresses.nestQueryAddress, await nestGovernance.getNestQueryAddress());
        assert.equal(addresses.nnIncomeAddress, await nestGovernance.getNnIncomeAddress());
        assert.equal(addresses.nTokenControllerAddress, await nestGovernance.getNTokenControllerAddress());

        assert.equal(nest.address, await nestGovernance.getNestTokenAddress());
        assert.equal(nn.address, await nestGovernance.getNestNodeAddress());
        assert.equal(nestLedger.address, await nestGovernance.getNestLedgerAddress());
        assert.equal(nestMining.address, await nestGovernance.getNestMiningAddress());
        assert.equal(account1, await nestGovernance.getNTokenMiningAddress());
        assert.equal(nestPriceFacade.address, await nestGovernance.getNestPriceFacadeAddress());
        assert.equal(nestVote.address, await nestGovernance.getNestVoteAddress());
        assert.equal(ntokenMining.address, await nestGovernance.getNestQueryAddress());
        assert.equal(nnIncome.address, await nestGovernance.getNnIncomeAddress());
        assert.equal(nTokenController.address, await nestGovernance.getNTokenControllerAddress());

        console.log('nest.dao.redeeming: ' + await nestGovernance.checkAddress('nest.dao.redeeming'));
        assert.equal(nestRedeeming.address, await nestGovernance.checkAddress('nest.dao.redeeming'));

        await nestGovernance.registerAddress('nest.dao.redeeming', '0x0000000000000000000000000000000000000000');
        console.log('nest.dao.redeeming: ' + await nestGovernance.checkAddress('nest.dao.redeeming'));
    });
});
