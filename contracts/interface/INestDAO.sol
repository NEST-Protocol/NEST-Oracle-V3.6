// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INestDAO {

    function addETHReward(address ntoken) external payable; 

    function addNestReward(uint256 amount) external;

    // /// @dev Only for governance
    // function loadContracts() external; 

    // /// @dev Only for governance
    // function loadGovernance() external;
    
    // /// @dev Only for governance
    // function start() external; 

    // function initEthLedger(address ntoken, uint256 amount) external;

    // event NTokenRedeemed(address ntoken, address user, uint256 amount);

    // event AssetsCollected(address user, uint256 ethAmount, uint256 nestAmount);

    // event ParamsSetup(address gov, uint256 oldParam, uint256 newParam);

    // event FlagSet(address gov, uint256 flag);

}