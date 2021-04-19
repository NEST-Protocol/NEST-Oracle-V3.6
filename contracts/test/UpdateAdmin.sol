// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "../interface/IVotePropose.sol";
import "../interface/INestMapping.sol";
import "../interface/INestGovernance.sol";

// Add and remove administrators by voting
contract UpdateAdmin is IVotePropose {

    address _nestMappingAddress;

    constructor(address nestMappingAddress) {
        _nestMappingAddress = nestMappingAddress;
    }

    address _addr;
    uint _flag;

    // To facilitate testing, this contract can modify the parameters of contract execution
    // In real voting, in order to ensure the certainty of voting goal, it is not allowed to 
    // modify parameters or transfer parameters to execute
    function setAddress(address addr, uint flag) external {
        _addr = addr;
        _flag = flag;
    }

    /// @dev Methods to be called after approved
    function run() override external {

        address nestGovernanceAddress = _nestMappingAddress;// INestMapping(_nestMappingAddress).getNestGovernanceAddress();

        INestGovernance(nestGovernanceAddress).setGovernance(_addr, _flag);
    }
}