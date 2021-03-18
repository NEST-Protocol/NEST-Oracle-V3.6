// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

library NumberHelper {

    /* ========== 工具方法 ========== */

    /// @dev 将uint值编码成fraction * 16 ^ exponent形式的浮点表示形式
    /// @param value 目标uint值
    /// @return fraction 分数值
    /// @return exponent 指数值
    function encodeFloat(uint value) public pure returns (uint48 fraction, uint8 exponent) {
        
        uint decimals = 0; 
        while (value > 0xFFFFFFFFFFFF /* 281474976710655 */) {
            value >>= 4;
            ++decimals;
        }

        return (uint48(value), uint8(decimals));
    }

    /// @dev 将fraction * 16 ^ exponent形式的浮点表示形式解码成uint
    /// @param fraction 分数值
    /// @param exponent 指数值
    function decodeFloat(uint fraction, uint exponent) public pure returns (uint) {
        return fraction << (exponent << 2);
    }
}