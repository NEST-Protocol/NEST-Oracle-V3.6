// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

/// @dev This interface defines the ProxyAdmin methods
interface IProxyAdmin {

    /// @dev Upgrades a proxy to the newest implementation of a contract
    /// @param proxy Proxy to be upgraded
    /// @param implementation the address of the Implementation
    function upgrade(address proxy, address implementation) external;

    /// @dev Transfers ownership of the contract to a new account (`newOwner`)
    ///      Can only be called by the current owner
    /// @param newOwner The address of new owner
    function transferOwnership(address newOwner) external;
}