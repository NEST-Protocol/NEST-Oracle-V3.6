// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "./interface/INestPriceFacade.sol";
import "./interface/INestQuery.sol";
import "./interface/INestDAO.sol";
import "./NestBase.sol";

/// @dev 价格调用入口
contract NestPriceFacade is NestBase, INestPriceFacade {
    
    uint fee;
    INestQuery nestQuery;
    INestDAO nestDao;

    constructor() public {
        // TODO: 实现包月收费策略
    }

    function setFee(uint value) external onlyGovernance {
        fee = value;
    }

    function setAddress(address nestQueryAddress, address nestDaoAddress) external onlyGovernance {
        nestQuery = INestQuery(nestQueryAddress);
        nestDao = INestDAO(nestDaoAddress);
    }

    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function triggeredPrice(address tokenAddress) override external payable returns (uint blockNumber, uint price) {
        
        require(msg.value >= fee, "NestPriceFacade:fee not enough");
        nestDao.addReward { value: msg.value } (tokenAddress);
        return nestQuery.triggeredPrice(tokenAddress);
    }

    /// @dev 获取最新的触发价格完整信息
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return avgPrice 平均价格
    /// @return sigma 波动率的平方
    function triggeredPriceInfo(address tokenAddress) override external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigma) {

        require(msg.value >= fee, "NestPriceFacade:fee not enough");
        nestDao.addReward { value: msg.value } (tokenAddress);
        return nestQuery.triggeredPriceInfo(tokenAddress);
    }

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function latestPrice(address tokenAddress) override external payable returns (uint blockNumber, uint price) {
        
        require(msg.value >= fee, "NestPriceFacade:fee not enough");
        nestDao.addReward { value: msg.value } (tokenAddress);
        return nestQuery.latestPrice(tokenAddress);
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

        require(msg.value >= fee, "NestPriceFacade:fee not enough");
        nestDao.addReward { value: msg.value } (tokenAddress);
        return nestQuery.latestPriceAndTriggeredPriceInfo(tokenAddress);
    }
}