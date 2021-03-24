// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/IERC20.sol";
import "./interface/INestMapping.sol";
import "./interface/INestQuery.sol";
import "./NestBase.sol";

/// @dev The contract is for nest builtin contract address mapping
abstract contract NestMapping is NestBase, INestMapping {

    constructor() { }

    /// @dev Address of nest token contract
    address _nestTokenAddress;
    /// @dev Address of nest node contract
    address _nestNodeAddress;
    /// @dev INestLedger implemention contract address
    address _nestLedgerAddress;
    /// @dev INestMining implemention contract address for nest
    address _nestMiningAddress;
    /// @dev INestMining implemention contract address for ntoken
    address _ntokenMiningAddress;
    /// @dev INestPriceFacade implemention contract address
    address _nestPriceFacadeAddress;
    /// @dev INestVote implemention contract address
    address _nestVoteAddress;
    /// @dev INestQuery implemention contract address
    address _nestQueryAddress;
    /// @dev NNIncome contract address
    address _nnIncomeAddress;
    /// @dev INTokenController implemention contract address
    address _nTokenControllerAddress;
    
    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param nestTokenAddress Address of nest token contract
    /// @param nestNodeAddress Address of nest node contract
    /// @param nestLedgerAddress INestLedger implemention contract address
    /// @param nestMiningAddress INestMining implemention contract address for nest
    /// @param ntokenMiningAddress INestMining implemention contract address for ntoken
    /// @param nestPriceFacadeAddress INestPriceFacade implemention contract address
    /// @param nestVoteAddress INestVote implemention contract address
    /// @param nestQueryAddress INestQuery implemention contract address
    /// @param nnIncomeAddress NNIncome contract address
    /// @param nTokenControllerAddress INTokenController implemention contract address
    function setBuiltinAddress(
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) override external onlyGovernance {
        
        if (nestTokenAddress != address(0)) {
            _nestTokenAddress = nestTokenAddress;
        }
        if (nestNodeAddress != address(0)) {
            _nestNodeAddress = nestNodeAddress;
        }
        if (nestLedgerAddress != address(0)) {
            _nestLedgerAddress = nestLedgerAddress;
        }
        if (nestMiningAddress != address(0)) {
            _nestMiningAddress = nestMiningAddress;
        }
        if (ntokenMiningAddress != address(0)) {
            _ntokenMiningAddress = ntokenMiningAddress;
        }
        if (nestPriceFacadeAddress != address(0)) {
            _nestPriceFacadeAddress = nestPriceFacadeAddress;
        }
        if (nestVoteAddress != address(0)) {
            _nestVoteAddress = nestVoteAddress;
        }
        if (nestQueryAddress != address(0)) {
            _nestQueryAddress = nestQueryAddress;
        }
        if (nnIncomeAddress != address(0)) {
            _nnIncomeAddress = nnIncomeAddress;
        }
        if (nTokenControllerAddress != address(0)) {
            _nTokenControllerAddress = nTokenControllerAddress;
        }
    }

    /// @dev Set the built-in contract address of the system
    /// @return nestTokenAddress Address of nest token contract
    /// @return nestNodeAddress Address of nest node contract
    /// @return nestLedgerAddress INestLedger implemention contract address
    /// @return nestMiningAddress INestMining implemention contract address for nest
    /// @return ntokenMiningAddress INestMining implemention contract address for ntoken
    /// @return nestPriceFacadeAddress INestPriceFacade implemention contract address
    /// @return nestVoteAddress INestVote implemention contract address
    /// @return nestQueryAddress INestQuery implemention contract address
    /// @return nnIncomeAddress NNIncome contract address
    /// @return nTokenControllerAddress INTokenController implemention contract address
    function getBuiltinAddress() override external view returns (
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) {
        return (
            _nestTokenAddress,
            _nestNodeAddress,
            _nestLedgerAddress,
            _nestMiningAddress,
            _ntokenMiningAddress,
            _nestPriceFacadeAddress,
            _nestVoteAddress,
            _nestQueryAddress,
            _nnIncomeAddress,
            _nTokenControllerAddress
        );
    }

    /// @dev Get address of nest token contract
    /// @return Address of nest token contract
    function getNestTokenAddress() override external view returns (address) { return _nestTokenAddress; }

    /// @dev Get address of nest node contract
    /// @return Address of nest node contract
    function getNestNodeAddress() override external view returns (address) { return _nestNodeAddress; }

    /// @dev Get INestLedger implemention contract address
    /// @return INestLedger implemention contract address
    function getNestLedgerAddress() override external view returns (address) { return _nestLedgerAddress; }

    /// @dev Get INestMining implemention contract address for nest
    /// @return INestMining implemention contract address for nest
    function getNestMiningAddress() override external view returns (address) { return _nestMiningAddress; }

    /// @dev Get INestMining implemention contract address for ntoken
    /// @return INestMining implemention contract address for ntoken
    function getNTokenMiningAddress() override external view returns (address) { return _ntokenMiningAddress; }

    /// @dev Get INestPriceFacade implemention contract address
    /// @return INestPriceFacade implemention contract address
    function getNestPriceFacadeAddress() override external view returns (address) { return _nestPriceFacadeAddress; }

    /// @dev Get INestVote implemention contract address
    /// @return INestVote implemention contract address
    function getNestVoteAddress() override external view returns (address) { return _nestVoteAddress; }

    /// @dev Get INestQuery implemention contract address
    /// @return INestQuery implemention contract address
    function getNestQueryAddress() override external view returns (address) { return _nestQueryAddress; }

    /// @dev Get NNIncome contract address
    /// @return NNIncome contract address
    function getNnIncomeAddress() override external view returns (address) { return _nnIncomeAddress; }

    /// @dev Get INTokenController implemention contract address
    /// @return INTokenController implemention contract address
    function getNTokenControllerAddress() override external view returns (address) { return _nTokenControllerAddress; }

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) override external onlyGovernance {
        _registeredAddress[key] = addr;
    }

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) override external view returns (address) {
        return _registeredAddress[key];
    }
}