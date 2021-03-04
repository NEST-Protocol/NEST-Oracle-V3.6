// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INestDAO {

    /// @dev 获取系统内置的合约地址
    /// @param nestMiningAddress 挖矿合约地址
    /// @param nestPriceFacadeAddress 价格调用入口合约地址
    /// @param nestVoteAddress 投票合约地址
    /// @param nestQueryAddress 提供价格的合约地址
    /// @param nnIncomeAddress NN挖矿合约
    /// @param nTokenControllerAddress nToken管理合约地址
    function setBuiltinAddress(
        address nestMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) external;

    /// @dev 获取系统内置的合约地址
    /// @return nestMiningAddress 挖矿合约地址
    /// @return nestPriceFacadeAddress 价格调用入口合约地址
    /// @return nestVoteAddress 投票合约地址
    /// @return nestQueryAddress 提供价格的合约地址
    /// @return nnIncomeAddress NN挖矿合约
    /// @return nTokenControllerAddress nToken管理合约地址
    function getBuiltinAddress() external view returns (
        address nestMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    );

    /// @dev 获取挖矿合约地址
    /// @return 挖矿合约地址
    function getNestMiningAddress() external view returns (address);

    /// @dev 获取价格调用入口合约地址
    /// @return 价格调用入口合约地址
    function getNestPriceFacadeAddress() external view returns (address);

    /// @dev 获取投票合约地址
    /// @return 投票合约地址
    function getNestVoteAddress() external view returns (address);

    /// @dev 获取提供价格的合约地址
    /// @return 提供价格的合约地址
    function getNestQueryAddress() external view returns (address);

    /// @dev 获取NN挖矿合约
    /// @return NN挖矿合约
    function getNnIncomeAddress() external view returns (address);

    /// @dev 获取nToken管理合约地址
    /// @return nToken管理合约地址
    function getNTokenControllerAddress() external view returns (address);

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

    /// @dev 检查目标地址是否具备对给定目标的治理权限
    /// @param 目标地址
    /// @param 治理目标
    /// @return true表示有权限
    function checkGovernance(address addr, uint flag) external view returns (bool);
}