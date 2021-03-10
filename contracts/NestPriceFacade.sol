// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./interface/INestPriceFacade.sol";
import "./interface/INestQuery.sol";
import "./interface/INestLedger.sol";
import "./interface/INestGovernance.sol";
import "./NestBase.sol";

/// @dev 价格调用入口
contract NestPriceFacade is NestBase, INestPriceFacade {

    constructor() {
        // TODO: ntoken和token价格一起调用时的收费细节：价格，均价，波动率，最新价格
    }

    Config _config;
    address _nestLedgerAddress;
    address _nestQueryAddress;

    /// @dev 修改配置
    /// @param config 配置结构体
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);

        (
            //address nestTokenAddress
            , 
            //address nestLedgerAddress
            _nestLedgerAddress, 
            //address nestMiningAddress
            , 
            //address nestPriceFacadeAddress
            , 
            //address nestVoteAddress
            , 
            //address nestQueryAddress
            _nestQueryAddress, 
            //address nnIncomeAddress
            , 
            //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    // 支付调用费用
    function pay(address tokenAddress) private {

        uint fee = _config.fee;
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        } else {
            require(msg.value == _config.fee, "NestPriceFacade:!fee");
        }
        INestLedger(_nestLedgerAddress).addReward { value: fee } (tokenAddress);
    }

    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function triggeredPrice(address tokenAddress) override external payable returns (uint blockNumber, uint price) {
        pay(tokenAddress);
        return INestQuery(_nestQueryAddress).triggeredPrice(tokenAddress);
    }

    /// @dev 获取最新的触发价格完整信息
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return avgPrice 平均价格
    /// @return sigma 波动率的平方
    function triggeredPriceInfo(address tokenAddress) override external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigma) {
        pay(tokenAddress);
        return INestQuery(_nestQueryAddress).triggeredPriceInfo(tokenAddress);
    }

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function latestPrice(address tokenAddress) override external payable returns (uint blockNumber, uint price) {
        pay(tokenAddress);
        return INestQuery(_nestQueryAddress).latestPrice(tokenAddress);
    }

    /// @dev 返回latestPrice()和triggeredPriceInfo()两个方法的结果
    /// @param tokenAddress 目标token地址
    /// @return latestPriceBlockNumber 价格所在区块号
    /// @return latestPriceValue 价格(1eth可以兑换多少token)
    /// @return triggeredPriceBlockNumber 价格所在区块号
    /// @return triggeredPriceValue 价格(1eth可以兑换多少token)
    /// @return triggeredAvgPrice 平均价格
    /// @return triggeredSigma 波动率的平方
    function latestPriceAndTriggeredPriceInfo(address tokenAddress) 
    override
    external 
    payable 
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigma
    ) {
        pay(tokenAddress);
        return INestQuery(_nestQueryAddress).latestPriceAndTriggeredPriceInfo(tokenAddress);
    }
}