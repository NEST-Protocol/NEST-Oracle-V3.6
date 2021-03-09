// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./interface/INestPriceFacade.sol";
import "./interface/INestQuery.sol";
import "./interface/INestLedger.sol";
import "./interface/INestGovernance.sol";
import "./NestBase.sol";

/// @dev 价格调用入口
contract NestPriceFacade is NestBase, INestPriceFacade {

    struct Config {
        uint fee;
    }

    address _nestLedgerAddress;
    address _nestQueryAddress;

    Config _config;

    constructor() {
        // TODO: 实现包月收费策略
    }

    function setConfig(Config memory config) external onlyGovernance {
        _config = config;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);

        (
            , //address nestTokenAddress,
            _nestLedgerAddress, //address nestLedgerAddress,
              
            , //address nestMiningAddress,
            , //address nestPriceFacadeAddress,
              
            , //address nestVoteAddress,
            _nestQueryAddress, //address nestQueryAddress,
            , //address nnIncomeAddress,
              //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    // function setAddress(address nestQueryAddress, address nestDaoAddress) external onlyGovernance {
    //     nestQuery = INestQuery(nestQueryAddress);
    //     nestDao = INestDAO(nestDaoAddress);
    // }

    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function triggeredPrice(address tokenAddress) override external payable returns (uint blockNumber, uint price) {
        
        require(msg.value >= _config.fee, "NestPriceFacade:!fee");
        INestLedger(_nestLedgerAddress).addReward { value: msg.value } (tokenAddress);
        return INestQuery(_nestQueryAddress).triggeredPrice(tokenAddress);
    }

    /// @dev 获取最新的触发价格完整信息
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return avgPrice 平均价格
    /// @return sigma 波动率的平方
    function triggeredPriceInfo(address tokenAddress) override external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigma) {

        require(msg.value >= _config.fee, "NestPriceFacade:!fee");
        INestLedger(_nestLedgerAddress).addReward { value: msg.value } (tokenAddress);
        return INestQuery(_nestQueryAddress).triggeredPriceInfo(tokenAddress);
    }

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function latestPrice(address tokenAddress) override external payable returns (uint blockNumber, uint price) {
        
        require(msg.value >= _config.fee, "NestPriceFacade:!fee");
        INestLedger(_nestLedgerAddress).addReward { value: msg.value } (tokenAddress);
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

        require(msg.value >= _config.fee, "NestPriceFacade:!fee");
        INestLedger(_nestLedgerAddress).addReward { value: msg.value } (tokenAddress);
        return INestQuery(_nestQueryAddress).latestPriceAndTriggeredPriceInfo(tokenAddress);
    }
}