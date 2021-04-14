const NToken = artifacts.require('NToken');
const TestERC20 = artifacts.require('TestERC20');
const ERC20 = artifacts.require('ERC20');

const BN = require("bn.js");
const { expect } = require('chai');
const { deploy, USDT, GWEI, ETHER, HBTC, nHBTC, LOG, ethBalance } = require("./.deploy.js");

contract("NestMining", async accounts => {

    it('test', async () => {

        const { nest, nn, usdt, hbtc,/* nhbtc,*/ nestLedger, nestMining, ntokenMining, nestPriceFacade, nestVote, nnIncome, nTokenController, nestRedeeming } = await deploy();
        
        const account0 = accounts[0];
        const account1 = accounts[1];

        // 初始化usdt余额
        await hbtc.transfer(account0, ETHER('10000000'), { from: account1 });
        await hbtc.transfer(account1, ETHER('10000000'), { from: account1 });
        await nest.transfer(account1, ETHER('1000000000'));
        await nest.transfer(ntokenMining.address, ETHER('8000000000'));

        await hbtc.approve(nTokenController.address, ETHER(1), { from: account1 });
        await nest.approve(nTokenController.address, ETHER(10000), { from: account1 });
        await nTokenController.setNTokenMapping(hbtc.address, '0x0000000000000000000000000000000000000000', 0);
        await nTokenController.open(hbtc.address, { from: account1 });
        let nhbtcAddress = await nTokenController.getNTokenAddress(hbtc.address);
        let nhbtc = await NToken.at(nhbtcAddress);

        //await web3.eth.sendTransaction({ from: account0, to: account1, value: new BN('200').mul(ETHER)});
        const skipBlocks = async function(blockCount) {
            for (var i = 0; i < blockCount; ++i) {
                await web3.eth.sendTransaction({ from: account0, to: account0, value: ETHER(1)});
            }
        };
        // 显示余额
        const getBalance = async function(account) {
            let balances = {
                balance: {
                    eth: await ethBalance(account),
                    hbtc: await hbtc.balanceOf(account),
                    nhbtc: await nhbtc.balanceOf(account),
                    nest: await nest.balanceOf(account)
                },
                pool: {
                    eth: ETHER(0),
                    hbtc: await ntokenMining.balanceOf(hbtc.address, account),
                    nhbtc: await ntokenMining.balanceOf(nhbtc.address, account),
                    nest: await ntokenMining.balanceOf(nest.address, account)
                }
            };

            return balances;
        };
        const showBalance = async function(account, msg) {
            console.log(msg);
            let balances = await getBalance(account);

            LOG('balance: {eth}eth, {nest}nest, {hbtc}hbtc, {nhbtc}nhbtc', balances.balance);
            LOG('pool: {eth}eth, {nest}nest, {hbtc}hbtc, {nhbtc}nhbtc', balances.pool);

            return balances;
        };

        let balance0 = await showBalance(account0, 'account0');
        let balance1 = await showBalance(account1, 'account1');
        assert.equal(0, balance1.balance.hbtc.cmp(HBTC('10000000')));

        // account0余额
        assert.equal(0, balance0.balance.hbtc.cmp(HBTC('10000000')));
        assert.equal(0, balance0.balance.nest.cmp(ETHER('1000000000')));
        assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
        assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));

        // nestMining余额
        assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0)));
        assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(0)));
        assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000)));

        await nest.approve(ntokenMining.address, ETHER('1000000000'));
        await hbtc.approve(ntokenMining.address, HBTC('10000000'));
        await nest.approve(ntokenMining.address, ETHER('1000000000'), { from: account1 });
        await hbtc.approve(ntokenMining.address, HBTC('10000000'), { from: account1 });

        let prevBlockNumber = 0;
        let mined = nHBTC(0);
        
        {
            // 发起报价
            console.log('发起报价');
            let receipt = await ntokenMining.post(hbtc.address, 30, HBTC(256), { value: ETHER(30.1) });
            console.log(receipt);
            balance0 = await showBalance(account0, '发起一次报价后');
            
            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nest.cmp(mined));

            // nestMining余额
            //assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(30.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000 + 100000)));
            
            mined = nHBTC(10 * 4 * 1);
            prevBlockNumber = receipt.receipt.blockNumber;

            await skipBlocks(20);

            // 关闭报价单
            receipt = await ntokenMining.close(hbtc.address, 0);

            console.log(receipt);
            balance0 = await showBalance(account0, '关闭报价单后');

            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000 - 256 * 30)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000 - 100000)));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(256 * 30)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(100000)));
            assert.equal(0, balance0.pool.nhbtc.cmp(mined));

            // nestMining余额
            //assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)).cmp(HBTC(256 * 30)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000 + 100000)));

            // nestLedger余额
            //assert.equal(0, (await ethBalance(nestLedger.address)).cmp(ETHER(0 + 0.099)));

            // 取回
            await ntokenMining.withdraw(hbtc.address, await ntokenMining.balanceOf(hbtc.address, account0));
            await ntokenMining.withdraw(nest.address, await ntokenMining.balanceOf(nest.address, account0));
            await ntokenMining.withdraw(nhbtc.address, await ntokenMining.balanceOf(nhbtc.address, account0));
            
            balance0 = await showBalance(account0, '取回后');

            //assert.equal(0, (await ethBalance(ntokenMining.address)).cmp(ETHER(0.099 - 0.099)));
            assert.equal(0, (await hbtc.balanceOf(ntokenMining.address)));
            assert.equal(0, (await nest.balanceOf(ntokenMining.address)).cmp(ETHER(8000000000)));
            
            // account0余额
            assert.equal(0, balance0.balance.hbtc.cmp(HBTC(10000000)));
            assert.equal(0, balance0.balance.nest.cmp(ETHER(1000000000)));
            assert.equal(0, balance0.balance.nhbtc.cmp(mined));
            assert.equal(0, balance0.pool.hbtc.cmp(HBTC(0)));
            assert.equal(0, balance0.pool.nest.cmp(ETHER(0)));
            assert.equal(0, balance0.pool.nhbtc.cmp(nHBTC(0)));

            LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            await skipBlocks(18);
            LOG('blockNumber: ' + await web3.eth.getBlockNumber());

            // 查看价格
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPrice = await ntokenMining.triggeredPrice(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}', triggeredPrice);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }
            await ntokenMining.stat(hbtc.address);
            // 查看价格
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            receipt = await ntokenMining.post(hbtc.address, 30, HBTC(2570), { value: ETHER(30.1) });
            console.log(receipt);

            await skipBlocks(20);
            await ntokenMining.stat(hbtc.address);
            // 查看价格
            {
                let latestPrice = await ntokenMining.latestPrice(hbtc.address);
                LOG('latestPrice: blockNumber={blockNumber}, price={price}', latestPrice);
                let triggeredPriceInfo = await ntokenMining.triggeredPriceInfo(hbtc.address);
                LOG('triggeredPrice: blockNumber={blockNumber}, price={price}, sigmaSQ={sigmaSQ}', triggeredPriceInfo);
                LOG('blockNumber: ' + await web3.eth.getBlockNumber());
            }

            receipt = await ntokenMining.close(hbtc.address, 1);
            console.log(receipt);

            // config
            console.log('修改配置前');
            console.log(await nTokenController.getConfig());

            await nTokenController.setConfig({
                // The number of nest needed to pay for opening ntoken. 10000 ether
                openFeeNestAmount: '12345678901234567890123',

                // ntoken management is enabled. 0: not enabled, 1: enabled
                state: 0
            });
            console.log('修改配置后');
            console.log(await nTokenController.getConfig());

            // token mapping
            assert.equal(await nTokenController.getTokenAddress(nest.address), usdt.address);
            assert.equal(await nTokenController.getTokenAddress(nhbtc.address), hbtc.address);

            assert.equal(await nTokenController.getNTokenAddress(usdt.address), nest.address);
            assert.equal(await nTokenController.getNTokenAddress(hbtc.address), nhbtc.address);

            await nTokenController.setNTokenMapping(usdt.address, nhbtc.address, 1);
            await nTokenController.setNTokenMapping(hbtc.address, nest.address, 0);
            let yfi = await TestERC20.new('YFI', 'YFI', 18);
            let nYFI = await TestERC20.new('nYFI', 'nYFI', 18);
            await nTokenController.setNTokenMapping(yfi.address, nYFI.address, 1);

            // 2. 列出所有的ntoken信息
            let list = await nTokenController.list(0, 3, 1);
            for (var i in list) {
                let tag = list[i];
                if (tag.tokenAddress == '0x0000000000000000000000000000000000000000'
                || tag.ntokenAddress == '0x0000000000000000000000000000000000000000') {
                    continue;
                }
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                    state: tag.state
                });
            }

            assert.equal(await nTokenController.getTokenAddress(nYFI.address), yfi.address);
            assert.equal(await nTokenController.getTokenAddress(nest.address), hbtc.address);
            assert.equal(await nTokenController.getTokenAddress(nhbtc.address), usdt.address);

            assert.equal(await nTokenController.getNTokenAddress(yfi.address), nYFI.address);
            assert.equal(await nTokenController.getNTokenAddress(usdt.address), nhbtc.address);
            assert.equal(await nTokenController.getNTokenAddress(hbtc.address), nest.address);

            // disable yfi
            console.log('disable yfi');
            await nTokenController.disable(yfi.address);
            list = await nTokenController.list(0, 3, 1);
            for (var i in list) {
                let tag = list[i];
                if (tag.tokenAddress == '0x0000000000000000000000000000000000000000'
                || tag.ntokenAddress == '0x0000000000000000000000000000000000000000') {
                    continue;
                }
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                    state: tag.state
                });
            }

            // disable usdt
            console.log('disable usdt');
            await nTokenController.disable(usdt.address);
            list = await nTokenController.list(0, 3, 1);
            for (var i in list) {
                let tag = list[i];
                if (tag.tokenAddress == '0x0000000000000000000000000000000000000000'
                || tag.ntokenAddress == '0x0000000000000000000000000000000000000000') {
                    continue;
                }
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                    state: tag.state
                });
            }

            // disable hbtc
            console.log('disable hbtc');
            await nTokenController.disable(hbtc.address);
            list = await nTokenController.list(0, 3, 1);
            for (var i in list) {
                let tag = list[i];
                if (tag.tokenAddress == '0x0000000000000000000000000000000000000000'
                || tag.ntokenAddress == '0x0000000000000000000000000000000000000000') {
                    continue;
                }
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                    state: tag.state
                });
            }

            // enable hbtc
            console.log('enable hbtc');
            await nTokenController.enable(hbtc.address);
            list = await nTokenController.list(0, 3, 1);
            for (var i in list) {
                let tag = list[i];
                if (tag.tokenAddress == '0x0000000000000000000000000000000000000000'
                || tag.ntokenAddress == '0x0000000000000000000000000000000000000000') {
                    continue;
                }
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                    state: tag.state
                });
            }

            // enable nYFI
            console.log('enable nYFI');
            await nTokenController.enable(nYFI.address);
            list = await nTokenController.list(0, 3, 1);
            for (var i in list) {
                let tag = list[i];
                if (tag.tokenAddress == '0x0000000000000000000000000000000000000000'
                || tag.ntokenAddress == '0x0000000000000000000000000000000000000000') {
                    continue;
                }
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                    state: tag.state
                });
            }

            // enable usdt
            console.log('enable usdt');
            await nTokenController.enable(usdt.address);
            list = await nTokenController.list(0, 3, 1);
            for (var i in list) {
                let tag = list[i];
                if (tag.tokenAddress == '0x0000000000000000000000000000000000000000'
                || tag.ntokenAddress == '0x0000000000000000000000000000000000000000') {
                    continue;
                }
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                    state: tag.state
                });
            }

            // getNTokenTag
            {
                let tag = await nTokenController.getNTokenTag(yfi.address);
                let token = await ERC20.at(tag.tokenAddress);
                let ntoken = await ERC20.at(tag.ntokenAddress);
                console.log({
                    tokenAddress: tag.tokenAddress,
                    token: {
                        name: await token.name(),
                        totalSupply: (await token.totalSupply()).toString()
                    },
                    ntokenAddress: tag.ntokenAddress,
                    ntoken: {
                        name: await ntoken.name(),
                        totalSupply: (await ntoken.totalSupply()).toString()
                    },
                    state: tag.state
                });
            }

            console.log('nTokenCount: ' + await nTokenController.getNTokenCount());
        }
    });
});
