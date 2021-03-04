// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/TransferHelper.sol";
import "./interface/INestDAO.sol";

/// @dev NEST合约基类
contract NestBase {

	address public dao;

    constructor() public {

        // 临时存储，用于限制只允许创建者设置DAO合约地址
        // DAO合约地址设置后，dao将真正的表示合约地址
        dao = msg.sender;
    }

    function initialize(address nestDaoAddress) external {
        require(msg.sender == dao, "NEST:only for creater");
        dao = nestDaoAddress;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址
    /// @param nestDaoAddress dao合约地址
    function update(address nestDaoAddress) virtual external onlyGovernance {
        dao = nestDaoAddress;
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(INestDAO(dao).checkGovernance(msg.sender, 0), "NEST:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "NEST:!contract");
        _;
    }

    // function setGovernance(address gov) public onlyGovernance {
    //     governance = gov;
    // }

    /// @dev 将当前合约的资金转走
    /// @param tokenAddress 目标token地址（0表示eth）
    /// @param to 转入地址
    /// @param value 转账金额
    function transfer(address tokenAddress, address to, uint value) onlyGovernance external {
        if (tokenAddress == address(0)) {
            address(uint160(to)).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }
}