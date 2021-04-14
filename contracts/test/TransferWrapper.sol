// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "../lib/TransferHelper.sol";
import "../lib/IERC20.sol";
import "../interface/IVotePropose.sol";
import "../interface/INestMapping.sol";
import "../interface/INestMining.sol";
import "../interface/INestPriceFacade.sol";

/// @dev 测试通过投票修改价格调用参数配置
contract TransferWrapper {

    function transferETH(address nestMining) external payable {
        TransferHelper.safeTransferETH(nestMining, msg.value);
    }
}