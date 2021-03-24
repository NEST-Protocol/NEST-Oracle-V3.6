// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/TransferHelper.sol";
import "./interface/INestLedger.sol";
import "./NestBase.sol";

/// @dev Nest ledger contract
contract NestLedger is NestBase, INestLedger {

    constructor(address nestTokenAddress) {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    struct UINT {
        uint value;
    }

    Config _config;
    // nest ledger
    uint _nestLedger;
    // ntoken ledger
    mapping(address=>UINT) _ntokenLedger;
    // DAO applications
    mapping(address=>uint) _applications;
    /// @dev Address of nest token contract
    address immutable NEST_TOKEN_ADDRESS;

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) override external onlyGovernance {
        _applications[addr] = flag;
    }

    /// @dev Carve reward
    /// @param ntokenAddress Destination ntoken address
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

    /// @dev Add reward
    /// @param ntokenAddress Destination ntoken address
    function addReward(address ntokenAddress) override external payable {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _nestLedger += msg.value;
        } else {
            UINT storage balance = _ntokenLedger[ntokenAddress];
            balance.value = balance.value + msg.value;
        }
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The ntoken address
    function totalRewards(address ntokenAddress) override external view returns (uint) {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            return _nestLedger;
        }
        return _ntokenLedger[ntokenAddress].value;
    }

    /// @dev Pay
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
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

    /// @dev Settlement
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to settle with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
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