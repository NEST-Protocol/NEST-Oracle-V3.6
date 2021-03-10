// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "./lib/SafeMath.sol";
import "./lib/IERC20.sol";
import './lib/TransferHelper.sol';
import "./interface/INTokenController.sol";
import "./interface/INToken.sol";
import "./NToken.sol";
import "./NestBase.sol";

/// @title NTokenController
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

/// @dev NToken控制器
contract NTokenController is NestBase, INTokenController {

    constructor(address nestTokenAddress)
    {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    Config _config;

    /// @dev ntoken->token映射
    mapping(address=>address) _tokenMapping;

    /// @dev token->ntoken映射
    mapping(address=>address) _ntokenMapping;

    /// @dev A mapping for all auctions
    ///     token(address) => NTokenTag
    mapping(address => NTokenTag) public _nTokenTagList;

    /* ========== ADDRESSES ============== */
    
    /// @dev A number counter for generating ntoken name
    uint public _ntokenCounter;

    /// @dev Contract address of NestToken
    address public _nestMiningAddress;
    
    address immutable NEST_TOKEN_ADDRESS;
    
    /* ========== 治理相关 ========== */

    /// @dev 设置ntokenCounter
    /// @param ntokenCounter 当前已经创建的ntoken数量
    function setNTokenCounter(uint ntokenCounter) override external onlyGovernance {
        _ntokenCounter = ntokenCounter;
    }

    /// @dev 修改配置。
    /// @param config 配置对象
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev 获取配置
    /// @return 配置对象
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);
        _nestMiningAddress = INestGovernance(nestGovernanceAddress).getNestMiningAddress();
    }

    /// @dev 添加ntoken映射
    /// @param tokenAddress token地址
    /// @param ntokenAddress ntoken地址
    function addNTokenMapping(address tokenAddress, address ntokenAddress) override external onlyGovernance {
        _ntokenMapping[tokenAddress] = _ntokenMapping[ntokenAddress] = ntokenAddress;
        _tokenMapping[ntokenAddress] = tokenAddress;
    }

    /// @dev 获取ntoken对应的token地址
    /// @param ntokenAddress ntoken地址
    /// @return token地址
    function getTokenAddress(address ntokenAddress) override public view returns (address) {
        return _tokenMapping[ntokenAddress];
    }

    /// @dev 获取token对应的ntoken地址
    /// @param tokenAddress token地址
    /// @return ntoken地址
    function getNTokenAddress(address tokenAddress) override public view returns (address) {
        return _ntokenMapping[tokenAddress];
    }

    /* ========== OPEN ========== */
    
    /// @dev Bad tokens should be banned 
    function disable(address tokenAddress) override external onlyGovernance
    {
        NTokenTag storage _to = _nTokenTagList[tokenAddress];
        _to.state = 0;
        emit NTokenDisabled(tokenAddress);
    }

    /// @dev 启用ntoken
    function enable(address tokenAddress) override external onlyGovernance
    {
        NTokenTag storage _to = _nTokenTagList[tokenAddress];
        _to.state = 1;
        emit NTokenEnabled(tokenAddress);
    }

    /// @notice Open a NToken for a token by anyone (contracts aren't allowed)
    /// @dev Create and map the (Token, NToken) pair in NestPool
    /// @param tokenAddress  The address of token contract
    function open(address tokenAddress) override external noContract
    {
        Config memory config = _config;
        require(config.state == 1, "NTokenController:!state");

        // token必须没有对应的nToken
        //require(getNTokenAddress(tokenAddress) == address(0), "NTokenController:!exists");

        // token的标记为0
        require(_nTokenTagList[tokenAddress].state == 0, "NTokenController:!active");

        _nTokenTagList[tokenAddress] = NTokenTag(
            address(msg.sender),                                // owner
            uint128(0),                                         // nestFee
            uint64(block.timestamp),                            // startTime
            // 3.5的代码中定义的状态存在问题，因为state默认值为0
            1,                                                  // state
            0                                                   // _reserved
        );
        
        uint ntokenCounter = _ntokenCounter;

        // 创建nToken代币合约
        // create ntoken
        NToken ntoken = new NToken(strConcat("NToken",
                getAddressStr(ntokenCounter)),
                strConcat("N", getAddressStr(ntokenCounter))
        );

        address governance = _governance;
        ntoken.update(governance);

        // 计数
        // increase the counter
        _ntokenCounter = ntokenCounter + 1;  // safe math
        _ntokenMapping[tokenAddress] = _ntokenMapping[address(ntoken)] = address(ntoken);
        _tokenMapping[address(ntoken)] = tokenAddress;

        // is token valid ?
        IERC20 tokenERC20 = IERC20(tokenAddress);
        TransferHelper.safeTransferFrom(tokenAddress, address(msg.sender), address(this), 1);
        require(tokenERC20.balanceOf(address(this)) >= 1, "NTokenController:!transfer");
        TransferHelper.safeTransfer(tokenAddress, address(msg.sender), 1);

        // 支付nest
        // charge nest
        IERC20(NEST_TOKEN_ADDRESS).transferFrom(address(msg.sender), address(governance), uint(config.openFeeNestAmount));

        // raise an event
        emit NTokenOpened(tokenAddress, address(ntoken), address(msg.sender));
    }

    /* ========== VIEWS ========== */

    function getNTokenTag(address token) override public view returns (NTokenTag memory) 
    {
        return _nTokenTagList[token];
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