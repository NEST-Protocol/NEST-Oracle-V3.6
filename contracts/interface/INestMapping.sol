// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev NEST映射合约
interface INestMapping {

    /// @dev 获取系统内置的合约地址
    /// @param nestTokenAddress nest代币合约地址
    /// @param nestLedgerAddress nest账本合约
    /// @param nestMiningAddress 挖矿合约地址
    /// @param nestPriceFacadeAddress 价格调用入口合约地址
    /// @param nestVoteAddress 投票合约地址
    /// @param nestQueryAddress 提供价格的合约地址
    /// @param nnIncomeAddress NN挖矿合约
    /// @param nTokenControllerAddress nToken管理合约地址
    function setBuiltinAddress(
        address nestTokenAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) external;

    /// @dev 获取系统内置的合约地址
    /// @return nestTokenAddress nest代币合约地址
    /// @return nestLedgerAddress nest账本合约
    /// @return nestMiningAddress 挖矿合约地址
    /// @return nestPriceFacadeAddress 价格调用入口合约地址
    /// @return nestVoteAddress 投票合约地址
    /// @return nestQueryAddress 提供价格的合约地址
    /// @return nnIncomeAddress NN挖矿合约
    /// @return nTokenControllerAddress nToken管理合约地址
    function getBuiltinAddress() external view returns (
        address nestTokenAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    );

    /// @dev 获取nest代币合约地址
    /// @return 挖矿合约地址
    function getNestTokenAddress() external view returns (address);

    /// @dev 获取nest账本合约地址
    /// @return 账本合约地址
    function getNestLedgerAddress() external view returns (address);

    /// @dev 获取挖矿合约地址
    /// @return 挖矿合约地址
    function getNestMiningAddress() external view returns (address);

    /// @dev 获取价格调用入口合约地址
    /// @return 价格调用入口合约地址
    function getNestPriceFacadeAddress() external view returns (address);

    /// @dev 获取投票合约地址
    /// @return 投票合约地址
    function getNestVoteAddress() external view returns (address);

    /// @dev 获取提供价格的合约地址
    /// @return 提供价格的合约地址
    function getNestQueryAddress() external view returns (address);

    /// @dev 获取NN挖矿合约
    /// @return NN挖矿合约
    function getNnIncomeAddress() external view returns (address);

    /// @dev 获取nToken管理合约地址
    /// @return nToken管理合约地址
    function getNTokenControllerAddress() external view returns (address);

    /// @dev 注册地址。通过此处注册的地址，是被nest系统接受的地址
    /// @param key 地址标识
    /// @param addr 目标地址。0地址表示删除注册信息
    function register(string memory key, address addr) external;

    /// @dev 查询注册地址
    /// @param key 地址标识
    /// @return 目标地址
    function getAddress(string memory key) external view returns (address);
}