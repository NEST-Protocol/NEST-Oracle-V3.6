// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/// @dev nest挖矿合约
interface INestMining {
    
    /// @dev 参数结构体
    // TODO: State中的部分内容迁移到参数结构体中
    struct Params {
        uint8    miningEthUnit;     // = 10;
        uint32   nestStakedNum1k;   // = 1;
        uint8    biteFeeRate;       // = 1; 
        uint8    miningFeeRate;     // = 10;
        uint8    priceDurationBlock; 
        uint8    maxBiteNestedLevel; // = 3;
        uint8    biteInflateFactor;
        uint8    biteNestInflateFactor;
    }

    // TODO: 状态

    // TODO: 提供组合价格接口

    /* ========== 报价挖矿 ========== */
    /// @notice Post a price sheet for TOKEN
    /// @dev  It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param token The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address token, uint256 ethNum, uint256 tokenAmountPerEth) external payable;

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev  Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param token The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(address token, uint256 ethNum, uint256 tokenAmountPerEth, uint256 ntokenAmountPerEth) external payable;

    // /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    // /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    // /// @param token The address of TOKEN contract
    // /// @param index The index of the price sheet w.r.t. `token`
    // function close(address token, uint256 index) external;

    // /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    // /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    // /// @param token The address of TOKEN contract
    // /// @param indices A list of indices of sheets w.r.t. `token`
    // function closeList(address token, uint32[] memory indices) external; 

    // /// @dev 生成价格
    // /// @param _token 目标token
    // function stat(address _token) external;

    /* ========== 验证吃单 ========== */
    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address token, uint256 index, uint256 biteNum, uint256 newTokenAmountPerEth) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address token, uint256 index, uint256 biteNum, uint256 newTokenAmountPerEth) external payable;
    
    /* ========== 查询价格 ========== */
    // // 查询最新的生效价格
    // /// @notice Get the latest effective price for a token
    // /// @dev It shouldn't be read from any contracts other than NestQuery
    // function latestPriceOf(address token) external view returns(uint256 ethAmount, uint256 tokenAmount, uint256 blockNum);

    // function priceOf(address token) external view returns(uint256 ethAmount, uint256 tokenAmount, uint256 bn);
    // 
    // function priceListOfToken(address token, uint8 num) external view returns(uint128[] memory data, uint256 bn);

    // function priceAvgAndSigmaOf(address token) 
    //     external view returns (uint128, uint128, int128, uint32);

    // function minedNestAmount() external view returns (uint256);

    // /// @dev Only for governance
    // function loadContracts() external; 
    // 
    // function loadGovernance() external;

    // function upgrade() external;

    // function setup(uint32   genesisBlockNumber, uint128  latestMiningHeight, uint128  minedNestTotalAmount, Params calldata initParams) external;

    // function setParams1(uint128  latestMiningHeight, uint128  minedNestTotalAmount) external;
}