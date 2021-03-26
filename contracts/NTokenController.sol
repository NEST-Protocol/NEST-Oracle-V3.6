// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/IERC20.sol";
import './lib/TransferHelper.sol';
import "./interface/INTokenController.sol";
import "./interface/INToken.sol";
import "./NToken.sol";
import "./NestBase.sol";

/// @dev NToken Controller, management for ntoken
contract NTokenController is NestBase, INTokenController {

    constructor(address nestTokenAddress)
    {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    Config _config;
    NTokenTag[] _nTokenTagList;

    /// @dev A mapping for all ntoken
    mapping(address=>uint) public _nTokenTags;

    address immutable NEST_TOKEN_ADDRESS;
    
    /* ========== Governance ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /// @dev Set the token mapping
    /// @param tokenAddress Destination token address
    /// @param ntokenAddress Destination ntoken address
    /// @param state status for this map
    function setNTokenMapping(address tokenAddress, address ntokenAddress, uint state) override external onlyGovernance {
        
        uint index = _nTokenTags[tokenAddress];
        if (index == 0) {
            _nTokenTagList.push(NTokenTag(
                // address ntokenAddress;
                ntokenAddress,
                // uint96 nestFee;
                uint96(0),
                // address tokenAddress;
                tokenAddress,
                // uint40 index;
                uint40(_nTokenTagList.length),
                // uint48 startTime;
                uint48(block.timestamp),
                // uint8 state;  
                uint8(state)
            ));
            _nTokenTags[tokenAddress] = _nTokenTags[ntokenAddress] = _nTokenTagList.length;
        } else {
            NTokenTag memory tag = _nTokenTagList[index - 1];
            tag.ntokenAddress = ntokenAddress;
            tag.tokenAddress = tokenAddress;
            tag.index = uint40(index - 1);
            tag.startTime = uint48(block.timestamp);
            tag.state = uint8(state);

            _nTokenTagList[index - 1] = tag;
        }
    }

    /// @dev Get token address from ntoken address
    /// @param ntokenAddress Destination ntoken address
    /// @return token address
    function getTokenAddress(address ntokenAddress) override external view returns (address) {

        uint index = _nTokenTags[ntokenAddress];
        if (index > 0) {
            return _nTokenTagList[index - 1].tokenAddress;
        }
        return address(0);
    }

    /// @dev Get ntoken address from token address
    /// @param tokenAddress Destination token address
    /// @return ntoken address
    function getNTokenAddress(address tokenAddress) override public view returns (address) {

        uint index = _nTokenTags[tokenAddress];
        if (index > 0) {
            return _nTokenTagList[index - 1].ntokenAddress;
        }
        return address(0);
    }

    /* ========== ntoken management ========== */
    
    /// @dev Bad tokens should be banned 
    function disable(address tokenAddress) override external onlyGovernance
    {
        // When tokenAddress does not exist, _nTokenTags[tokenAddress] - 1 will overflow error
        _nTokenTagList[_nTokenTags[tokenAddress] - 1].state = 0;
        emit NTokenDisabled(tokenAddress);
    }

    /// @dev enable ntoken
    function enable(address tokenAddress) override external onlyGovernance
    {
        // When tokenAddress does not exist, _nTokenTags[tokenAddress] - 1 will overflow error
        _nTokenTagList[_nTokenTags[tokenAddress] - 1].state = 1;
        emit NTokenEnabled(tokenAddress);
    }

    /// @notice Open a NToken for a token by anyone (contracts aren't allowed)
    /// @dev Create and map the (Token, NToken) pair in NestPool
    /// @param tokenAddress The address of token contract
    function open(address tokenAddress) override external noContract
    {
        Config memory config = _config;
        require(config.state == 1, "NTokenController:!state");

        // Check token mapping
        require(getNTokenAddress(tokenAddress) == address(0), "NTokenController:!exists");

        // Check token state
        uint index = _nTokenTags[tokenAddress];
        require(index == 0 || _nTokenTagList[index - 1].state == 0, "NTokenController:!active");

        uint ntokenCounter = _nTokenTagList.length;

        // Create ntoken contract
        NToken ntoken = new NToken(strConcat("NToken",
            getAddressStr(ntokenCounter)),
            strConcat("N", getAddressStr(ntokenCounter))
        );

        address governance = _governance;
        ntoken.update(governance);

        // is token valid ?
        IERC20 tokenERC20 = IERC20(tokenAddress);
        TransferHelper.safeTransferFrom(tokenAddress, address(msg.sender), address(this), 1);
        require(tokenERC20.balanceOf(address(this)) >= 1, "NTokenController:!transfer");
        TransferHelper.safeTransfer(tokenAddress, address(msg.sender), 1);

        // Pay nest
        IERC20(NEST_TOKEN_ADDRESS).transferFrom(address(msg.sender), address(governance), uint(config.openFeeNestAmount));

        // TODO: Consider how to migrate the existing token information
        _nTokenTags[tokenAddress] = _nTokenTags[address(ntoken)] = ntokenCounter + 1;
        _nTokenTagList.push(NTokenTag(
            // address ntokenAddress;
            address(ntoken),
            // uint96 nestFee;
            config.openFeeNestAmount,
            // address tokenAddress;
            tokenAddress,
            // uint40 index;
            uint40(_nTokenTagList.length),
            // uint48 startTime;
            uint48(block.timestamp),
            // uint8 state;  
            1
        ));

        emit NTokenOpened(tokenAddress, address(ntoken), address(msg.sender));
    }

    /* ========== VIEWS ========== */

    /// @dev Get ntoken information
    /// @param tokenAddress Destination token address
    /// @return ntoken information
    function getNTokenTag(address tokenAddress) override external view returns (NTokenTag memory) 
    {
        return _nTokenTagList[_nTokenTags[tokenAddress]];
    }

    /// @dev Get opened ntoken count
    /// @return ntoken count
    function getNTokenCount() override external view returns (uint) {
        return _nTokenTagList.length;
    }

    /// @dev List ntoken information by page
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return ntoken information by page
    function list(uint offset, uint count, uint order) override external view returns (NTokenTag[] memory) {
        
        NTokenTag[] storage nTokenTagList = _nTokenTagList;
        NTokenTag[] memory result = new NTokenTag[](count);
        uint i = 0;

        // 倒序
        if (order == 0) {

            uint index = nTokenTagList.length - offset;
            uint end = index - count;
            while (index > end) {
                result[i++] = nTokenTagList[--index];
            }
        } 
        // 正序
        else {
            
            uint index = offset;
            uint end = index + count;
            while (index < end) {
                result[i++] = nTokenTagList[index++];
            }
        }

        return result;
    }

    /* ========== HELPERS ========== */

    /// @dev from NESTv3.0
    function strConcat(string memory _a, string memory _b) public pure returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bret[k++] = _ba[i];
        } 
        for (uint i = 0; i < _bb.length; i++) {
            bret[k++] = _bb[i];
        } 
        return string(ret);
    } 
    
    /// @dev Convert a 4-digital number into a string, from NestV3.0
    function getAddressStr(uint256 iv) public pure returns (string memory) 
    {
        bytes memory buf = new bytes(64);
        uint256 index = 0;
        do {
            buf[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        } while (iv > 0 || index < 4);
        bytes memory str = new bytes(index);
        for(uint256 i = 0; i < index; ++i) {
            str[i] = buf[index - i - 1];
        }
        return string(str);
    }
}