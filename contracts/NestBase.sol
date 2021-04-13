// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "./lib/TransferHelper.sol";
import "./interface/INestGovernance.sol";
import "./interface/INestLedger.sol";

/// @dev Base contract of nest
contract NestBase {

    // TODO: Change to 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // Address of nest token contract
    address constant NEST_TOKEN_ADDRESS = 0x1d1f9E2789b22818425ede5d3889745fe516D5bB;// 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

    // TODO: Change to 6236588
    // Genesis block number of nest
    uint constant NEST_GENESIS_BLOCK = 0; // 6236588;

    // // To support open-zeppelin/upgrades, leave it blank
    // constructor() {

    //     // Temporary storage, used to restrict only the creator to set the governance contract address
    //     // After setting the address of the governance contract _governance will really represent the contract address
    //     //_governance = msg.sender;
    // }

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    // TODO: This method is for testing, it should be deleted for mainnet
    /**
    * @return adm The admin slot.
    */
    function getAdmin() external view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    /// @dev To support open-zeppelin/upgrades
    /// @param nestGovernanceAddress INestGovernance implemention contract address
    function initialize(address nestGovernanceAddress) virtual public {
        require(_governance == address(0), 'NEST:!initialize');
        _governance = nestGovernanceAddress;
    }

    /// @dev INestGovernance implemention contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implemention contract address
    function update(address nestGovernanceAddress) virtual public {
        require(INestGovernance(_governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _governance = nestGovernanceAddress;
    }

    /// @dev Migrate funds from current contract to NestLedger
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = INestGovernance(_governance).getNestLedgerAddress();
        if (tokenAddress == address(0)) {
            INestLedger(to).addReward { value: value } (address(0));
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