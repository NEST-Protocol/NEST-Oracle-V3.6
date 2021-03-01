// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INestDAO {

    /// @dev 添加ntoken映射
    /// @param tokenAddress token地址
    /// @param ntokenAddress ntoken地址
    function addNTokenMapping(address tokenAddress, address ntokenAddress) external;

    /// @dev 获取token对应的ntoken地址
    /// @param tokenAddress token地址
    /// @return ntoken地址
    function getNToken(address tokenAddress) external view returns (address);

    /// @dev 添加ntoken收益
    /// @param ntokenAddress ntoken地址
    function addReward(address ntokenAddress) external payable;

    /// @dev Redeem ntokens for ethers
    /// @notice Ethfee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount  The amount of ntoken
    function redeem(address ntokenAddress, uint amount) external payable;

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The notoken address
    function totalRewards(address ntokenAddress) external view returns (uint);

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) external view returns (uint quota);

    //function addETHReward(address ntoken) external payable; 

    //function addNestReward(uint amount) external;

    // /// @dev nest收益
    // function nestReward() external payable;

    // /// @dev Only for governance
    // function loadContracts() external; 

    // /// @dev Only for governance
    // function loadGovernance() external;
    
    // /// @dev Only for governance
    // function start() external; 

    // function initEthLedger(address ntoken, uint amount) external;

    // event NTokenRedeemed(address ntoken, address user, uint amount);

    // event AssetsCollected(address user, uint ethAmount, uint nestAmount);

    // event ParamsSetup(address gov, uint oldParam, uint newParam);

    // event FlagSet(address gov, uint flag);

}