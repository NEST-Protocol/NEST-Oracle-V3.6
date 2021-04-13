// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "../interface/IVotePropose.sol";
import "../interface/INestMapping.sol";
import "../interface/INestGovernance.sol";

// 通过投票添加和删除管理员
contract UpdateAdmin is IVotePropose {

    address _nestMappingAddress;

    constructor(address nestMappingAddress) {
        _nestMappingAddress = nestMappingAddress;
    }

    address _addr;
    uint _flag;

    // 为了方便测试，这个合约可以修改合约执行的参数
    // 现实的投票，为了保证投票的目标的确定性，是不应该允许修改参数，或者传参数来执行的
    function setAddress(address addr, uint flag) external {
        _addr = addr;
        _flag = flag;
    }

    /// @dev 投票通过后需要执行的代码
    function run() override external {

        address nestGovernanceAddress = _nestMappingAddress;// INestMapping(_nestMappingAddress).getNestGovernanceAddress();

        INestGovernance(nestGovernanceAddress).setGovernance(_addr, _flag);
    }
}