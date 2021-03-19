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
        // TODO: 考虑更加友好的支持nest挖矿和ntoken挖矿分开约合并的合约设计
    }

    Config _config;
    address _nestLedgerAddress;
    address _nestQueryAddress;

    /// @dev 万分之一eth，手续费单位
    uint constant DIMI_ETHER = 1 ether / 10000;

    /// @dev 地址标记，只有用户的地址标记和配置标记一致的地址才可以调用价格
    mapping(address=>uint) _addressFlags;

    /// @dev (tokenAddress=>INestQuery)。优先使用此地址映射的INestQuery地址进行价格查询，可以通过此功能来将nest价格查询和ntoken价格查询独立起来
    mapping(address=>address) _nestQueryMapping;

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

    /// @dev 设置地址标记。只有地址标记和配置里面的normalFlag相等的才能够调用价格
    /// @param addr 目标地址
    /// @param flag 地址标记
    function setAddressFlag(address addr, uint flag) override external onlyGovernance {
        _addressFlags[addr] = flag;
    }

    /// @dev 获取标记。只有地址标记和配置里面的normalFlag相等的才能够调用价格
    /// @param addr 目标地址
    /// @return 地址标记
    function getAddressFlag(address addr) override external view returns(uint) {
        return _addressFlags[addr];
    }

    /// @dev 设置NestQuery地址映射
    /// @param tokenAddress token地址
    /// @param nestQueryAddress INestQuery地址，0表示删除映射
    function setNestQuery(address tokenAddress, address nestQueryAddress) override external onlyGovernance {
        _nestQueryMapping[tokenAddress] = nestQueryAddress;
    }

    // @dev 获取NestQuery地址映射
    /// @param tokenAddress token地址
    /// @return nestQueryAddress INestQuery地址，0表示没有映射
    function getNestQuery(address tokenAddress) override external view returns (address) {
        return _nestQueryMapping[tokenAddress];
    }

    // 获取nestQuery地址
    function _getNestQuery(address tokenAddress) private view returns (address) {
        address addr = _nestQueryMapping[tokenAddress];
        if (addr == address(0)) {
            return _nestQueryAddress;
        }
        return addr;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请调用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {

        super.update(nestGovernanceAddress);
        (
            //address nestTokenAddress
            , 
            //address nestNodeAddress
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
    function _pay(address tokenAddress, uint fee) private {

        fee = fee * DIMI_ETHER;
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        } else {
            require(msg.value == fee, "NestPriceFacade:!fee");
        }
        INestLedger(_nestLedgerAddress).addReward { value: fee } (tokenAddress);
    }

    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function triggeredPrice(address tokenAddress) override external payable returns (uint blockNumber, uint price) {

        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee);
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPrice(tokenAddress);
    }

    /// @dev 获取最新的触发价格完整信息
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return avgPrice 平均价格
    /// @return sigmaSQ 波动率的平方。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
    function triggeredPriceInfo(address tokenAddress) override external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee);
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPriceInfo(tokenAddress);
    }

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    function latestPrice(address tokenAddress) override external payable returns (uint blockNumber, uint price) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee);
        return INestQuery(_getNestQuery(tokenAddress)).latestPrice(tokenAddress);
    }

    /// @dev 返回latestPrice()和triggeredPriceInfo()两个方法的结果
    /// @param tokenAddress 目标token地址
    /// @return latestPriceBlockNumber 价格所在区块号
    /// @return latestPriceValue 价格(1eth可以兑换多少token)
    /// @return triggeredPriceBlockNumber 价格所在区块号
    /// @return triggeredPriceValue 价格(1eth可以兑换多少token)
    /// @return triggeredAvgPrice 平均价格
    /// @return triggeredSigmaSQ 波动率的平方。当前实现假定波动率不可能超过1，与此对应的，当返回值等于999999999999996447时，表示波动率已经超过可以表示的范围
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
        uint triggeredSigmaSQ
    ) {

        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee);
        return INestQuery(_getNestQuery(tokenAddress)).latestPriceAndTriggeredPriceInfo(tokenAddress);
    }

    /// @dev 获取最新的触发价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    function triggeredPrice2(address tokenAddress) override external payable returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.doubleFee);
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPrice2(tokenAddress);
    }

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
    function triggeredPriceInfo2(address tokenAddress) override external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ, uint ntokenBlockNumber, uint ntokenPrice, uint ntokenAvgPrice, uint ntokenSigmaSQ) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.doubleFee);
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPriceInfo2(tokenAddress);
    }

    /// @dev 获取最新的生效价格
    /// @param tokenAddress 目标token地址
    /// @return blockNumber 价格所在区块号
    /// @return price 价格(1eth可以兑换多少token)
    /// @return ntokenBlockNumber ntoken价格所在区块号
    /// @return ntokenPrice 价格(1eth可以兑换多少ntoken)
    function latestPrice2(address tokenAddress) override external payable returns (uint blockNumber, uint price, uint ntokenBlockNumber, uint ntokenPrice) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.doubleFee);
        return INestQuery(_getNestQuery(tokenAddress)).latestPrice2(tokenAddress);
    }
}