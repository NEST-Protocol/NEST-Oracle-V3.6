// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
// pragma experimental ABIEncoderV2;

// import "../lib/TransferHelper.sol";

// library MiningChannel {

//     struct PriceSheetV36 {
//         uint32 miner;
//         uint32 height;
//         uint32 remainNum;
//         uint32 ethNumBal;
//         uint32 tokenNumBal;
//         uint32 nestNum1k;
//         uint8 level;
//         uint8 priceExponent;
//         uint48 priceFraction;
//     }

//     struct PriceInfoV36 {
//         uint32 index;
//         uint32 height;
//         //uint32 ethNum;
//         uint64 tokenAmount;
//         uint32 volatility_sigma_sq;
//         uint32 volatility_ut_sq;
//         uint64 avgTokenAmount;
//     }
    
//     struct MiningShare {
//         uint128 eth;
//         uint128 mined;
//     }

//     struct PriceChannel {
        
//         // 指向报价数据结构当前位置的指针，0~99循环
//         uint index;

//         // 报价单数组
//         PriceSheetV36[100] sheets;

//         // 挖矿信息
//         MiningShare[20] shares;

//         // 价格信息
//         PriceInfoV36 price;
//     }

//     /* ========== 报价挖矿 ========== */
//     /// @notice Post a price sheet for TOKEN
//     /// @dev  It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
//     /// @param channel 报价通道
//     /// @param token The address of TOKEN contract
//     /// @param ethNum The numbers of ethers to post sheets
//     /// @param tokenAmountPerEth The price of TOKEN
//     function post(PriceChannel storage channel, address token, uint256 ethNum, uint256 tokenAmountPerEth) external {

//         // 1. 检查
//         require(ethNum > 0, "NestMining:ethNum is zero");

//         // 2. 转账
//         // 2.1 手续费
        
//         // 2.2 

//         // 3. 生成报价单
//         uint index = channel.index;

//         // 3.1 检查当前位置是否有未关闭的报价单
//         PriceSheetV36 memory sheet = channel.sheets[index];
        
//         // 当前位置有报价单，先给其结算
//         if (sheet.miner > 0) {
            
//             // 报价单数组中还存在未超过验证区块的价格，不允许新报价
//             require(sheet.height + 20 > block.number, "NestMining:out of capacity");

//             // 关闭即将覆盖的报价单
//             address payable miner = address(uint160(indexAddress(sheet.miner)));
            
//             // 转回其eth
//             if (sheet.ethNumBal > 0) {
//                 miner.transfer(sheet.ethNumBal * 1 ether);
//             }

//             // 转回其token
//             if (sheet.tokenNumBal > 0) {
//                 TransferHelper.safeTransfer(token, miner, decodeFloat(sheet.priceFraction, sheet.priceExponent) * sheet.tokenNumBal);
//             }

//             // TODO: 出矿

//             // 清空报价单
//             //channel.sheets[index] = PriceSheetV36(0,0,0,0,0,0,0,0,0);
//         } 

//         // 生成报价单并保存
//         (uint48 fraction, uint8 exponent) = encodeFloat(tokenAmountPerEth);
//         channel.sheets[index] = PriceSheetV36(
//             addressIndex(msg.sender),   // uint32 miner;
//             uint32(block.number),       // uint32 height;
//             uint32(ethNum),             // uint32 remainNum;
//             uint32(ethNum),             // uint32 ethNumBal;
//             uint32(ethNum),             // uint32 tokenNumBal;
//             uint32(100),                // uint32 nestNum1k;
//             uint8(0),                   // uint8 level;
//             exponent,                   // uint8 priceExponent;
//             fraction                    // uint48 priceFraction;
//         );
        
//         if (index < 99) {
//             ++index;
//         } else {
//             index = 0;
//         }

//         channel.index = index;
//     }

//     function encodeFloat(uint value) public pure returns (uint48 fraction, uint8 exponent) {
        
//         uint decimals = 0; 
//         while (value > 0xFFFFFFFFFFFF /* 281474976710655 */) {
//             value >>= 4;
//             ++decimals;
//         }

//         return (uint48(value), uint8(decimals));
//     }

//     function decodeFloat(uint fraction, uint exponent) public pure returns (uint) {

//         while(exponent-- > 0) {
//             fraction <<= 4;
//         }

//         return fraction;
//     }
// }