
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

        let nest = await IBNEST.new();
        let usdt = await TestERC20.new('usdt', 'usdt', 6);
        let nestDao = await NestDAO.new(nest.address);
        let nestMining = await NestMining.new(nest.address, nestDao.address);
        
        // //let result = await nestMining.singlePost2('0x47bb09e62b00ae98cf9abdec33a93d07c45b6fe9', 0, new BN('123456789012345678901234567890'));
        // //let result = await nestMining.singlePost2('0x47bb09e62b00ae98cf9abdec33a93d07c45b6fe9', 0, new BN('1234567890100'));
        let result = await nestMining.encodeFloat(new BN('1158748551564310544000'));
        // //let result = await nestMining.singlePost2('0x47bb09e62b00ae98cf9abdec33a93d07c45b6fe9', 0, new BN('281474976710656'));

        console.log('exponent=' + result.exponent + ', fraction=' + result.fraction);
        // 123456789012340000000000000000
        // 123456789012345678901234567890
        // 123456789012344587162184843264
        // 123456789012344587162184843264
        // 44228626498081093993571024896
        // 123456789009998211756324814848
        // 1158748551564310544000
        // 1158748551564308250624
        let v = await nestMining.decodeFloat(result.fraction, result.exponent);
        console.log('rev=' + v)
    });
});
