// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/IERC20.sol";
import "./interface/INestMapping.sol";
import "./interface/INestQuery.sol";
import "./NestBase.sol";

/// @dev The contract is for redeeming nest token and getting ETH in return
abstract contract NestMapping is NestBase, INestMapping {

    constructor() { }

    /// @dev nest代币合约地址
    address _nestTokenAddress;
    /// @dev nest node合约地址
    address _nestNodeAddress;
    /// @dev nest账本合约
    address _nestLedgerAddress;
    /// @dev 挖矿合约地址
    address _nestMiningAddress;
    /// @dev 价格调用入口合约地址
    address _nestPriceFacadeAddress;
    /// @dev 投票合约地址
    address _nestVoteAddress;
    /// @dev 提供价格的合约地址
    address _nestQueryAddress;
    /// @dev NN挖矿合约
    address _nnIncomeAddress;
    /// @dev nToken管理合约地址
    address _nTokenControllerAddress;
    
    /// @dev 在系统内注册过的地址
    mapping(string=>address) _registeredAddress;

    /// @dev 获取系统内置的合约地址
    /// @param nestTokenAddress nest代币合约地址
    /// @param nestNodeAddress nest node合约地址
    /// @param nestLedgerAddress nest账本合约
    /// @param nestMiningAddress 挖矿合约地址
    /// @param nestPriceFacadeAddress 价格调用入口合约地址
    /// @param nestVoteAddress 投票合约地址
    /// @param nestQueryAddress 提供价格的合约地址
    /// @param nnIncomeAddress NN挖矿合约
    /// @param nTokenControllerAddress nToken管理合约地址
    function setBuiltinAddress(
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
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

    /// @dev 获取系统内置的合约地址
    /// @return nestTokenAddress nest代币合约地址
    /// @return nestNodeAddress nest node合约地址
    /// @return nestLedgerAddress nest账本合约
    /// @return nestMiningAddress 挖矿合约地址
    /// @return nestPriceFacadeAddress 价格调用入口合约地址
    /// @return nestVoteAddress 投票合约地址
    /// @return nestQueryAddress 提供价格的合约地址
    /// @return nnIncomeAddress NN挖矿合约
    /// @return nTokenControllerAddress nToken管理合约地址
    function getBuiltinAddress() override external view returns (
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
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
            _nestPriceFacadeAddress,
            _nestVoteAddress,
            _nestQueryAddress,
            _nnIncomeAddress,
            _nTokenControllerAddress
        );
    }

    /// @dev 获取nest代币合约地址
    /// @return nest代币合约地址
    function getNestTokenAddress() override external view returns (address) { return _nestTokenAddress; }

    /// @dev 获取nest node合约地址
    /// @return nest node合约地址
    function getNestNodeAddress() override external view returns (address) { return _nestNodeAddress; }

    /// @dev 获取nest账本合约地址
    /// @return nest账本合约地址
    function getNestLedgerAddress() override external view returns (address) { return _nestLedgerAddress; }

    /// @dev 获取挖矿合约地址
    /// @return 挖矿合约地址
    function getNestMiningAddress() override external view returns (address) { return _nestMiningAddress; }

    /// @dev 获取价格调用入口合约地址
    /// @return 价格调用入口合约地址
    function getNestPriceFacadeAddress() override external view returns (address) { return _nestPriceFacadeAddress; }

    /// @dev 获取投票合约地址
    /// @return 投票合约地址
    function getNestVoteAddress() override external view returns (address) { return _nestVoteAddress; }

    /// @dev 获取提供价格的合约地址
    /// @return 提供价格的合约地址
    function getNestQueryAddress() override external view returns (address) { return _nestQueryAddress; }

    /// @dev 获取NN挖矿合约
    /// @return NN挖矿合约
    function getNnIncomeAddress() override external view returns (address) { return _nnIncomeAddress; }

    /// @dev 获取nToken管理合约地址
    /// @return nToken管理合约地址
    function getNTokenControllerAddress() override external view returns (address) { return _nTokenControllerAddress; }

    /// @dev 注册地址。通过此处注册的地址，是被nest系统接受的地址
    /// @param key 地址标识
    /// @param addr 目标地址。0地址表示删除注册信息
    function register(string memory key, address addr) override external onlyGovernance {
        _registeredAddress[key] = addr;
    }

    /// @dev 查询注册地址
    /// @param key 地址标识
    /// @return 目标地址
    function getAddress(string memory key) override external view returns (address) {
        return _registeredAddress[key];
    }
}