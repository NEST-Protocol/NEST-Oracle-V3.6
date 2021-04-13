const BN = require("bn.js");
const $hcj = require("./hcore.js");
const { expect } = require('chai');
const { deployProxy, upgradeProxy, admin } = require('@openzeppelin/truffle-upgrades');

// Load compiled artifacts
const IBNEST = artifacts.require('IBNEST');
const NNToken = artifacts.require('NNToken');
const TestERC20 = artifacts.require('TestERC20');
const NestGovernance = artifacts.require('NestGovernance');
const NestLedger = artifacts.require('NestLedger');
const NestPriceFacade = artifacts.require('NestPriceFacade');
const NTokenController = artifacts.require('NTokenController');
const NestMining = artifacts.require('NestMining');
const NestMining2 = artifacts.require('NestMining2');
const NestVote = artifacts.require('NestVote');
const NNIncome = artifacts.require('NNIncome');
const NestRedeeming = artifacts.require('nestRedeeming');
const UpdateAdmin = artifacts.require("UpdateAdmin");
const TransferWrapper = artifacts.require("TransferWrapper");
const UpdateProxyPropose = artifacts.require("UpdateProxyPropose");

const USDT = function(value) { return new BN('1000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }
const ETHER = function(value) { return new BN('1000000000000000000').mul(new BN(value * 1000000)).div(new BN('1000000')); }

// Start test block
contract('NestMining (proxy)', async accounts => {
    
    let account0 = accounts[0];
    const skipBlocks = async function(blockCount) {
        for (var i = 0; i < blockCount; ++i) {
            await web3.eth.sendTransaction({ from: account0, to: account0, value: ETHER(1)});
        }
    };

    beforeEach(async function () {
        
        // nest: 0x1d1f9E2789b22818425ede5d3889745fe516D5bB
        // let n = await IBNEST.new();
        // console.log('nest: ' + n.address);
        // return;
        // 为每个测试部署一个新的Box合约 
        this.nest = await IBNEST.at('0x1d1f9E2789b22818425ede5d3889745fe516D5bB');
        this.usdt = await TestERC20.new('USDT', 'USDT', 6);
        this.nn = await NNToken.new(1500, 'NN');
        console.log('nest: ' + this.nest.address);
        this.nestGovernance = await deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
        this.nestLedger = await deployProxy(NestLedger, [this.nestGovernance.address], { initializer: 'initialize' });
        this.nestPriceFacade = await deployProxy(NestPriceFacade, [this.nestGovernance.address], { initializer: 'initialize' });
        this.nTokenController = await deployProxy(NTokenController, [this.nestGovernance.address], { initializer: 'initialize' });
        this.nestMining = await deployProxy(NestMining, [this.nestGovernance.address], { initializer: 'initialize' });
        this.nestVote = await deployProxy(NestVote, [this.nestGovernance.address], { initializer: 'initialize' });
        this.nnIncome = await deployProxy(NNIncome, [this.nestGovernance.address], { initializer: 'initialize' });
        this.nestRedeeming = await deployProxy(NestRedeeming, [this.nestGovernance.address], { initializer: 'initialize' });
        //this.box = await deployProxy(NestMining, [], {initializer: null });

        await this.nestGovernance.setBuiltinAddress(
            this.nest.address,
            this.nn.address, //nestNodeAddress,
            this.nestLedger.address,
            this.nestMining.address,
            this.nestMining.address,
            this.nestPriceFacade.address,
            this.nestVote.address,
            this.nestMining.address, //nestQueryAddress,
            this.nnIncome.address, //nnIncomeAddress,
            this.nTokenController.address //nTokenControllerAddress
        );

        // 更新合约地址
        await this.nestLedger.update(this.nestGovernance.address);
        await this.nestMining.update(this.nestGovernance.address);
        await this.nestPriceFacade.update(this.nestGovernance.address);
        await this.nestRedeeming.update(this.nestGovernance.address);
        await this.nestVote.update(this.nestGovernance.address);
        await this.nTokenController.update(this.nestGovernance.address);

        // 设置参数
        await this.nestLedger.setConfig({
            // NEST分成（万分制）。2000
            nestRewardScale: 2000,
            // NTOKEN分成（万分制）。8000
            //ntokenRewardScale: 8000
        });
          
        await this.nestMining.setConfig({
          
            // 报价的eth单位。30
            // 可以通过将postEthUnit设置为0来停止报价和吃单（关闭和取回不受影响）
            postEthUnit: 30,
    
            // 报价的手续费（万分之一eth，DIMI_ETHER）。1000
            postFeeUnit: 1000,
    
            // 矿工挖到nest的比例（万分制）。8000
            minerNestReward: 8000,
              
            // 矿工挖到的ntoken比例，只对3.0版本创建的ntoken有效（万分制）。9500
            minerNTokenReward: 9500,
    
            // 双轨报价阈值，当ntoken的发行量超过此阈值时，禁止单轨报价（单位：10000 ether）。500
            doublePostThreshold: 500,
              
            // ntoken最多可以挖到多少区块。100
            ntokenMinedBlockLimit: 100,
    
            // -- 公共配置
            // 吃单资产翻倍次数。4
            maxBiteNestedLevel: 4,
              
            // 价格生效区块间隔。20
            priceEffectSpan: 20,
    
            // 报价抵押nest数量（单位千）。100
            pledgeNest: 100
        });
  
        await this.nestPriceFacade.setConfig({
  
            // 单轨询价费用（万分之一eth，DIMI_ETHER）。100
            singleFee: 100,
    
            // 双轨询价费用（万分之一eth，DIMI_ETHER）。100
            doubleFee: 100,
              
            // 调用地址的正常状态标记。0
            normalFlag: 0
        });
  
        await this.nTokenController.setConfig({

            // 开通ntoken需要支付的nest数量。10000 ether
            openFeeNestAmount: '10000000000000000000000',

            // ntoken管理功能启用状态。0：未启用，1：已启用
            state: 1
        });

        await this.nestVote.setConfig({

            // 投票通过需要的比例（万分制）。5100
            acceptance: 5100,
    
            // 投票时间周期。5 * 86400秒
            voteDuration: 5 * 86400,
    
            // 投票需要抵押的nest数量。100000 nest
            proposalStaking: '100000000000000000000000'
        });

        // 添加ntoken映射
        //await this.nTokenController.setNTokenMapping(hbtc.address, nhbtc.address, 1);
        await this.nTokenController.setNTokenMapping(this.usdt.address, this.nest.address, 1);

        // 给投票合约授权
        await this.nestGovernance.setGovernance(this.nestVote.address, 1);
        await this.nestLedger.setApplication(this.nestRedeeming.address, 1);
    });
 
    // 测试用例
    it('retrieve returns a value previously initialized', async function () {
        // 测试是否返回了同一个设置的值
        // 注意需要使用字符串去对比256位的整数
        //expect((await this.box.retrieve()).toString()).to.equal('42');

        await this.usdt.transfer(account0, USDT(10000000));
        await this.usdt.approve(this.nestMining.address, USDT(10000000));
        await this.nest.approve(this.nestMining.address, ETHER(10000000));

        if (true) {
            // 代理报价
            let receipt = await this.nestMining.post2(this.usdt.address, 30, USDT(1600), ETHER(1), { value: ETHER(60.1) });
            console.log(receipt);

            await skipBlocks(20);
            await this.nestMining.closeList2(this.usdt.address, [0], [0]);
            console.log('latestPriceAndTriggeredPriceInfo()');
            let pi = await this.nestMining.latestPriceAndTriggeredPriceInfo(this.usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });
        }

        if (false) {
            // 修改代理
            await upgradeProxy(this.nestMining.address, NestMining2);
            let receipt = await this.nestMining.post2(this.usdt.address, 30, USDT(1600), ETHER(1), { value: ETHER(60.1) });
            console.log(receipt);
            await skipBlocks(20);
            await this.nestMining.closeList2(this.usdt.address, [1], [1]);
            console.log('latestPriceAndTriggeredPriceInfo()');
            let pi = await this.nestMining.latestPriceAndTriggeredPriceInfo(this.usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });
        }

        if (false) {
            let updateAdmin = await UpdateAdmin.new(this.nestGovernance.address);
            await updateAdmin.setAddress(account0, 0);

            await this.nestGovernance.setGovernance(updateAdmin.address, 1);
            await updateAdmin.run();

            await updateAdmin.setAddress(account0, 1);
            await updateAdmin.run();
            await this.nestGovernance.setGovernance(updateAdmin.address, 0);
        }

        if (false) {

            console.log('balance1: ' + await web3.eth.getBalance(this.nestMining.address));
            await web3.eth.sendTransaction({ from: account0, to: this.nestMining.address, value: ETHER(1)});
            console.log('balance2: ' + await web3.eth.getBalance(this.nestMining.address));

            let pw = await TransferWrapper.new();
            console.log('balance3: ' + await web3.eth.getBalance(this.nestMining.address));
            await pw.transferETH(this.nestMining.address, { value: ETHER(1) });
            console.log('balance4: ' + await web3.eth.getBalance(this.nestMining.address));
        }

        if (true) {

            let nestMining2 = await NestMining2.new();
            let proxyAdmin = await this.nestMining.getAdmin();
            let updateProxyPropose = await UpdateProxyPropose.new();
            await updateProxyPropose.setAddress(
                this.nestVote.address,
                proxyAdmin,
                this.nestMining.address,
                nestMining2.address
            );

            await this.nest.approve(this.nestVote.address, ETHER(8000000000));
            await this.nestVote.propose(updateProxyPropose.address, 'change nest mining');
            await this.nestVote.vote(0, ETHER(6000000000));

            await admin.transferProxyAdminOwnership(this.nestVote.address);
            await this.nestVote.execute(0);
            await this.nestVote.withdraw(0);

            let receipt = await this.nestMining.post2(this.usdt.address, 30, USDT(1600), ETHER(1), { value: ETHER(60.1) });
            console.log(receipt);
            await skipBlocks(20);
            await this.nestMining.closeList2(this.usdt.address, [1], [1]);
            console.log('latestPriceAndTriggeredPriceInfo()');
            let pi = await this.nestMining.latestPriceAndTriggeredPriceInfo(this.usdt.address);
            console.log({
                latestPriceBlockNumber: pi.latestPriceBlockNumber.toString(),
                latestPriceValue: pi.latestPriceValue.toString(),
                triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
                triggeredPriceValue: pi.triggeredPriceValue.toString(),
                triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
                triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
            });
        }
    });
});