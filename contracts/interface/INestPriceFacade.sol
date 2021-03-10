// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev 价格调用入口
interface INestPriceFacade {
    
    struct Config {
        uint fee;
    }
    
    /// @dev 修改配置
    /// @param config 配置结构体
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() external view returns (Config memory);

    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function triggeredPrice(address tokenAddress) external payable returns (uint blockNumber, uint price);

    /// @dev 获取最新的触发价格完整信息
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return avgPrice 平均价格
    /// @return sigma 波动率的平方
    function triggeredPriceInfo(address tokenAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigma);

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function latestPrice(address tokenAddress) external payable returns (uint blockNumber, uint price);

    /// @dev 返回latestPrice()和triggeredPriceInfo()两个方法的结果
    /// @param tokenAddress 目标token地址
    /// @return latestPriceBlockNumber 价格所在区块号
    /// @return latestPriceValue 价格(1eth可以兑换多少token)
    /// @return triggeredPriceBlockNumber 价格所在区块号
    /// @return triggeredPriceValue 价格(1eth可以兑换多少token)
    /// @return triggeredAvgPrice 平均价格
    /// @return triggeredSigma 波动率的平方
    function latestPriceAndTriggeredPriceInfo(address tokenAddress) 
    external 
    payable 
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigma
    );
}