const { deployProxy } = require('@openzeppelin/truffle-upgrades');

// Load compiled artifacts
const IterableMapping = artifacts.require("IterableMapping");
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
    2021-03-22
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
    setQueryPrice: 0xD83C860d3A27cC5EddaB68EaBFCF9cc8ad38F15D
    */
    
    /*
    2021-04-04
    hbtc: 0x52e669eb87fBF69027190a0ffb6e6fEd48451E04
    usdt: 0xBa2064BbD49454517A9dBba39005bf46d31971f8
    nest: 0x3145AF0F18759D7587F22278d965Cdf7e19d6437
    nn: 0xF6298cc65E84F6a6D67Fa2890fbD2AD8735e3c29
    nestGovernance: 0x8a4fD519CEcFA7eCE7B4a204Dbb4b781B397C460
    nhbtc: 0x4269Fee5d9aAC83F1A9a81Cd17Bf71A01240765a
    nestLedger: 0x4397F20d20b5B89131b631c43AdE98Baf3A6dc9F
    nestMining: 0x4218e20Cdc77172972E40B9B56400E6ffe680724
    ntokenMining: 0x13742076bc96950cAfF0d0EfE64ebE818018121B
    nestPriceFacade: 0xCAc72395a6EaC6D0D06C8B303e26cC0Bfb5De33c
    nestRedeeming: 0xf453E3c1733f4634210ce15cd2A4fAfb191c36A5
    nestVote: 0x6B9C63a52533CB9b653B468f72fD751E0f2bc181
    nnIncome: 0xAc88d1fBF58E2646E0F4FF60aa436a70753885D9
    nTokenController: 0xF0737e3C98f1Ee41251681e2C6ad53Ab92AB0AEa
    */
     
    /*
    2021-04-06
    hbtc: 0x52e669eb87fBF69027190a0ffb6e6fEd48451E04
    usdt: 0xBa2064BbD49454517A9dBba39005bf46d31971f8
    nest: 0x3145AF0F18759D7587F22278d965Cdf7e19d6437
    nn: 0x8f89663562dDD4519566e590C18ec892134A0cdD
    nestGovernance: 0x74487D1a0FB2a70bb67e7D6c154d2ac71954a313
    nhbtc: 0x7A4DAca8f91c94479A6F8DD00D4bBABCa1Ac174d
    nestLedger: 0x82502A8f52BF186907BD0E12c8cEe612b4C203d1
    nestMining: 0xf94Af5800A4104aDEab67b3f5AA7A3a6E5bC64c3
    ntokenMining: 0x0684746A347033436E77030a43891Ea4FDaBb78E
    nestPriceFacade: 0x97F09D58a87B9a6f0cA1E69aCef77da3EFF8da0A
    nestRedeeming: 0xC545b531e1A093E33ec7058b70E74eD3aD113a2A
    nestVote: 0xD2BD52C52c0C2A220Ce2750e41Bc09b84526f26E
    nnIncome: 0xD5A32f6de0997749cb6F2F5B6042e2f878688aE2
    nTokenController: 0x57513Fc3133C7A4a930c345AB3aA9a4D21600Db9
    ht: 0xff2EDDDCF81033De38e70E6CdA75187a2cA567D9
    nht: 0x28aC53bD7e65306dF8ffccBbf77e7CcCaAf8415F
    */
    
    /*
    2021-04-14
    nest: 0x6158Ebb8022Ab0Cea5Ee507eDa9648A5f96538fE
    nn: 0x7cFb525161d0062923CAA6AbfaBcDb7c580acd48
    usdt: 0xE3972FF989F8aC7d6950B4bccE2D7e39B3F8A83f
    hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    nestGovernance: 0x79BAD49d6f76c7f0Ed6CD8E93A198a6E29765179
    nhbtc: 0xe6bf6Bd50b07D577a22FEA5b1A205Cf21642b198
    nestLedger: 0x566909EEc3B9cCbF3C5E1a3eCFCb439F54b2AF51
    nTokenController: 0x046528d4E9C9A8b0744163e1220758cF1FB58471
    nestVote: 0xB31f969571e09d832E582820457d614Ca482C822
    nestMining: 0xe8Bec71aeac191bbf4c870f927fE8fFaAEd9efc8
    ntokenMining: 0xaD223aBB38aE83b08facFD7469E8ef49fb525Ca1
    nestPriceFacade: 0x831fE938eEEC8dd7b993aB64F5B596dEdE9513D0
    nestRedeeming: 0xd170c041FD00876a77762E764e1433bed12Ca5D9
    nnIncome: 0x73832B6dF01E253E3CaDefD68f7c1a0e71241301
    */
   
    console.log('***** .deploy.proxy.js *****');
    let ib = await IterableMapping.new();
    await IBNEST.link(ib);
    let nest = await IBNEST.new();
    //let nest = await IBNEST.at('0x6158Ebb8022Ab0Cea5Ee507eDa9648A5f96538fE');
    console.log('nest: ' + nest.address);
    let usdt = await TestERC20.new('USDT', 'USDT', 6);
    //let usdt = await TestERC20.at('0xE3972FF989F8aC7d6950B4bccE2D7e39B3F8A83f');
    console.log('usdt: ' + usdt.address);
    let hbtc = await TestERC20.new('HBTC', 'HBTC', 18);
    //let hbtc = await TestERC20.at('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);
    let nestGovernance = await deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //let nestGovernance = await NestGovernance.at('0x79BAD49d6f76c7f0Ed6CD8E93A198a6E29765179');
    console.log('nestGovernance: ' + nestGovernance.address);
    let nestLedger = await deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    //let nestLedger = await NestLedger.at('0x566909EEc3B9cCbF3C5E1a3eCFCb439F54b2AF51');
    console.log('nestLedger: ' + nestLedger.address);
    let nTokenController = await deployProxy(NTokenController, [nestGovernance.address], { initializer: 'initialize' });
    //let nTokenController = await NTokenController.at('0x046528d4E9C9A8b0744163e1220758cF1FB58471');
    console.log('nTokenController: ' + nTokenController.address);
    let nestVote = await deployProxy(NestVote, [nestGovernance.address], { initializer: 'initialize' });
    //let nestVote = await NestVote.at('0xB31f969571e09d832E582820457d614Ca482C822');
    console.log('nestVote: ' + nestVote.address);
    let nestMining = await deployProxy(NestMining, [nestGovernance.address], { initializer: 'initialize' });
    //let nestMining = await NestMining.at('0xe8Bec71aeac191bbf4c870f927fE8fFaAEd9efc8');
    console.log('nestMining: ' + nestMining.address);
    let ntokenMining = await deployProxy(NestMining, [nestGovernance.address], { initializer: 'initialize' });
    //let ntokenMining = await NestMining.at('0xaD223aBB38aE83b08facFD7469E8ef49fb525Ca1');
    console.log('ntokenMining: ' + ntokenMining.address);
    let nestPriceFacade = await deployProxy(NestPriceFacade, [nestGovernance.address], { initializer: 'initialize' });
    //let nestPriceFacade = await NestPriceFacade.at('0x831fE938eEEC8dd7b993aB64F5B596dEdE9513D0');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    let nestRedeeming = await deployProxy(NestRedeeming, [nestGovernance.address], { initializer: 'initialize' });
    //let nestRedeeming = await NestRedeeming.at('0xd170c041FD00876a77762E764e1433bed12Ca5D9');
    console.log('nestRedeeming: ' + nestRedeeming.address);
    let nnIncome = await deployProxy(NNIncome, [nestGovernance.address], { initializer: 'initialize' });
    //let nnIncome = await NNIncome.at('0x73832B6dF01E253E3CaDefD68f7c1a0e71241301');
    console.log('nnIncome: ' + nnIncome.address);
    let nhbtc = await Nest_NToken.new('NHBTC', 'NToken0001', nestGovernance.address, (await web3.eth.getAccounts())[0]);
    //let nhbtc = await Nest_NToken.at('0xe6bf6Bd50b07D577a22FEA5b1A205Cf21642b198');
    console.log('nhbtc: ' + nhbtc.address);
    let nn = await SuperMan.new(nestGovernance.address);//.new(1500, 'NN');
    //let nn = await SuperMan.at('0x7cFb525161d0062923CAA6AbfaBcDb7c580acd48');
    console.log('nn: ' + nn.address);

    let contracts = {
        nest: nest,
        nn: nn,
        usdt: usdt,
        hbtc: hbtc,
        nhbtc: nhbtc,
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
        hbtc: hbtc.address,
        nhbtc: nhbtc.address,
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

        // Add ntoken mapping
        console.log('13. nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1)');
        await nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1);
        console.log('14. nTokenController.setNTokenMapping(usdt.address, nest.address, 1)');
        await nTokenController.setNTokenMapping(usdt.address, nest.address, 1);

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
    }
    return contracts;
};

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
            ntokenMinedBlockLimit: 100,
    
            // -- Public configuration
            // The number of times the sheet assets have doubled. 4
            maxBiteNestedLevel: 4,
            
            // Price effective block interval. 20
            priceEffectSpan: 20,
    
            // The amount of nest to pledge for each post (Unit: 1000). 100
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
    
            // The amount of nest to pledge for each post (Unit: 1000). 100
            pledgeNest: 100
        });

        console.log('23. nestPriceFacade.setConfig()');
        await contracts.nestPriceFacade.setConfig({

            // Single query fee (0.0001 ether, DIMI_ETHER). 100
            singleFee: 100,
    
            // Double query fee (0.0001 ether, DIMI_ETHER). 100
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
    }
}