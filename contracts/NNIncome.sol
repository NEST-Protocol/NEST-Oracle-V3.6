// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NestBase.sol";

contract NNIncome is NestBase {
	using SafeMath for uint256;

	// // 管理员地址
	// address public governance;
	// NEST地址
	address public nestAddress;
	// NN地址
	address public nnAddress;
	// 挖矿起始区块
	uint256 public startBlock = 6236588;
	// 区块衰减
	uint256[10] perBlockAmount;
	// 稳定出矿量
	uint256 perBlockAmountPeace = 6 ether;
	// 已产生NEST
	uint256 public generatedNest;
	// 最近操作区块
	uint256 public latestBlock;
	// struct TotalInfo {
	// 	uint192 generatedNest;
	// 	uint64 latestBlock;
	// }
	// 个人账本
	mapping(address=>uint256) infoMapping;

	constructor() public {
		//governance = msg.sender;
		uint256 amount = 60 ether;
		// 设置区块衰减
        for (uint i =0; i < 10; i++) {
            perBlockAmount[i] = amount;
            amount = amount.mul(80).div(100);
        }
    }

    //---------modifier------------

    // modifier onlyGovernance() {
    //     require(msg.sender == governance, "Log:NNIncome:!gov");
    //     _;
    // }

    modifier onlyNN() {
        require(msg.sender == nnAddress, "Log:NNIncome:!nnAddress");
        _;
    }

    // modifier noContract() {
    //     require(msg.sender == tx.origin, "Log:NNIncome:!contract");
    //     _;
    // }

    //---------view----------------

    // 查询当前可领取Nest
    function nodeCount(address owner) public view returns(uint256) {
    	uint256 totalNest = generatedNest.add(miningNest());
    	IERC20 NN = IERC20(nnAddress);
    	uint256 blnc =  NN.balanceOf(address(owner));
    	return totalNest.sub(infoMapping[owner]).mul(blnc).div(1500);
    }

    //---------governance----------

    function setNestAddress(address add) public onlyGovernance {
    	require(add != address(0x0), "Log:NNIncome:0x0");
    	nestAddress = add;
    }

    function setNNAddress(address add) public onlyGovernance {
    	require(add != address(0x0), "Log:NNIncome:0x0");
    	nnAddress = add;
    }

    //---------transaction---------

    /// @dev NN转账结算，NN转账时触发此方法，必须NN合约调用
    /// @param from 转出地址
    /// @param to 转入地址
    function settlement(address from, address to) public onlyNN {
    	// 检测余额
    	IERC20 NN = IERC20(nnAddress);
    	uint256 blnc_from =  NN.balanceOf(address(from));
        require(blnc_from > 0, "Nest:NNIncome:blnc");
        // 触发挖矿
        uint256 nestAmount = miningNest();
        generatedNest = generatedNest.add(nestAmount);
        // 计算from本次挖矿
        uint256 subAmount_from = generatedNest.sub(infoMapping[address(from)]);
        uint256 thisAmount_from = subAmount_from.mul(blnc_from).div(1500);
        if (thisAmount_from > 0) {
        	require(IERC20(nestAddress).transfer(address(from), thisAmount_from), "Nest:NNIncome:!transfer from");
        }
        infoMapping[address(from)] = generatedNest;
        // 计算to本次挖矿
        uint256 blnc_to =  NN.balanceOf(address(to));
        if (blnc_to > 0) {
        	uint256 subAmount_to = generatedNest.sub(infoMapping[address(to)]);
        	uint256 thisAmount_to = subAmount_to.mul(blnc_to).div(1500);
        	if (thisAmount_to > 0) {
        		require(IERC20(nestAddress).transfer(address(to), thisAmount_to), "Nest:NNIncome:!transfer to");
        	}
        }
        infoMapping[address(to)] = generatedNest;
        // 更新最新操作区块
        latestBlock = block.number;
    }

    // 领取NEST
    function getNest() public noContract {
    	// 检测余额
    	IERC20 NN = IERC20(nnAddress);
    	uint256 blnc =  NN.balanceOf(address(tx.origin));
        require(blnc > 0, "Nest:NNIncome:blnc");
        // 触发挖矿
        uint256 nestAmount = miningNest();
        generatedNest = generatedNest.add(nestAmount);
        // 计算本次挖矿
        uint256 subAmount = generatedNest.sub(infoMapping[address(tx.origin)]);
        uint256 thisAmount = subAmount.mul(blnc).div(1500);
        require(IERC20(nestAddress).transfer(address(tx.origin), thisAmount), "Nest:NNIncome:!transfer");
        infoMapping[address(tx.origin)] = generatedNest;
        // 更新最新操作区块
        latestBlock = block.number;
    }

    // 触发挖矿
    function miningNest() public view returns(uint256) {
    	uint256 period = block.number.sub(startBlock).div(2400000);
        uint256 nestPerBlock;
        if (period > 9) {
            nestPerBlock = perBlockAmountPeace;
        } else {
            nestPerBlock = perBlockAmount[period];
        }
        return nestPerBlock.mul(block.number.sub(latestBlock));
    }
}