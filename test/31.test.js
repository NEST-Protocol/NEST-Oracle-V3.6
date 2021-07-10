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
        ntokenMining: 0xE34A736290548227415329962705a6ee17c5f1a5
                 -> 0xcDAB36F3A9d4705a0F27Bfde64D770597945376A
        nestPriceFacade: 0xD0B5532Cd0Ae1a14dAdf94f8562679A48aDa3643
                    -> 0x7D58E982Ac043716B2b8002B16744233cB722211
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

        //let nestPriceFacade = await INestPriceFacade.at('0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A');
        let nestMining = await NestMining.at('0x03dF236EaCfCEf4457Ff7d6B88E8f00823014bcd');
        let ntokenMining = await NestMining.at('0xC2058Dd4D55Ae1F3e1b0744Bdb69386c9fD902CA');

        console.log('21. nestMining.setConfig()');
        await nestMining.setConfig({
        
            // Eth number of each post. 30
            // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
            postEthUnit: 10,
    
            // Post fee(0.0001eth，DIMI_ETHER). 1000
            postFeeUnit: 200,
    
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
    
            // The amount of nest to pledge for each post（Unit: 1000). 100
            pledgeNest: 100
        });

        console.log('22. ntokenMining.setConfig()');
        await ntokenMining.setConfig({
        
            // Eth number of each post. 30
            // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
            postEthUnit: 1,
    
            // Post fee(0.0001eth，DIMI_ETHER). 1000
            postFeeUnit: 200,
    
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
    
            // The amount of nest to pledge for each post（Unit: 1000). 100
            pledgeNest: 100
        });

        return;

        if (false) {
            let npf = await INestPriceFacade.at(nestPriceFacade.address);
            for (var i = 0; i < 200; ++i) {
                console.log('调用: ' + i);
                await npf.latestPriceAndTriggeredPriceInfo(usdt.address, account0, { value : ETHER(0.01)});
                console.log({
                    nestPriceFacade: (await ethBalance(npf.address)).toString(),
                    nestLedger: (await ethBalance(nestLedger.address)).toString()
                });
                console.log('getTokenFee()=' + await npf.getTokenFee(usdt.address));
            }
        }

        if (false) {
            let nTokenController = await NTokenController.at('0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62');
            let nestLedger = await NestLedger.at('0x34B931C7e5Dc45dDc9098A1f588A0EA0dA45025D');
            let nTokenCount = await nTokenController.getNTokenCount();
            console.log('nTokenCount=' + nTokenCount);
            let nTokenList = await nTokenController.list(0, nTokenCount, 1);
            let total = new BN('0');
            //console.log(nTokenList);
            for (var i in nTokenList) {
                let tag = nTokenList[i];
                console.log('tokenAddress: ' + tag.tokenAddress + ", ntokenAddress=" + tag.ntokenAddress);
                let rewards = new BN(await nestLedger.totalETHRewards(tag.ntokenAddress));
                total = total.add(rewards);
                console.log('rewards=' + rewards.toString());
                let token = await TestERC20.at(tag.tokenAddress);
                let ntoken = await TestERC20.at(tag.ntokenAddress);

                let inf = {
                    index: i + ' - ' + tag.index,
                    tokenAddress: tag.tokenAddress,
                    ntokenAddress: tag.ntokenAddress,
                    state: tag.state,
                    tokenName: await token.name(),
                    ntokenName: await ntoken.name(),
                    ntokenTotalSupply: (await ntoken.totalSupply()).toString()
                };
                console.log(inf);
            }

            console.log('tatalRewards: ' + total.toString());
        }

        return;

        if (false) {
            console.log('1. Check rewards for NestLedger');
            let totalEth = await web3.eth.getBalance(nestLedger.address);
            let nestReward = await nestLedger.totalETHRewards(nest.address);
            let nhhbtcReward = await nestLedger.totalETHRewards('0xdB61D250372fb1c4BD49CE34C0caCaBeFe575592');
            console.log('totalEth: ' + totalEth.toString());
            console.log('nestReward: ' + nestReward.toString());
            console.log('nhbtcReward: ' + nhhbtcReward.toString());

            console.log('nTokenCount: ' + await nTokenController.getNTokenCount());
        }

        if (false) {

            console.log('2. Post2');
            console.log('usdt: ' + await usdt.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
            //usdt: 10000000000000
            //nest: 10000000000000000000000000
            //      10000000000000000000000000.0
            await usdt.approve(nestMining.address, USDT(10000000));
            await nest.approve(nestMining.address, ETHER(10000000));

            let receipt = await nestMining.post2(usdt.address, 30, USDT(1600), ETHER(600), { value: ETHER(60.1) });
            console.log(receipt);
        }

        if (false) {

            console.log('3. CloseList2');
            let receipt = await nestMining.closeList2(usdt.address, [0], [0]);
            console.log(receipt);
        }

        if (false) {

            console.log('4. Withdraw');
            await nestMining.withdraw(usdt.address, await nestMining.balanceOf(usdt.address, account0));
            await nestMining.withdraw(nest.address, await nestMining.balanceOf(nest.address, account0));
            console.log('usdt: ' + await usdt.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
        }

        if (false) {
        
            console.log('5. NestNode transfer');
            //usdt: 10000000000000
            //nest: 10027520000000000000000000
            console.log('nn: ' + await nn.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
            await nn.transfer(account0, 0);
            console.log('nn: ' + await nn.balanceOf(account0));
            console.log('nest: ' + await nest.balanceOf(account0));
        }
        
        if (false) {

            console.log('6. NestNode claim');
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

        if (false) {
            console.log('6.1. list tokens');
            let list = await nTokenController.list(0, 60, 1);
            for (var i in list) {
                var tag = list[i];
                console.log(tag);
            }
        }

        if (false) {
            console.log('7. nTokenController.open');
            // nTokenCount: 21
            // YFI: 0xCF46fA1879757A5B523bF2BFF3b7fD82Fa56F622
            // nYFI-name: NToken0021
            // nYFI-symbol: N0021
            // nYFI-bidder: 0x0C5E0FBd686B2AB85328A1487A37ad336Ab89aee

            // nYFI-name: NToken0057
            // nYFI-symbol: N0057
            // nYFI-bidder: 0x2Ea38A9a418402C7a2D245744DfD6baA83cfA80c
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

        if (false) {
            let nestGovernance = await NestGovernance.at('0x1729fcb4C10f8bB643B687aC95C4fA7f4553f3E2');
            await nestGovernance.setGovernance('0xB0FFF7683D7Ae43E5360aba39f75695BAA07dbB2', 1);

            nestGovernance = await NestGovernance.at('0xA2D58989ef9981065f749C217984DB21970fF0b7');
            await nestGovernance.setGovernance('0xB0FFF7683D7Ae43E5360aba39f75695BAA07dbB2', 1);

            //await nest36Update.setNToken();
        }

        if (false) {
            let nestMining = await NestMining.at('0x1522c284B0eD0fF5a6DB8a8922b597A361a63bb2');
            await nestMining.setNTokenAddress('0xc3f9794C9f50537194ef0bd9e74e9658d51a0eBa', '0xCB35fE6Ba7E9a4d7aE1D34Cf32095ed9653301B5');
        }

        if (false) {
            let config = await nestVote.getConfig();
            console.log(config);
        }

        if (false) {
            let nv = await NestVote.at('0xD2BD52C52c0C2A220Ce2750e41Bc09b84526f26E');
            let config = await nv.getConfig();
            console.log(config);

            let list = await nv.list(0, 5, 0);
            for (var i in list) {
                console.log(list[i]);
            }
        }

        if (false) {
            let qry = await NestMining.at(nestPriceFacade.address);
            let pi = await qry.latestPriceAndTriggeredPriceInfo(usdt.address);
            
            let str = {
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            }

            console.log('latestPriceAndTriggeredPriceInfo(): ');
            console.log(str);

            let price = await qry.findPrice(usdt.address, 8414737);
            str = {
                blockNumber: price.blockNumber.toString(),
                price: price.price.toString()
            };

            console.log('findPrice')
            console.log(str);
        }

        if (false) {

            console.log('nest balance of account0: ' + await nest.balanceOf(account0));
            let nestMiningBalance = await nest.balanceOf(nestMining.address);
            let nestLedgerBalance = await nest.balanceOf(nestLedger.address);
            console.log('nest balance of nestMining: ' + nestMiningBalance);
            console.log('nest balance of nestLedger: ' + nestLedgerBalance);

            console.log('nestMining.migrate(nest.address, nestMiningBalance)');
            await nestMining.migrate(nest.address, nestMiningBalance);
            console.log('nest balance of account0: ' + await nest.balanceOf(account0));
            nestMiningBalance = await nest.balanceOf(nestMining.address);
            nestLedgerBalance = await nest.balanceOf(nestLedger.address);
            console.log('nest balance of nestMining: ' + nestMiningBalance);
            console.log('nest balance of nestLedger: ' + nestLedgerBalance);

            console.log('nestLedger.setApplication(account0, 1)');
            await nestLedger.setApplication(account0, 1);
            console.log("nestLedger.pay('0x0000000000000000000000000000000000000000', nest.address, account0, nestLedgerBalance)");
            await nestLedger.pay('0x0000000000000000000000000000000000000000', nest.address, account0, nestLedgerBalance);

            console.log('nest balance of account0: ' + await nest.balanceOf(account0));
            nestMiningBalance = await nest.balanceOf(nestMining.address);
            nestLedgerBalance = await nest.balanceOf(nestLedger.address);
            console.log('nest balance of nestMining: ' + nestMiningBalance);
            console.log('nest balance of nestLedger: ' + nestLedgerBalance);
        }

        if (false) {
            let usdt = await TestERC20.at('0xdAC17F958D2ee523a2206206994597C13D831ec7');
            console.log('usdt: ' + usdt.address);
            let nest = await TestERC20.at('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
            console.log('nest: ' + nest.address);
            let qry = await INestQuery.at('0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A');
            console.log('qry: ' + qry.address);
            let pi = await qry.latestPriceAndTriggeredPriceInfo(usdt.address); 
            // (
            //     uint latestPriceBlockNumber, 
            //     uint latestPriceValue,
            //     uint triggeredPriceBlockNumber,
            //     uint triggeredPriceValue,
            //     uint triggeredAvgPrice,
            //     uint triggeredSigmaSQ
            // )
    
            console.log(pi.toString());
            let js = {
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            };
    
            console.log(js);
        }
    });
});
