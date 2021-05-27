const { deployProxy } = require('@openzeppelin/truffle-upgrades');

// Load compiled artifacts
const IterableMapping = artifacts.require("IterableMapping");
const IBNEST = artifacts.require('IBNEST');
const USDT = artifacts.require('USDT');
const HBTC = artifacts.require('HBTC');
const NHBTC = artifacts.require('NHBTC');
const NNToken = artifacts.require('NNToken'); // for test only
const SuperMan = artifacts.require('SuperMan'); // NNToken on Mainnet
//const TestERC20 = artifacts.require('TestERC20');
//const Nest_NToken = artifacts.require('Nest_NToken');
//const NToken = artifacts.require('NToken');
const NestGovernance = artifacts.require('NestGovernance');
const NestLedger = artifacts.require('NestLedger');
const NestPriceFacade = artifacts.require('NestPriceFacade');
const NTokenController = artifacts.require('NTokenController');
const NestVote = artifacts.require('NestVote');
const NestMining = artifacts.require('NestMining');
const NTokenMining = artifacts.require('NTokenMining');
const NestRedeeming = artifacts.require('NestRedeeming');
const NNIncome = artifacts.require('NNIncome');


async function setConfig(contracts) {
    if (false) {
    } else {
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
        await contracts.ntokenMining.setConfig({
        
            // Eth number of each post. 30
            // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
            postEthUnit: 10,
    
            // Post fee(0.0001eth，DIMI_ETHER). 1000
            postFeeUnit: 500,
    
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
            openFeeNestAmount: '1000000000000000000000',
    
            // ntoken management is enabled. 0: not enabled, 1: enabled
            state: 1
        });
    }
}

module.exports = async function (deployer, network, accounts) {
 
    let nest;
    if (network == 'mainnet') {
        // Set nest address: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
        nest = await IBNEST.at('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
        return;
    }
    else {
        await deployer.deploy(IterableMapping);
        await deployer.link(IterableMapping, IBNEST);
        nest = await deployer.deploy(IBNEST);
    }
    console.log('nest: ' + nest.address);

    let usdt;
    if (network == 'mainnet') {
        // Set usdt address: 0xdAC17F958D2ee523a2206206994597C13D831ec7
        usdt = await USDT.at('0xdAC17F958D2ee523a2206206994597C13D831ec7');
    }
    else {
        usdt = await deployer.deploy(USDT, 'USDT', 'USDT', 6);
    }
    console.log('usdt: ' + usdt.address);

    let nestGovernance = await deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000', nest.address], { deployer, initializer: 'initialize' });
    //let nestGovernance = await NestGovernance.at('0x79BAD49d6f76c7f0Ed6CD8E93A198a6E29765179');
    console.log('nestGovernance: ' + nestGovernance.address);

    let nn;
    if (network == 'mainnet') {
        // nn = await SuperMan.new(nestGovernance.address);//.new(1500, 'NN');
        // Set nn address: 0xC028E81e11F374f7c1A3bE6b8D2a815fa3E96E6e
        await SuperMan.at('0xC028E81e11F374f7c1A3bE6b8D2a815fa3E96E6e');
    }
    else {
        nn = await deployer.deploy(NNToken, 1500, 'NN');
    }
    console.log('nn: ' + nn.address);

    let nestGenesisBlock;
    if (network == 'mainnet') {
        nestGenesisBlock = 2000; // FIXME: use the actual block number on BSC Mainnet
    }
    else {
        nestGenesisBlock = 0;
    }
    console.log('nestGenesisBlock: ' + nestGenesisBlock);

    //const nestBaseInitArgs = [nestGovernance.address];
    const nestBaseInitArgs = [nestGovernance.address, nest.address, nestGenesisBlock];
    //const nnIncomeInitArgs = [nestGovernance.address];
    const nnIncomeInitArgs = [nestGovernance.address, nest.address, nestGenesisBlock, nn.address];
    
    let nestLedger = await deployProxy(NestLedger, nestBaseInitArgs, { deployer, initializer: 'initialize' });
    console.log('nestLedger: ' + nestLedger.address);

    let nTokenController = await deployProxy(NTokenController, nestBaseInitArgs, { deployer, initializer: 'initialize' });
    console.log('nTokenController: ' + nTokenController.address);

    let nestVote = await deployProxy(NestVote, nestBaseInitArgs, { deployer, initializer: 'initialize' });
    console.log('nestVote: ' + nestVote.address);

    let nestMining = await deployProxy(NestMining, nestBaseInitArgs, { deployer, initializer: 'initialize' });
    console.log('nestMining: ' + nestMining.address);

    let ntokenMining = await deployProxy(NTokenMining, nestBaseInitArgs, { deployer, initializer: 'initialize' });
    console.log('ntokenMining: ' + ntokenMining.address);

    let nestPriceFacade = await deployProxy(NestPriceFacade, nestBaseInitArgs, { deployer, initializer: 'initialize' });
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    let nestRedeeming = await deployProxy(NestRedeeming, nestBaseInitArgs, { deployer, initializer: 'initialize' });
    console.log('nestRedeeming: ' + nestRedeeming.address);

    let nnIncome = await deployProxy(NNIncome, nnIncomeInitArgs, { deployer, initializer: 'initialize' });
    console.log('nnIncome: ' + nnIncome.address);

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
        //usdt: usdt.address,
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
    } else {
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

        if (network != "mainnet") {
            const hbtc = await deployer.deploy(HBTC, 'HBTC', 'HBTC', 18);
            console.log('hbtc: ' + hbtc.address);
            const nhbtc = await deployer.deploy(NHBTC, 'NHBTC', 'NToken0001', nestGovernance.address, accounts[0]);
            //nhbtc = await Nest_NToken.new('NHBTC', 'NToken0001', nestGovernance.address, (await web3.eth.getAccounts())[0]);
            //let nhbtc = await Nest_NToken.at('0xe6bf6Bd50b07D577a22FEA5b1A205Cf21642b198');            
            console.log('nhbtc: ' + nhbtc.address);

            // Add ntoken mapping
            console.log('13. nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1)');
            await nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1);
            console.log('14. nTokenController.setNTokenMapping(usdt.address, nest.address, 1)');
            await nTokenController.setNTokenMapping(usdt.address, nest.address, 1);
        }

        console.log('15. nestPriceFacade.setNestQuery(usdt.address, nestMining.address)');
        await nestPriceFacade.setNestQuery(usdt.address, nestMining.address);
        console.log('16. nestPriceFacade.setNestQuery(nest.address, nestMining.address)');
        await nestPriceFacade.setNestQuery(nest.address, nestMining.address);

        // In order to prevent others from preempting to initiate the deletion of administrator's vote,
        // resulting in a passive situation, the voting contract is not authorized during deployment
        // // Authorization of voting contracts
        // console.log('17. nestGovernance.setGovernance(nestVote.address, 1)');
        // await nestGovernance.setGovernance(nestVote.address, 1);
        console.log('18. nestLedger.setApplication(nestRedeeming.address, 1)');
        await nestLedger.setApplication(nestRedeeming.address, 1);

        await setConfig(contracts);
    }
};
