// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/TransferHelper.sol";
import "./interface/INestLedger.sol";
import "./NestBase.sol";

/// @dev NEST 账本合约
contract NestLedger is NestBase, INestLedger {

    constructor(address nestTokenAddress) {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    struct UINT {
        uint value;
    }

    Config _config;
    // nest账本
    uint _nestLedger;
    // ntoken账本
    mapping(address=>UINT) _ntokenLedger;
    // DAO应用
    mapping(address=>uint) _applications;
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

    /// @dev 设置DAO应用
    /// @param addr DAO应用地址
    /// @param flag 授权标记，1表示授权，0表示取消授权
    function setApplication(address addr, uint flag) override external onlyGovernance {
        _applications[addr] = flag;
    }

    /// @dev 收益分成
    /// @param ntokenAddress ntoken地址
    function carveReward(address ntokenAddress) override external payable {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _nestLedger += msg.value;
        } else {
            Config memory config = _config;
            UINT storage balance = _ntokenLedger[ntokenAddress];
            // TODO: 使用减法看是否可以节省gas
            balance.value = balance.value + msg.value * uint(config.nestRewardScale) / 10000;
            _nestLedger = _nestLedger + msg.value * uint(config.ntokenRedardScale) / 10000;
        }
    }

    /// @dev ntoken收益
    /// @param ntokenAddress ntoken地址
    function addReward(address ntokenAddress) override external payable {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _nestLedger += msg.value;
        } else {
            UINT storage balance = _ntokenLedger[ntokenAddress];
            balance.value = balance.value + msg.value;
        }
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The notoken address
    function totalRewards(address ntokenAddress) override external view returns (uint) {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            return _nestLedger;
        }
        return _ntokenLedger[ntokenAddress].value;
    }

    /// @dev 支付资金
    /// @param ntokenAddress 表示需要和哪个ntoken进行结算
    /// @param tokenAddress 接收资金的token地址（0表示eth）
    /// @param to 接收资金的地址
    /// @param value 接收资金的数量
    function pay(address ntokenAddress, address tokenAddress, address to, uint value) override external {

        require(_applications[msg.sender] > 0, "NestLedger:!app");
        if (tokenAddress == address(0)) {
            if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                _nestLedger -= value;
            } else {
                UINT storage balance = _ntokenLedger[ntokenAddress];
                balance.value = balance.value - value;
            }
            payable(to).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    /// @dev 结算资金
    /// @param ntokenAddress 表示需要和哪个ntoken进行结算
    /// @param tokenAddress 接收资金的token地址（0表示eth）
    /// @param to 接收资金的地址
    /// @param value 接收资金的数量
    function settle(address ntokenAddress, address tokenAddress, address to, uint value) override external payable {

        require(_applications[msg.sender] > 0, "NestLedger:!app");

        if (tokenAddress == address(0)) {
            if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                _nestLedger = _nestLedger + msg.value - value;
            } else {
                UINT storage balance = _ntokenLedger[ntokenAddress];
                balance.value = balance.value + msg.value - value;
            }
            payable(to).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
            if (msg.value > 0) {
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                    _nestLedger += msg.value;
                } else {
                    UINT storage balance = _ntokenLedger[ntokenAddress];
                    balance.value = balance.value + msg.value;
                }
            }
        }
    } 
}