// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/TransferHelper.sol";
import "./interface/INestGovernance.sol";

/// @dev NEST合约基类
contract NestBase {

    constructor() {

        // 临时存储，用于限制只允许创建者设置治理合约地址
        // 治理合约地址设置后，_governance将真正的表示合约地址
        _governance = msg.sender;
    }

    /// @dev 治理合约地址
	address public _governance;

    // function initialize(address nestDaoAddress) external {
    //     require(msg.sender == dao, "NEST:!creater");
    //     dao = nestDaoAddress;
    // }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) virtual public {

        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0));
        _governance = nestGovernanceAddress;
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

    // function setGovernance(address gov) public onlyGovernance {
    //     governance = gov;
    // }

    /// @dev 将当前合约的资金转走
    /// @param tokenAddress 目标token地址（0表示eth）
    /// @param to 转入地址
    /// @param value 转账金额
    function transfer(address tokenAddress, address to, uint value) external onlyGovernance {
        if (tokenAddress == address(0)) {
            //address(uint160(to)).transfer(value);
            payable(to).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    // /// @dev 获取DAO合约地址
    // /// @return DAO合约地址
    // function getDaoAddress() public view returns (address) {
    //     return _DAO;
    // }
}