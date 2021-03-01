// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

/// @dev 投票合约需要实现的接口
interface IVotePropose {

    /// @dev 投票通过后需要执行的代码
    function run() external;
}