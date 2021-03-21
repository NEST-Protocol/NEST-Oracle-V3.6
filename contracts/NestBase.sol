// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/TransferHelper.sol";
import "./interface/INestGovernance.sol";

/// @dev Base contract of nest
contract NestBase {

    constructor() {

        // Temporary storage, used to restrict only the creator to set the governance contract address
        // After setting the address of the governance contract _governance will really represent the contract address
        _governance = msg.sender;
    }

    /// @dev INestGovernance implemention contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implemention contract address
    function update(address nestGovernanceAddress) virtual public {

        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0));
        _governance = nestGovernanceAddress;
    }

    /// @dev Transfer funds from current contracts
    /// @param tokenAddress Destination token address.（0 means eth）
    /// @param to Transfer in address
    /// @param value Transfer amount
    function transfer(address tokenAddress, address to, uint value) external onlyGovernance {
        if (tokenAddress == address(0)) {
            //address(uint160(to)).transfer(value);
            payable(to).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(INestGovernance(_governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "NEST:!contract");
        _;
    }
}