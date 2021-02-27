
//const { expect } = require('chai');
//require('chai').should();
const { BN, constants, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');

//const CoFiXNode = artifacts.require("CoFiXNode");

const NestMining = artifacts.require("NestMining");
const TestERC20 = artifacts.require("TestERC20");
const IBNEST = artifacts.require("IBNEST");
const NestDAO = artifacts.require("NestDAO");

contract("TestNestMining", async accounts => {
    it('test1', async () => {

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

        // let rec = await nestMining.test(1);
        // console.log(rec);
        // return;

        // let r = await nestMining.test(100);
        // console.log(r);
        // return;

        await usdt.transfer(accounts[0], 10000000000000, { from: accounts[1] });

        console.log('报价前: ');
        console.log('nest balance=' + await nest.balanceOf(accounts[0]));
        console.log('usdt balance=' + await usdt.balanceOf(accounts[0]));
        console.log('nest freezen=' + await nestMining.balanceOf(nest.address, accounts[0]));
        console.log('usdt freezen=' + await nestMining.balanceOf(usdt.address, accounts[0]));

        await nest.approve(nestMining.address, new BN('9999999999999999999999999999'));
        await usdt.approve(nestMining.address, new BN('9999999999999999999999999999'));
        let receipt = await nestMining.post(usdt.address, 30, 1000000 * 1599, { value: new BN('30099000000000000000') });
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

        receipt = await nestMining.post(usdt.address, 30, 1000000 * 1599, { value: new BN('30099000000000000000') });
        console.log(receipt);

        receipt = await nestMining.close(usdt.address, 0);
        console.log(receipt);

        receipt = await nestMining.close(usdt.address, 1);
        console.log(receipt);

        receipt = await nestMining.post(usdt.address, 30, 1000000 * 1599, { value: new BN('30099000000000000000') });
        console.log(receipt);

        await nestMining.close(usdt.address, 2);

        // // //let result = await nestMining.singlePost2('0x47bb09e62b00ae98cf9abdec33a93d07c45b6fe9', 0, new BN('123456789012345678901234567890'));
        // // //let result = await nestMining.singlePost2('0x47bb09e62b00ae98cf9abdec33a93d07c45b6fe9', 0, new BN('1234567890100'));
        // let result = await nestMining.encodeFloat(new BN('1158748551564310544000'));
        // // //let result = await nestMining.singlePost2('0x47bb09e62b00ae98cf9abdec33a93d07c45b6fe9', 0, new BN('281474976710656'));

        // console.log('exponent=' + result.exponent + ', fraction=' + result.fraction);
        // // 123456789012340000000000000000
        // // 123456789012345678901234567890
        // // 123456789012344587162184843264
        // // 123456789012344587162184843264
        // // 44228626498081093993571024896
        // // 123456789009998211756324814848
        // // 1158748551564310544000
        // // 1158748551564308250624
        // let v = await nestMining.decodeFloat(result.fraction, result.exponent);
        // console.log('rev=' + v)
    });
});
