
//const { expect } = require('chai');
//require('chai').should();
const { BN, constants, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');

//const CoFiXNode = artifacts.require("CoFiXNode");

const NestMining = artifacts.require("NestMining");
const TestERC20 = artifacts.require("TestERC20");
const IBNEST = artifacts.require("IBNEST");
const NestDAO = artifacts.require("NestDAO");

contract("TestNestMining", async accounts => {
    it('test4', async () => {

        //await accounts[9].sentTransaction(accounts[0], new BN('99000000000000000000'));
        //console.log(await web3.eth.getBalance(accounts[0]));
        //return;
        // for (var i = 1; i < 10; ++i) {
        //     await web3.eth.sendTransaction({ from: accounts[i], to: accounts[0], value: new BN('99000000000000000000')});
        // }
        // return;

        //let ib = await IterableMapping.new();
        let nest = await IBNEST.new();
        let usdt = await TestERC20.new('usdt', 'usdt', 6);
        let nestDao = await NestDAO.new(nest.address);
        let nestMining = await NestMining.new(nest.address, nestDao.address);

        await usdt.transfer(accounts[0], 10000000000000, { from: accounts[1] });

        console.log('报价前: ');
        console.log('nest balance=' + await nest.balanceOf(accounts[0]));
        console.log('usdt balance=' + await usdt.balanceOf(accounts[0]));
        console.log('nest freezen=' + await nestMining.balanceOf(nest.address, accounts[0]));
        console.log('usdt freezen=' + await nestMining.balanceOf(usdt.address, accounts[0]));

        await nest.approve(nestMining.address, new BN('9999999999999999999999999999'));
        await usdt.approve(nestMining.address, new BN('9999999999999999999999999999'));

        let receipt = await nestMining.post2(usdt.address, 30, 1000000 * 1599, 123, { value: new BN('60099000000000000000') });
        console.log(receipt);
        
        console.log('报价后: ');
        console.log('nest balance=' + await nest.balanceOf(accounts[0]));
        console.log('usdt balance=' + await usdt.balanceOf(accounts[0]));
        console.log('nest freezen=' + await nestMining.balanceOf(nest.address, accounts[0]));
        console.log('usdt freezen=' + await nestMining.balanceOf(usdt.address, accounts[0]));

        let sheets = await nestMining.list(usdt.address, 0, 1, 0);
        for (var i in sheets) {
            let sheet = sheets[i];
            console.log(i);
            console.log(sheet);
        }

        receipt = await nestMining.biteToken(usdt.address, 0, 30, 1000000 * 599, { value: new BN('90000000000000000000')});
        console.log(receipt);

        await nestMining.close(usdt.address, 0);
        await nestMining.close(usdt.address, 1);

        // let receipt = await nestMining.post2(usdt.address, 30, 1000000 * 1599, 123, { value: new BN('60099000000000000000') });
        // console.log(receipt);

        // receipt = await nestMining.close(usdt.address, 0);
        // console.log(receipt);

        // receipt = await nestMining.close(nest.address, 0);
        // console.log(receipt);

        // return;

        // receipt = await nestMining.close(usdt.address, 1);
        // console.log(receipt);

        // receipt = await nestMining.post2(usdt.address, 30, 1000000 * 1599, 123, { value: new BN('60099000000000000000') });
        // console.log(receipt);

        // await nestMining.close(usdt.address, 2);
    });
});
