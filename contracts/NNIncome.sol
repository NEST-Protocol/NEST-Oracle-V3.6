// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./lib/IERC20.sol";
import "./NestBase.sol";

contract NNIncome is NestBase {

	constructor(address nestNodeAddress, address nestTokenAddress, uint nestGenesisBlock) {
        
        NEST_NODE_ADDRESS = nestNodeAddress;
        NEST_TOKEN_ADDRESS = nestTokenAddress;
        NEST_GENESIS_BLOCK = nestGenesisBlock;

        uint full = 400 ether * 15 / 100;
        for (uint i = 0; i < 10; ++i) {
            _nestReductionSteps[i] = full;
            full = full * 8 / 10;
        }
    }

    // NN发行总量
    uint constant NEST_NODE_TOTALSUPPLY = 1500;

    // NEST出矿衰减间隔。2400000区块，约一年
    uint constant NEST_REDUCTION_SPAN = 2400000;

    // 衰减梯度数
    uint constant NEST_REDUCTION_STEP_COUNT = 10;

    // NEST NODE地址
	address immutable NEST_NODE_ADDRESS;

	// NEST地址
	address immutable NEST_TOKEN_ADDRESS;

	// 挖矿起始区块
	uint immutable NEST_GENESIS_BLOCK;// = 6236588;	

    // NN地址
	//address public _nestNodeAddress;
	
    // 衰减梯度数组
    uint[NEST_REDUCTION_STEP_COUNT] _nestReductionSteps;
	
    // 稳定出矿量
    uint _nestStableMiningSpeed = 6 ether;

    // 已产生NEST
	uint public _generatedNest;
	
    // 最近操作区块
	uint public _latestBlock;

	// 个人账本
	mapping(address=>uint) _infoMapping;

    //---------governance----------

    // /// @dev 设置NestNode合约地址
    // /// @param nestNodeAddress NestNode合约地址
    // function setNestNodeAddress(address nestNodeAddress) external onlyGovernance {
    // 	//require(add != address(0x0), "Log:NNIncome:0x0");
    // 	_nestNodeAddress = nestNodeAddress;
    // }

    /// @dev 设置出矿衰减参数
    /// @param nestStableMiningSpeed 稳定出矿量
    /// @param nestReductionSteps 衰减梯度数组（长度：10）
    function setReduction(
        uint nestStableMiningSpeed,
        uint[NEST_REDUCTION_STEP_COUNT] memory nestReductionSteps
    ) external onlyGovernance {
        _nestReductionSteps = nestReductionSteps;
        _nestStableMiningSpeed = nestStableMiningSpeed;
    }

    //---------transaction---------

    /// @dev NN转账结算，NN转账时触发此方法，必须NN合约调用
    /// @param from 转出地址
    /// @param to 转入地址
    function nodeCount(address from, address to) public  {
        settlement(from, to);
    }

    /// @dev NN转账结算，NN转账时触发此方法，必须NN合约调用
    /// @param from 转出地址
    /// @param to 转入地址
    function settlement(address from, address to) public {

        require(msg.sender == NEST_NODE_ADDRESS, "NNIncome:!nestNode");
    	
        // 检测余额
    	IERC20 nn = IERC20(NEST_NODE_ADDRESS);
    	uint balanceFrom = nn.balanceOf(address(from));
        require(balanceFrom > 0, "NNIncome:!balance");

        // 计算出矿增量
        uint nestAmount = miningNest();
        uint generatedNest = _generatedNest = _generatedNest + nestAmount;

        mapping(address=>uint) storage infoMapping = _infoMapping;
        // 计算from本次挖矿
        uint subAmountFrom = generatedNest - infoMapping[address(from)];
        uint thisAmountFrom = subAmountFrom * balanceFrom / NEST_NODE_TOTALSUPPLY;

        if (thisAmountFrom > 0) {
        	require(IERC20(NEST_TOKEN_ADDRESS).transfer(address(from), thisAmountFrom), "NNIncome:!transfer from");
        }
        infoMapping[address(from)] = generatedNest;

        // 计算to本次挖矿
        uint balanceTo = nn.balanceOf(address(to));
        if (balanceTo > 0) {
        	uint subAmountTo = generatedNest - infoMapping[address(to)];
        	uint thisAmountTo = subAmountTo * balanceTo / NEST_NODE_TOTALSUPPLY;
        	if (thisAmountTo > 0) {
        		require(IERC20(NEST_TOKEN_ADDRESS).transfer(address(to), thisAmountTo), "NNIncome:!transfer to");
        	}
        }
        infoMapping[address(to)] = generatedNest;

        // 更新最新操作区块
        _latestBlock = block.number;
    }

    /// @dev 领取nest
    function claimNest() public noContract {
    	
        // 检测余额
    	IERC20 nn = IERC20(NEST_NODE_ADDRESS);
    	uint balance = nn.balanceOf(address(tx.origin));
        require(balance > 0, "NNIncome:!balance");

        // 触发挖矿
        uint nestAmount = miningNest();
        _generatedNest = _generatedNest + nestAmount;

        // 计算本次挖矿
        uint subAmount = _generatedNest - _infoMapping[address(tx.origin)];
        uint thisAmount = subAmount * balance / NEST_NODE_TOTALSUPPLY;

        require(IERC20(NEST_TOKEN_ADDRESS).transfer(address(tx.origin), thisAmount), "NNIncome:!transfer");
        _infoMapping[address(tx.origin)] = _generatedNest;
        // 更新最新操作区块
        _latestBlock = block.number;
    }

    //---------view----------------

    /// @dev 计算出矿增量
    /// @return 出矿增量
    function miningNest() public view returns(uint) {
    	
        uint period = (block.number - NEST_GENESIS_BLOCK) / NEST_REDUCTION_SPAN;
        uint nestPerBlock;
        if (period < NEST_REDUCTION_STEP_COUNT) {
            nestPerBlock = _nestReductionSteps[period];
        } else {
            nestPerBlock = _nestStableMiningSpeed;
        }
        return nestPerBlock * (block.number - _latestBlock);
    }

    /// @dev 查询当前可领取Nest
    /// @param owner 目标地址
    /// @param 当前可领取的nest数量
    function earnedNest(address owner) public view returns(uint) {

    	uint totalNest = _generatedNest + miningNest();
    	uint balance = IERC20(NEST_NODE_ADDRESS).balanceOf(address(owner));
    	return (totalNest - _infoMapping[owner]) * balance / NEST_NODE_TOTALSUPPLY;
    }
}