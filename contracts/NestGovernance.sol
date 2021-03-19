// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./interface/INestGovernance.sol";
import "./NestMapping.sol";

/// @dev 
contract NestGovernance is NestMapping, INestGovernance {

    constructor() {
        _governance = address(this);
        governanceMapping[msg.sender] = GovernanceInfo(msg.sender, uint96(0xFFFFFFFFFFFFFFFFFFFFFFFF));
    }

    /// @dev 治理地址信息
    struct GovernanceInfo {
        address addr;
        uint96 flag;
    }

    /// @dev 治理地址信息
    mapping(address=>GovernanceInfo) governanceMapping;

    /// @dev 设置治理权限
    /// @param addr 目标地址
    /// @param flag 权重。为0表示删除目标地址的治理权限。权重当前系统并没有实现，只有有权限和无权限的区别，此处用一个uint96来表示权重，只是留作扩展用
    function setGovernance(address addr, uint flag) override external onlyGovernance {
        
        if (flag > 0) {
            governanceMapping[addr] = GovernanceInfo(addr, uint96(flag));
        } else {
            governanceMapping[addr] = GovernanceInfo(address(0), uint96(0));
        }
    }

    /// @dev 获取治理权限
    /// @param addr 目标地址
    /// @return 权重。为0表示删除目标地址的治理权限。权重当前系统并没有实现，只有有权限和无权限的区别，此处用一个uint96来表示权重，只是留作扩展用
    function getGovernance(address addr) override external view returns (uint) {
        return governanceMapping[addr].flag;
    }

    /// @dev 检查目标地址是否具备对给定目标的治理权限
    /// @param 目标地址
    /// @param 权限权重，目标地址的权限需要大于此权重才能通过检查
    /// @return true表示有权限
    function checkGovernance(address addr, uint flag) override external view returns (bool) {
        return governanceMapping[addr].flag > flag;
    }
}