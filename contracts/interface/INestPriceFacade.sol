// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev 价格调用入口
interface INestPriceFacade {
    
    /// @dev 配置结构体
    struct Config {
        // 单轨询价费用。0.01ether
        uint96 singleFee;
        // 双轨询价费用。0.01ether
        uint96 doubleFee;
        // 调用地址的正常状态标记。0
        uint8 normalFlag;
    }

    /// @dev 修改配置
    /// @param config 配置结构体
    function setConfig(Config memory config) external;

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() external view returns (Config memory);

    /// @dev 设置地址标记。只有地址标记和配置里面的normalFlag相等的才能够调用价格
    /// @param addr 目标地址
    /// @param flag 地址标记
    function setAddressFlag(address addr, uint flag) external;

    /// @dev 获取标记。只有地址标记和配置里面的normalFlag相等的才能够调用价格
    /// @param addr 目标地址
    /// @return 地址标记
    function getAddressFlag(address addr) external view returns(uint);

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
    /// @return sigmaSQ 波动率的平方。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
    function triggeredPriceInfo(address tokenAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ);

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
    /// @return triggeredSigmaSQ 波动率的平方。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
    function latestPriceAndTriggeredPriceInfo(address tokenAddress) 
    external 
    payable 
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    );

    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    function triggeredPrice2(address tokenAddress) external payable returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice);

    /// @dev 获取最新的触发价格完整信息
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格（1eth可以兑换多少token）
    /// @return avgPrice 平均价格
    /// @return sigmaSQ 波动率的平方（18位小数）。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    /// @return ntokenAvgPrice 平均价格
    /// @return ntokenSigmaSQ 波动率的平方（18位小数）。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
    function triggeredPriceInfo2(address tokenAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ, uint ntokenBlockNumber, uint ntokenPrice, uint ntokenAvgPrice, uint ntokenSigmaSQ);

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    function latestPrice2(address tokenAddress) external payable returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice);
}