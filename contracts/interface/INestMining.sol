// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev This interface defined the mining method of nest.
interface INestMining {
    
    /// @dev Post event
    /// @param tokenAddress The address of TOKEN contract
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param ethNum The numbers of ethers to post sheets
    event Post(address tokenAddress, address miner, uint index, uint ethNum, uint price);

    /* ========== Structures ========== */
    
    /// @dev Nest mining configuration structure
    struct Config {
        
        // Eth unit of each post. 30
        // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
        uint32 postEthUnit;

        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFee;

        // Proportion of miners digging(10000 based). 8000
        uint16 minerNestReward;
        
        // The proportion of token dug by miners is only valid for the token created in version 3.0
        // (10000 based). 9500
        uint16 minerNTokenReward;

        // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
        uint32 doublePostThreshold;
        
        // The limit of ntoken mined blocks. 100
        uint16 ntokenMinedBlockLimit;

        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        uint16 maxBiteNestedLevel;
        
        // Price effective block interval. 20
        uint16 priceEffectSpan;

        // The amount of nest to pledge for each post（Unit: 1000). 100
        uint16 pledgeNest;
    }

    /// @dev 报价单视图
    struct PriceSheetView {
        
        // Index of the price sheeet
        uint32 index;

        // Address of miner
        address miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // The eth number which miner will got
        uint32 ethNumBal;

        // The eth number which equivalent to token's value which miner will got
        uint32 tokenNumBal;

        // The pledged number of nest in this sheet. (unit: 1000nest)
        uint32 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // The token price. (1eth equivalent to (price) token)
        uint128 price;
    }

    /* ========== Configuration ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /* ========== Mining ========== */

    /// @notice Post a price sheet for TOKEN
    /// @dev It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address tokenAddress, uint ethNum, uint tokenAmountPerEth) external payable;

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(address tokenAddress, uint ethNum, uint tokenAmountPerEth, uint ntokenAmountPerEth) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) external payable;

    /// @notice Call the function to buy ETH from a posted price sheet
    /// @dev bite ETH by TOKEN(NTOKEN),  (-ethNumBal, +tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address tokenAddress, uint index, uint biteNum, uint newTokenAmountPerEth) external payable;
    
    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param tokenAddress The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address tokenAddress, uint index) external;

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint32[] memory indices) external;

    /// @notice Close two batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress1 The address of TOKEN1 contract
    /// @param indices1 A list of indices of sheets w.r.t. `token1`
    /// @param tokenAddress2 The address of TOKEN2 contract
    /// @param indices2 A list of indices of sheets w.r.t. `token2`
    function closeList2(address tokenAddress1, uint32[] memory indices1, address tokenAddress2, uint32[] memory indices2) external;

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function stat(address tokenAddress) external;

    /// @dev Settlement Commission
    /// @param tokenAddress The token address
    function settle(address tokenAddress) external;

    /// @dev List sheets by page
    /// @param tokenAddress Destination token address
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(address tokenAddress, uint offset, uint count, uint order) external view returns (PriceSheetView[] memory);

    /// @dev Estimated ore yield
    /// @param tokenAddress Destination token address
    /// @return Estimated ore yield
    function estimate(address tokenAddress) external view returns (uint);

    /// @dev Query the quantity of the target quotation
    /// @param tokenAddress Token address. The token can't mine. Please make sure you don't use the token address when calling
    /// @param index The index of the sheet
    function getMinedBlocks(address tokenAddress, uint index) external view returns (uint minedBlocks, uint count);

    /* ========== Accounts ========== */

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    /// @return Actually withdrawn
    function withdraw(address tokenAddress, uint value) external returns (uint);

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view returns (uint);

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) external view returns (address);
    
    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) external view returns (uint);

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view returns (uint);
}