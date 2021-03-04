
//const { expect } = require('chai');
//require('chai').should();
//const { BN, constants, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const BN = require("bn.js");
const $hcj = require("./hcore.js");

//const CoFiXNode = artifacts.require("CoFiXNode");

const NestMining = artifacts.require("NestMining");
const TestERC20 = artifacts.require("TestERC20");
const IBNEST = artifacts.require("IBNEST");
const NestDAO = artifacts.require("NestDAO");

const USDT = function(value) { return new BN('1000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const GWEI = function(value) { return new BN('1000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const ETHER = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }

const LOG = function(fmt, ctx) {
    console.log($hcj.fmt(fmt, ctx));
};

contract("TestNestMining", async accounts => {
    it('test4', async () => {

        // await web3.eth.sendTransaction({ from: accounts[0], to: accounts[1], value: ETHER(500) });
        // return;
        for (var i = 2; i < 10; ++i) {
            await web3.eth.sendTransaction({ from: accounts[i], to: accounts[0], value: new BN('99000000000000000000')});
        }
        return;
    });
});
