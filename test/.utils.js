const $hcj = require("./hcore.js");
const BN = require("bn.js");

module.exports = {
    USDT: function(value) { return new BN('1000000').mul(new BN(value * 1000000)).div(new BN('1000000')); },
    GWEI: function(value) { return new BN('1000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); },
    ETHER: function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); },
    HBTC: function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); },
    nHBTC: function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); },
    
    LOG: function(fmt, ctx) {
        console.log($hcj.fmt(fmt, ctx));
    },

    ethBalance: async function(account) {
        return new BN(await web3.eth.getBalance(account));
    }
}