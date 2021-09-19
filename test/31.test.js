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
const INestPriceFacade = artifacts.require('INestPriceFacade');
const NTokenController = artifacts.require('NTokenController');
const NestVote = artifacts.require('NestVote');
const NestMining = artifacts.require('NestMining');
const NestRedeeming = artifacts.require('NestRedeeming');
const NNIncome = artifacts.require('NNIncome');
const INestQuery = artifacts.require('INestQuery');

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

        //const { nest, nn, usdt, hbtc, nhbtc, nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming, nestGovernance } = await deploy();
        const account0 = accounts[0];
        console.log('account0: ' + account0);
        // let ua = await UpdateAdmin.new('0x79BAD49d6f76c7f0Ed6CD8E93A198a6E29765179');
        // console.log('ua: ' + ua.address);
        // await ua.setAddress(account0, 2);
        // return;
        /*
        2021-04-27
        proxy
        nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
        usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7
        nestGovernance: 0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5
        nestLedger: 0x34B931C7e5Dc45dDc9098A1f588A0EA0dA45025D
        nTokenController: 0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62
        nestVote: 0xDa52f53a5bE4cb876DE79DcfF16F34B95e2D38e9
        nestMining: 0x03dF236EaCfCEf4457Ff7d6B88E8f00823014bcd
        ntokenMining: 0xC2058Dd4D55Ae1F3e1b0744Bdb69386c9fD902CA
        nestPriceFacade: 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A
        nestRedeeming: 0xF48D58649dDb13E6e29e03059Ea518741169ceC8
        nnIncome: 0x95557DE67444B556FE6ff8D7939316DA0Aa340B2
        nn: 0xC028E81e11F374f7c1A3bE6b8D2a815fa3E96E6e

        implementation
        nestGovernance: 0x6D76935090FB8b8B73B39F03243fAd047B0794C0
        nestLedger: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
        nTokenController: 0x6C4BD6148F72b525f72b8033D6dD5C5aC4C9DCB7
        nestVote: 0xBBf3E1B2901AcCc3fDe5A4971903a0aBC6CA04CA
        nestMining: 0xE34A736290548227415329962705a6ee17c5f1a5
                 -> 0xcDAB36F3A9d4705a0F27Bfde64D770597945376A
                 -> 0xaa6238bA1b26113278B0A00dBbc14b35700E0586
        ntokenMining: 0xE34A736290548227415329962705a6ee17c5f1a5
                 -> 0xcDAB36F3A9d4705a0F27Bfde64D770597945376A
                 -> 0xaa6238bA1b26113278B0A00dBbc14b35700E0586
        nestPriceFacade: 0xD0B5532Cd0Ae1a14dAdf94f8562679A48aDa3643
                    -> 0x7D58E982Ac043716B2b8002B16744233cB722211
                    -> 0x200FFB773535c5c1aAD8a24bB9E43a2C93910D43
        nestRedeeming: 0x5441B24FA3a2347Ac6EE70431dD3BfD0c224B4B7
        nnIncome: 0x718626a4b78e0ECfA60dE1D4C386302e68fac8cD
        */
        // let proxyAdmin = await IProxyAdmin.at('0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6');
        // console.log('nestGovernance: ' + await proxyAdmin.getProxyImplementation(nestGovernance.address));
        // console.log('nestLedger: ' + await proxyAdmin.getProxyImplementation(nestLedger.address));
        // console.log('nTokenController: ' + await proxyAdmin.getProxyImplementation(nTokenController.address));
        // console.log('nestVote: ' + await proxyAdmin.getProxyImplementation(nestVote.address));
        // console.log('nestMining: ' + await proxyAdmin.getProxyImplementation(nestMining.address));
        // console.log('ntokenMining: ' + await proxyAdmin.getProxyImplementation(ntokenMining.address));
        // console.log('nestPriceFacade: ' + await proxyAdmin.getProxyImplementation(nestPriceFacade.address));
        // console.log('nestRedeeming: ' + await proxyAdmin.getProxyImplementation(nestRedeeming.address));
        // console.log('nnIncome: ' + await proxyAdmin.getProxyImplementation(nnIncome.address));

        
        if (true) {
            let newNestMining = await NestMining.new();
            // newNestMiningImpl: 0x24AC69F7810e5a929795E0675beB7994CA23B25a
            console.log('newNestMiningImpl: ' + newNestMining.address);
            return;
        }

        if (false) {
            let nestMining = await NestMining.at('0x03dF236EaCfCEf4457Ff7d6B88E8f00823014bcd');
            let ntokenMining = await NestMining.at('0xC2058Dd4D55Ae1F3e1b0744Bdb69386c9fD902CA');
            let nestRedeeming = await NestRedeeming.at('0xF48D58649dDb13E6e29e03059Ea518741169ceC8');

            console.log('21. nestMining.setConfig()');
            await nestMining.setConfig({
            
                // Eth number of each post. 30
                // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
                postEthUnit: 10,
        
                // Post fee(0.0001eth，DIMI_ETHER). 1000
                postFeeUnit: 100,
        
                // Proportion of miners digging(10000 based). 8000
                minerNestReward: 8000,
                
                // The proportion of token dug by miners is only valid for the token created in version 3.0
                // (10000 based). 9500
                minerNTokenReward: 9500,
        
                // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
                doublePostThreshold: 500,
                
                // The limit of ntoken mined blocks. 100
                ntokenMinedBlockLimit: 300,
        
                // -- Public configuration
                // The number of times the sheet assets have doubled. 4
                maxBiteNestedLevel: 4,
                
                // Price effective block interval. 20
                priceEffectSpan: 20,
        
                // The amount of nest to pledge for each post (Unit: 1000). 100
                pledgeNest: 100
            });

            console.log('22. ntokenMining.setConfig()');
            await ntokenMining.setConfig({
            
                // Eth number of each post. 30
                // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
                postEthUnit: 1,
        
                // Post fee(0.0001eth，DIMI_ETHER). 1000
                postFeeUnit: 100,
        
                // Proportion of miners digging(10000 based). 8000
                minerNestReward: 8000,
                
                // The proportion of token dug by miners is only valid for the token created in version 3.0
                // (10000 based). 9500
                minerNTokenReward: 9500,
        
                // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
                doublePostThreshold: 500,
                
                // The limit of ntoken mined blocks. 100
                ntokenMinedBlockLimit: 300,
        
                // -- Public configuration
                // The number of times the sheet assets have doubled. 4
                maxBiteNestedLevel: 4,
                
                // Price effective block interval. 20
                priceEffectSpan: 20,
        
                // The amount of nest to pledge for each post (Unit: 1000). 100
                pledgeNest: 100
            });

            console.log('24. nestRedeeming.setConfig()');
            await nestRedeeming.setConfig({

                // Redeem activate threshold, when the circulation of token exceeds this threshold, 
                // activate redeem (Unit: 10000 ether). 500 
                activeThreshold: 500,
        
                // The number of nest redeem per block. 1000
                nestPerBlock: 10000,
        
                // The maximum number of nest in a single redeem. 300000
                nestLimit: 3000000,
        
                // The number of ntoken redeem per block. 10
                ntokenPerBlock: 100,
        
                // The maximum number of ntoken in a single redeem. 3000
                ntokenLimit: 30000,
        
                // Price deviation limit, beyond this upper limit stop redeem (10000 based). 500
                priceDeviationLimit: 1000
            });
        }
    });
});
