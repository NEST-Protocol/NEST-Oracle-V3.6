const BN = require("bn.js");
const $hcj = require("./hcore.js");

const NestGovernance = artifacts.require("NestGovernance");
const NestLedger = artifacts.require("NestLedger");
const NestMining = artifacts.require("NestMining");
const NestPriceFacade = artifacts.require("NestPriceFacade");
const NestRedeeming = artifacts.require("NestRedeeming");
const NestVote = artifacts.require("NestVote");
const NNIncome = artifacts.require("NNIncome");
const NToken = artifacts.require("NToken");
const NTokenController = artifacts.require("NTokenController");
const TestERC20 = artifacts.require("TestERC20");
const IBNEST = artifacts.require("IBNEST");
const NNToken = artifacts.require("NNToken");
const Nest_NToken = artifacts.require("Nest_NToken");
const SetQueryPrice = artifacts.require("SetQueryPrice");

const USDT = function(value) { return new BN('1000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const GWEI = function(value) { return new BN('1000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const ETHER = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const HBTC = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const nHBTC = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }

const LOG = function(fmt, ctx) {
    console.log($hcj.fmt(fmt, ctx));
};

const ethBalance = async function(account) {
    return new BN(await web3.eth.getBalance(account));
}

contract("NestMining", async accounts => {
    it('test', async () => {

        const account0 = accounts[0];
        //const account1 = accounts[1];

        /* 
        hbtc: 0x52e669eb87fBF69027190a0ffb6e6fEd48451E04
        usdt: 0xBa2064BbD49454517A9dBba39005bf46d31971f8
        nest: 0xBaa792bba02D82Ebf3569E01f142fc80F72D9b8f
        nest_3_VoteFactory: 0xF4061985d6854965d443c09bE09f29f51708446F
        nhbtc: 0x4269Fee5d9aAC83F1A9a81Cd17Bf71A01240765a
        nn: 0xF6298cc65E84F6a6D67Fa2890fbD2AD8735e3c29
        nestGovernance: 0xad33e1B199265dEAE3dfe4eB49B9FcaB824268E3
        nestLedger: 0x239C1421fEC5cc00695584803F52188A9eD92ef2
        nestMining: 0x7d919aaC07Ec3a7330a0C940F711abb6a6599E23
        nestPriceFacade: 0x0d3Be4D8F602469BbdF9CDEA3fA59293EFeB223B
        nestRedeeming: 0x146Af6aE0c93e9Aca1a39A644Ee7728bA9ddFA7c
        nestVote: 0xC75bd10B11E498083075876B3D6e1e6df1427De6
        nnIncome: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
        nTokenController: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
        setQueryPrice: 0x661D928e196797389Af5826BFE590345E0E2d6C0
        */

        let nestMining = await NestMining.at('0x7d919aaC07Ec3a7330a0C940F711abb6a6599E23');

        let arr = [];
        let start = 8283851;
        let end = 8318367 + 10000;
        while(start < end) {
            arr.push(start);
            start += 100;
        }
        for (var i in arr) {
            let pi = await nestMining.findPrice('0xBa2064BbD49454517A9dBba39005bf46d31971f8', arr[i]);
            LOG('dist: {dist}, blockNumber: {pi.blockNumber}, price: {pi.price}', { dist: arr[i], pi: pi });
        }
    });
});
