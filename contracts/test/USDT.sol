// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "./TestERC20.sol";

contract USDT is TestERC20 {
    constructor (string memory name, string memory symbol, uint8 decimals) TestERC20(name, symbol, decimals) {
    }
}
