// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "../legacy/Nest_NToken.sol";

contract NHBTC is Nest_NToken {
    constructor (string memory _name, string memory _symbol, address voteFactory, address bidder) Nest_NToken(_name, _symbol, voteFactory, bidder) {
    }
}
