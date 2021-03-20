// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev The interface defines methods for nest builtin contract address mapping
interface INestMapping {

    /// @dev Set the built-in contract address of the system
    /// @param nestTokenAddress Address of nest token contract
    /// @param nestNodeAddress Address of nest node contract
    /// @param nestLedgerAddress INestLedger implemention contract address
    /// @param nestMiningAddress INestMining implemention contract address
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
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) external;

    /// @dev Set the built-in contract address of the system
    /// @return nestTokenAddress Address of nest token contract
    /// @return nestNodeAddress Address of nest node contract
    /// @return nestLedgerAddress INestLedger implemention contract address
    /// @return nestMiningAddress INestMining implemention contract address
    /// @return nestPriceFacadeAddress INestPriceFacade implemention contract address
    /// @return nestVoteAddress INestVote implemention contract address
    /// @return nestQueryAddress INestQuery implemention contract address
    /// @return nnIncomeAddress NNIncome contract address
    /// @return nTokenControllerAddress INTokenController implemention contract address
    function getBuiltinAddress() external view returns (
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    );

    /// @dev Get address of nest token contract
    /// @return Address of nest token contract
    function getNestTokenAddress() external view returns (address);

    /// @dev Get address of nest node contract
    /// @return Address of nest node contract
    function getNestNodeAddress() external view returns (address);

    /// @dev Get INestLedger implemention contract address
    /// @return INestLedger implemention contract address
    function getNestLedgerAddress() external view returns (address);

    /// @dev Get INestMining implemention contract address
    /// @return INestMining implemention contract address
    function getNestMiningAddress() external view returns (address);

    /// @dev Get INestPriceFacade implemention contract address
    /// @return INestPriceFacade implemention contract address
    function getNestPriceFacadeAddress() external view returns (address);

    /// @dev Get INestVote implemention contract address
    /// @return INestVote implemention contract address
    function getNestVoteAddress() external view returns (address);

    /// @dev Get INestQuery implemention contract address
    /// @return INestQuery implemention contract address
    function getNestQueryAddress() external view returns (address);

    /// @dev Get NNIncome contract address
    /// @return NNIncome contract address
    function getNnIncomeAddress() external view returns (address);

    /// @dev Get INTokenController implemention contract address
    /// @return INTokenController implemention contract address
    function getNTokenControllerAddress() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view returns (address);
}