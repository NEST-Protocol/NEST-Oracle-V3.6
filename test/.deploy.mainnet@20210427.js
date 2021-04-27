const { deployProxy } = require('@openzeppelin/truffle-upgrades');

// Load compiled artifacts
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

module.exports = async function() {

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
    ntokenMining: 0xE34A736290548227415329962705a6ee17c5f1a5
    nestPriceFacade: 0xD0B5532Cd0Ae1a14dAdf94f8562679A48aDa3643
    nestRedeeming: 0x5441B24FA3a2347Ac6EE70431dD3BfD0c224B4B7
    nnIncome: 0x718626a4b78e0ECfA60dE1D4C386302e68fac8cD
    */

    console.log('***** .deploy.mainnet@20210427.js *****');
    //let nest = await IBNEST.new();
    let nest = await IBNEST.at('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
    console.log('nest: ' + nest.address);
    //let usdt = await TestERC20.new('USDT', 'USDT', 6);
    let usdt = await TestERC20.at('0xdAC17F958D2ee523a2206206994597C13D831ec7');
    console.log('usdt: ' + usdt.address);
    //let hbtc = await TestERC20.new('HBTC', 'HBTC', 18);
    //let hbtc = await TestERC20.at('0xe089A4d2CBC409f30eb4E6c6661502ceDD5510b5');
    //console.log('hbtc: ' + hbtc.address);
    //let nestGovernance = await deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    let nestGovernance = await NestGovernance.at('0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5');
    console.log('nestGovernance: ' + nestGovernance.address);
    //let nestLedger = await deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    let nestLedger = await NestLedger.at('0x34B931C7e5Dc45dDc9098A1f588A0EA0dA45025D');
    console.log('nestLedger: ' + nestLedger.address);
    //let nTokenController = await deployProxy(NTokenController, [nestGovernance.address], { initializer: 'initialize' });
    let nTokenController = await NTokenController.at('0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62');
    console.log('nTokenController: ' + nTokenController.address);
    //let nestVote = await deployProxy(NestVote, [nestGovernance.address], { initializer: 'initialize' });
    let nestVote = await NestVote.at('0xDa52f53a5bE4cb876DE79DcfF16F34B95e2D38e9');
    console.log('nestVote: ' + nestVote.address);
    //let nestMining = await deployProxy(NestMining, [nestGovernance.address], { initializer: 'initialize' });
    let nestMining = await NestMining.at('0x03dF236EaCfCEf4457Ff7d6B88E8f00823014bcd');
    console.log('nestMining: ' + nestMining.address);
    //let ntokenMining = await deployProxy(NestMining, [nestGovernance.address], { initializer: 'initialize' });
    let ntokenMining = await NestMining.at('0xC2058Dd4D55Ae1F3e1b0744Bdb69386c9fD902CA');
    console.log('ntokenMining: ' + ntokenMining.address);
    //let nestPriceFacade = await deployProxy(NestPriceFacade, [nestGovernance.address], { initializer: 'initialize' });
    let nestPriceFacade = await NestPriceFacade.at('0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    //let nestRedeeming = await deployProxy(NestRedeeming, [nestGovernance.address], { initializer: 'initialize' });
    let nestRedeeming = await NestRedeeming.at('0xF48D58649dDb13E6e29e03059Ea518741169ceC8');
    console.log('nestRedeeming: ' + nestRedeeming.address);
    //let nnIncome = await deployProxy(NNIncome, [nestGovernance.address], { initializer: 'initialize' });
    let nnIncome = await NNIncome.at('0x95557DE67444B556FE6ff8D7939316DA0Aa340B2');
    console.log('nnIncome: ' + nnIncome.address);
    //let nhbtc = await Nest_NToken.new('NHBTC', 'NToken0001', nestGovernance.address, (await web3.eth.getAccounts())[0]);
    //let nhbtc = await Nest_NToken.at('0x58F9Dffda5D733FaAAb355A99a1B56A38262d541');
    //console.log('nhbtc: ' + nhbtc.address);
    //let nn = await SuperMan.new(nestGovernance.address);//.new(1500, 'NN');
    let nn = await SuperMan.at('0xC028E81e11F374f7c1A3bE6b8D2a815fa3E96E6e');
    console.log('nn: ' + nn.address);

    let contracts = {
        nest: nest,
        nn: nn,
        usdt: usdt,
        //hbtc: hbtc,
        //nhbtc: nhbtc,
        nestLedger: nestLedger,
        nestMining: nestMining,
        ntokenMining: ntokenMining,
        nestPriceFacade: nestPriceFacade,
        nestVote: nestVote,
        nnIncome: nnIncome,
        nTokenController: nTokenController,
        nestRedeeming: nestRedeeming,
        nestGovernance: nestGovernance
    };

    let contractAddresses = {
        nest: nest.address,
        nn: nn.address,
        usdt: usdt.address,
        //hbtc: hbtc.address,
        //nhbtc: nhbtc.address,
        nestLedger: nestLedger.address,
        nestMining: nestMining.address,
        ntokenMining: ntokenMining.address,
        nestPriceFacade: nestPriceFacade.address,
        nestVote: nestVote.address,
        nnIncome: nnIncome.address,
        nTokenController: nTokenController.address,
        nestRedeeming: nestRedeeming.address,
        nestGovernance: nestGovernance.address
    };

    console.log(contractAddresses);

    if (false) {
        console.log('1. nestGovernance.setBuiltinAddress()');
        await nestGovernance.setBuiltinAddress(
            nest.address,
            nn.address, //nestNodeAddress,
            nestLedger.address,
            nestMining.address,
            ntokenMining.address,
            nestPriceFacade.address,
            nestVote.address,
            ntokenMining.address, //nestQueryAddress,
            nnIncome.address, //nnIncomeAddress,
            nTokenController.address //nTokenControllerAddress
        );

        console.log('2. nestGovernance.update()');
        await nestGovernance.update(nestGovernance.address);
        console.log('3. nestLedger.update()');
        await nestLedger.update(nestGovernance.address);
        console.log('4. nTokenController.update()');
        await nTokenController.update(nestGovernance.address);
        console.log('5. nestVote.update()');
        await nestVote.update(nestGovernance.address);
        console.log('6. nestMining.update()');
        await nestMining.update(nestGovernance.address);
        console.log('7. ntokenMining.update()');
        await ntokenMining.update(nestGovernance.address);
        console.log('8. nestPriceFacade.update()');
        await nestPriceFacade.update(nestGovernance.address);
        console.log('9. nestRedeeming.update()');
        await nestRedeeming.update(nestGovernance.address);
        console.log('10. nnIncome.update()');
        await nnIncome.update(nestGovernance.address);

        console.log('11. nestGovernance.registerAddress(nest.dao.redeeming)');
        await nestGovernance.registerAddress('nest.dao.redeeming', nestRedeeming.address);
        console.log('12. nestGovernance.registerAddress(nest.nToken.offerMain)');
        await nestGovernance.registerAddress('nest.nToken.offerMain', ntokenMining.address);
        console.log('12.1. nestGovernance.registerAddress(nodeAssignment)');
        await nestGovernance.registerAddress('nodeAssignment', nnIncome.address);

        // Add ntoken mapping
        //console.log('13. nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1)');
        //await nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1);
        //console.log('14. nTokenController.setNTokenMapping(usdt.address, nest.address, 1)');
        //await nTokenController.setNTokenMapping(usdt.address, nest.address, 1);

        console.log('15. nestPriceFacade.setNestQuery(usdt.address, nestMining.address)');
        await nestPriceFacade.setNestQuery(usdt.address, nestMining.address);
        console.log('16. nestPriceFacade.setNestQuery(nest.address, nestMining.address)');
        await nestPriceFacade.setNestQuery(nest.address, nestMining.address);

        // Authorization of voting contracts
        console.log('17. nestGovernance.setGovernance(nestVote.address, 1)');
        await nestGovernance.setGovernance(nestVote.address, 1);
        console.log('18. nestLedger.setApplication(nestRedeeming.address, 1)');
        await nestLedger.setApplication(nestRedeeming.address, 1);

        await setConfig(contracts);
    } else {
    }
    return contracts;
};

async function setConfig(contracts) {
    if (false) {
        // Set configuration
        console.log('20. nestLedger.setConfig()');
        await contracts.nestLedger.setConfig({
        
            // nest reward scale(10000 based). 2000
            nestRewardScale: 2000
    
            // // ntoken reward scale(10000 based). 8000
            // uint16 ntokenRewardScale;
        });

        console.log('21. nestMining.setConfig()');
        await contracts.nestMining.setConfig({
        
            // Eth number of each post. 30
            // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
            postEthUnit: 30,
    
            // Post fee(0.0001eth，DIMI_ETHER). 1000
            postFeeUnit: 1000,
    
            // Proportion of miners digging(10000 based). 8000
            minerNestReward: 8000,
            
            // The proportion of token dug by miners is only valid for the token created in version 3.0
            // (10000 based). 9500
            minerNTokenReward: 9500,
    
            // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
            doublePostThreshold: 500,
            
            // The limit of ntoken mined blocks. 100
            ntokenMinedBlockLimit: 100,
    
            // -- Public configuration
            // The number of times the sheet assets have doubled. 4
            maxBiteNestedLevel: 4,
            
            // Price effective block interval. 20
            priceEffectSpan: 20,
    
            // The amount of nest to pledge for each post（Unit: 1000). 100
            pledgeNest: 100
        });

        console.log('22. ntokenMining.setConfig()');
        await contracts.ntokenMining.setConfig({
        
            // Eth number of each post. 30
            // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
            postEthUnit: 10,
    
            // Post fee(0.0001eth，DIMI_ETHER). 1000
            postFeeUnit: 1000,
    
            // Proportion of miners digging(10000 based). 8000
            minerNestReward: 8000,
            
            // The proportion of token dug by miners is only valid for the token created in version 3.0
            // (10000 based). 9500
            minerNTokenReward: 9500,
    
            // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
            doublePostThreshold: 500,
            
            // The limit of ntoken mined blocks. 100
            ntokenMinedBlockLimit: 100,
    
            // -- Public configuration
            // The number of times the sheet assets have doubled. 4
            maxBiteNestedLevel: 4,
            
            // Price effective block interval. 20
            priceEffectSpan: 20,
    
            // The amount of nest to pledge for each post（Unit: 1000). 100
            pledgeNest: 100
        });

        console.log('23. nestPriceFacade.setConfig()');
        await contracts.nestPriceFacade.setConfig({

            // Single query fee（0.0001 ether, DIMI_ETHER). 100
            singleFee: 100,
    
            // Double query fee（0.0001 ether, DIMI_ETHER). 100
            doubleFee: 100,
    
            // The normal state flag of the call address. 0
            normalFlag: 0
        });

        console.log('24. nestRedeeming.setConfig()');
        await contracts.nestRedeeming.setConfig({

            // Redeem activate threshold, when the circulation of token exceeds this threshold, 
            // activate redeem (Unit: 10000 ether). 500 
            activeThreshold: 500,
    
            // The number of nest redeem per block. 1000
            nestPerBlock: 1000,
    
            // The maximum number of nest in a single redeem. 300000
            nestLimit: 300000,
    
            // The number of ntoken redeem per block. 10
            ntokenPerBlock: 10,
    
            // The maximum number of ntoken in a single redeem. 3000
            ntokenLimit: 3000,
    
            // Price deviation limit, beyond this upper limit stop redeem (10000 based). 500
            priceDeviationLimit: 500
        });

        console.log('25. nestVote.setConfig()');
        await contracts.nestVote.setConfig({

            // Proportion of votes required (10000 based). 5100
            acceptance: 5100,
    
            // Voting time cycle (seconds). 5 * 86400
            voteDuration: 5 * 86400,
    
            // The number of nest votes need to be staked. 100000 nest
            proposalStaking: '100000000000000000000000'
        });

        console.log('26. nTokenController.setConfig()');
        await contracts.nTokenController.setConfig({

            // The number of nest needed to pay for opening ntoken. 10000 ether
            openFeeNestAmount: '10000000000000000000000',
    
            // ntoken management is enabled. 0: not enabled, 1: enabled
            state: 1
        });
    } else {
    }
}

