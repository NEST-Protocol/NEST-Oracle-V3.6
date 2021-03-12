// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/IERC20.sol";
import "./interface/INestLedger.sol";
import "./interface/INestQuery.sol";
import "./interface/INestRedeeming.sol";
import "./NestBase.sol";

/// @dev The contract is for redeeming nest token and getting ETH in return
contract NestRedeeming is NestBase, INestRedeeming {

    constructor(address nestTokenAddress) {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    /// @dev 治理地址信息
    struct GovernanceInfo {
        address addr;
        uint96 flag;
    }

    /// @dev 回购信息
    struct RedeemInfo {
        
        // 已经消耗的回购额度
        // block.number * quotaPerBlock - quota
        uint128 quota;

        // 回购发行量阈值，当此值和config.activeThreshold相等时，启用回购，无需检查ntoken的发行量
        // 当config.activeThreshold修改时，会重新根据发行量检查是否启用回购
        uint32 threshold;
    }

    Config _config;
    mapping(address=>RedeemInfo) redeemLedger;
    address _nestLedgerAddress;
    address _nestQueryAddress;
    address immutable NEST_TOKEN_ADDRESS;

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

    /// @dev Redeem ntokens for ethers
    /// @notice Ethfee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount The amount of ntoken
    function redeem(address ntokenAddress, uint amount) override external payable {
        
        // 1. 加载配置
        Config memory config = _config;
        require(msg.value == uint(config.fee), "NestDAO:!fee");

        // 2. 检查回购状态
        RedeemInfo storage redeemInfo = redeemLedger[ntokenAddress];
        if (redeemInfo.threshold != config.activeThreshold) {
            require(IERC20(ntokenAddress).totalSupply() >= uint(config.activeThreshold) * 10000 ether, "NestDAO:!totalSupply");
            redeemInfo.threshold = config.activeThreshold;
        }

        // 3. 查询价格
        (
            /* uint latestPriceBlockNumber */, 
            uint latestPriceValue,
            /* uint triggeredPriceBlockNumber */,
            /* uint triggeredPriceValue */,
            uint triggeredAvgPrice,
            /* uint triggeredSigma */
        ) = INestQuery(_nestQueryAddress).latestPriceAndTriggeredPriceInfo(ntokenAddress);

        // 4. 计算回购可以换得的eth数量
        uint value = amount * 1 ether / latestPriceValue;
        uint quota;

        // 5. 计算回购额度
        // nest回购额度
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            quota = block.number * uint(config.nestPerBlock) * 1 ether - redeemInfo.quota;
            if (quota > uint(config.nestLimit) * 1 ether) {
                quota = uint(config.nestLimit) * 1 ether;
            }
            redeemInfo.quota = uint128(block.number * uint(config.nestPerBlock) * 1 ether - (quota - amount));
            //nestLedger = nestLedger + msg.value - value;
        } 
        // ntoken回购额度
        else {
            quota = block.number * uint(config.ntokenPerBlock) * 1 ether - redeemInfo.quota;
            if (quota > uint(config.ntokenLimit) * 1 ether) {
                quota = uint(config.ntokenLimit) * 1 ether;
            }
            redeemInfo.quota = uint128(block.number * uint(config.ntokenPerBlock) * 1 ether - (quota - amount));
            //UINT storage balance = ntokenLedger[ntokenAddress];
            //balance.value = balance.value + msg.value - value;
        }

        // 6. 检查回购额度和价格偏差
        require(quota >= amount, "NestDAO:!amount");
        require(
            latestPriceValue <= triggeredAvgPrice * (10000 + uint(config.priceDeviationLimit)) / 10000 && 
            latestPriceValue >= triggeredAvgPrice * (10000 - uint(config.priceDeviationLimit)) / 10000, "NestDAO:!price");
        
        // 7. 转入回购的ntoken
        address nestLedgerAddress = _nestLedgerAddress;
        TransferHelper.safeTransferFrom(ntokenAddress, msg.sender, address(nestLedgerAddress), amount);
        //payable(msg.sender).transfer(value);
        
        // 8. 结算资金
        // TODO: 考虑改为一个结算方法（settle）
        INestLedger(nestLedgerAddress).addReward { value: msg.value } (ntokenAddress);
        INestLedger(nestLedgerAddress).pay(ntokenAddress, address(0), msg.sender, value);
    }

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) override public view returns (uint) {

        // 1. 加载配置
        Config memory config = _config;

        // 2. 检查回购状态
        RedeemInfo storage redeemInfo = redeemLedger[ntokenAddress];
        if (redeemInfo.threshold != config.activeThreshold) {
            if (IERC20(ntokenAddress).totalSupply() < uint(config.activeThreshold) * 10000 ether) return 0;
        }

        // 3. 计算回购额度
        uint quota;
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            quota = block.number * uint(config.nestPerBlock) * 1 ether - quota;
            if (quota > uint(config.nestLimit) * 1 ether) {
                quota = uint(config.nestLimit) * 1 ether;
            }
        } else {
            quota = block.number * uint(config.ntokenPerBlock) * 1 ether - quota;
            if (quota > uint(config.ntokenLimit) * 1 ether) {
                quota = uint(config.ntokenLimit) * 1 ether;
            }
        } 

        return quota;
    }
}