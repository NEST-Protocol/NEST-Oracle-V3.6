const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

const IBNEST = artifacts.require('IBNEST');
const NNToken = artifacts.require('NNToken');
const SuperMan = artifacts.require('SuperMan');
const TestERC20 = artifacts.require('TestERC20');
const Nest_NToken = artifacts.require('Nest_NToken');
const NToken = artifacts.require('NToken');
const NestGovernance = artifacts.require('NestGovernance');
const NestLedger = artifacts.require('NestLedger');
const NestPriceFacade = artifacts.require('NestPriceFacade');
const NTokenController = artifacts.require('NTokenController');
const NestVote = artifacts.require('NestVote');
const NestMining = artifacts.require('NestMining');
const NestRedeeming = artifacts.require('NestRedeeming');
const NNIncome = artifacts.require('NNIncome');

const UpdateProxyPropose = artifacts.require('UpdateProxyPropose');
const IProxyAdmin = artifacts.require('IProxyAdmin');
const NestMining2 = artifacts.require('NestMining2');
const ITransferable = artifacts.require('ITransferable');
const UpdateAdmin = artifacts.require('UpdateAdmin');
//const NEST36Update = artifacts.require('NEST36Update');

const $hcj = require("./hcore.js");
const BN = require("bn.js");
const { expect } = require('chai');
const { deployProxy, upgradeProxy, admin } = require('@openzeppelin/truffle-upgrades');

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming, nestGovernance } = await deploy();
        const account0 = accounts[0];
        
        //let nestMining = await NestMining.at('0xe8Bec71aeac191bbf4c870f927fE8fFaAEd9efc8');
        //let usdt = await TestERC20.at('0xe3972ff989f8ac7d6950b4bcce2d7e39b3f8a83f');
        //await nestMining.closeList2('0xe3972ff989f8ac7d6950b4bcce2d7e39b3f8a83f', [5], [5]);

        // updateAdmin: 0xd8C3cc981394d671939E1c51a99f70e13896162e
        //let tr = await UpdateAdmin.at('0xd8C3cc981394d671939E1c51a99f70e13896162e');
        //await tr.setAddress(account0, 1);

        // let nTokenController = await NTokenController.at('0x51C7a4CDe357aeC596337161Bf40a682BEf61D82');
        // let list = await nTokenController.list(0, 60, 0);

        // for (var i in list) {
        //     var tag = list[i];
        //     console.log(tag);
        // }

        // nest36Update2: 0x7870317a2183A849d1AAe5C44B55771ceA09457b
        // let nest36Update = await NEST36Update.new();//('0x7870317a2183A849d1AAe5C44B55771ceA09457b');
        // console.log('nest36Update: ' + nest36Update.address);
        // return;
        //let nestGovernance = await NestGovernance.at('0xA2D58989ef9981065f749C217984DB21970fF0b7');
        //await nestGovernance.setGovernance(nest36Update.address, 1);
        //await nest36Update.setNToken();

        if (false) {
        
            let totalEth = await web3.eth.getBalance(nestLedger.address);
            let nestReward = await nestLedger.totalETHRewards(nest.address);
            let nhhbtcReward = await nestLedger.totalETHRewards('0xdB61D250372fb1c4BD49CE34C0caCaBeFe575592');
            console.log('totalEth: ' + totalEth.toString());
            console.log('nestReward: ' + nestReward.toString());
            console.log('nhhbtcReward: ' + nhhbtcReward.toString());

            console.log('nTokenCount: ' + await nTokenController.getNTokenCount());
        }

        if (false) {

            console.log('usdt: ' + await usdt.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
            //usdt: 10000000000000
            //nest: 10000000000000000000000000
            //      10000000000000000000000000.0
            //await usdt.approve(nestMining.address, USDT(10000000));
            //await nest.approve(nestMining.address, ETHER(10000000));

            let receipt = await nestMining.post2(usdt.address, 30, USDT(1600), ETHER(600), { value: ETHER(60.1) });
            console.log(receipt);
        }

        if (false) {

            let receipt = await nestMining.closeList2(usdt.address, [2], [2]);
            console.log(receipt);
        }

        if (false) {

            await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account0));
            await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account0));
            console.log('usdt: ' + await usdt.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
        }

        if (false) {
            //usdt: 10000000000000
            //nest: 10027520000000000000000000
            console.log('nn: ' + await nn.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
            await nn.transfer(account0, 0);
            console.log('nn: ' + await nn.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
        }
        
        if (false) {
            //usdt: 10000000000000
            //nest: 10027520000000000000000000
            console.log('nn: ' + await nn.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
            await nnIncome.claim();
            console.log('nn: ' + await nn.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));

            //nn: 0x52Ab1592d71E20167EB657646e86ae5FC04e9E01
            //nn: 100
            //nest: 10028192000000000000000000
            //nn: 100
            //nest: 10028272000000000000000000
        }

        if (true) {
            // nTokenCount: 21
            // YFI: 0xCF46fA1879757A5B523bF2BFF3b7fD82Fa56F622
            // nYFI-name: NToken0021
            // nYFI-symbol: N0021
            // nYFI-bidder: 0x0C5E0FBd686B2AB85328A1487A37ad336Ab89aee
            let nTokenCount = await nTokenController.getNTokenCount();
            console.log('nTokenCount: ' + nTokenCount);

            let YFI = await TestERC20.new('YFI', 'YFI', 18);
            console.log('YFI: ' + YFI.address);
            await YFI.transfer(account0, ETHER(10000000));
            await YFI.approve(nTokenController.address, 1);
            await nest.approve(nTokenController.address, ETHER(10000));
            let receipt = await nTokenController.open(YFI.address);
            console.log(receipt);

            let nYFIaddress = await nTokenController.getNTokenAddress(YFI.address);
            let nYFI = await NToken.at(nYFIaddress);
            console.log('nYFI-name: ' + await nYFI.name());
            console.log('nYFI-symbol: ' + await nYFI.symbol());
            console.log('nYFI-bidder: ' + await nYFI.checkBidder());
        }
    });
});
