// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/TransferHelper.sol";
import "./interface/INestLedger.sol";
import "./NestBase.sol";

/// @dev NEST 账本合约
contract NestLedger is NestBase, INestLedger {

    address immutable NEST_TOKEN_ADDRESS;

    /// @dev 配置结构体
    struct Config {
        // NEST分成（万分制）。2000
        uint32 nestRewardScale;
        // NTOKEN分成（万分制）。8000
        uint32 ntokenRedardScale;
    }

    struct UINT {
        uint value;
    }

    uint _nestLedger;
    mapping(address=>UINT) _ntokenLedger;
    mapping(address=>uint) _applications;
    Config _config;

    constructor(address nestTokenAddress) {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);

        // (
        //     , //address nestTokenAddress,
        //     _nestLedgerAddress, //address nestLedgerAddress,
              
        //     , //address nestMiningAddress,
        //     , //address nestPriceFacadeAddress,
              
        //     , //address nestVoteAddress,
        //     _nestQueryAddress, //address nestQueryAddress,
        //     , //address nnIncomeAddress,
        //       //address nTokenControllerAddress
              
        // ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev 设置配置
    /// @param config 配置结构体
    function setConfig(Config memory config) public onlyGovernance {
        _config = config;
    }

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() public view returns (Config memory) {
        return _config;
    }

    /// @dev 设置DAO应用
    /// @param addr DAO应用地址
    /// @param flag 授权标记，1表示授权，0表示取消授权
    function setApplication(address addr, uint flag) external onlyGovernance {
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
    /// @param from 指定从哪个ntoken的账本支出
    /// @param tokenAddress 目标token地址（0表示eth）
    /// @param to 转入地址
    /// @param value 转账金额
    function pay(address from, address tokenAddress, address to, uint value) override external {

        require(_applications[msg.sender] > 0, "NestLedger:!app");
        if (tokenAddress == address(0)) {
            if (from == NEST_TOKEN_ADDRESS) {
                _nestLedger -= value;
            } else {
                UINT storage balance = _ntokenLedger[from];
                balance.value = balance.value - value;
            }
            payable(to).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }
}