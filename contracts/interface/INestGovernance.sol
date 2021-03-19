// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./INestMapping.sol";

/// @dev 
interface INestGovernance is INestMapping {

    /// @dev 设置治理权限
    /// @param addr 目标地址
    /// @param flag 权重。为0表示删除目标地址的治理权限。权重当前系统并没有实现，只有有权限和无权限的区别，此处用一个uint96来表示权重，只是留作扩展用
    function setGovernance(address addr, uint flag) external;

    /// @dev 获取治理权限
    /// @param addr 目标地址
    /// @return 权重。为0表示删除目标地址的治理权限。权重当前系统并没有实现，只有有权限和无权限的区别，此处用一个uint96来表示权重，只是留作扩展用
    function getGovernance(address addr) external view returns (uint);

    /// @dev 检查目标地址是否具备对给定目标的治理权限
    /// @param 目标地址
    /// @param 权限权重，目标地址的权限需要大于此权重才能通过检查
    /// @return true表示有权限
    function checkGovernance(address addr, uint flag) external view returns (bool);
}