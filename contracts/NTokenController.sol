// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/SafeMath.sol";
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

    /* ========== STATE VARIABLES ============== */

    /// @dev A number counter for generating ntoken name
    uint32  public ntokenCounter;

    // 0: uninitialized 
    // 1: active (and initialized)
    // 2: paused
    uint8   public flag;
    uint8   constant NTCTRL_FLAG_UNINITIALIZED    = 0;
    uint8   constant NTCTRL_FLAG_ACTIVE           = 1;
    uint8   constant NTCTRL_FLAG_PAUSED           = 2;

    /// @dev A mapping for all auctions
    ///     token(address) => NTokenTag
    mapping(address => NTokenTag) public nTokenTagList;

    /* ========== PARAMETERS ============== */

    uint256 public openFeeNestAmount = 10000 ether; // default = 10000

    /* ========== ADDRESSES ============== */

    /// @dev Contract address of NestToken
    address immutable NEST_TOKEN_ADDRESS;
    address public nestMining;

    /* ========== EVENTS ============== */

    /// @notice when the auction of a token gets started
    /// @param token    The address of the (ERC20) token
    /// @param ntoken   The address of the ntoken w.r.t. token for incentives
    /// @param owner    The address of miner who opened the oracle
    event NTokenOpened(address token, address ntoken, address owner);

    event NTokenDisabled(address token);
    
    event NTokenEnabled(address token);

    mapping(address=>address) ntokenMapping;

    /// @dev 添加ntoken映射
    /// @param tokenAddress token地址
    /// @param ntokenAddress ntoken地址
    function addNTokenMapping(address tokenAddress, address ntokenAddress) override external onlyGovernance {
        ntokenMapping[tokenAddress] = ntokenMapping[ntokenAddress] = ntokenAddress;
    }

    /// @dev 获取token对应的ntoken地址
    /// @param tokenAddress token地址
    /// @return ntoken地址
    function getNTokenAddress(address tokenAddress) override public view returns (address) {
        return ntokenMapping[tokenAddress];
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address nestTokenAddress)
    {
        //governance = msg.sender;
        flag = NTCTRL_FLAG_UNINITIALIZED;
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);
        nestMining = INestGovernance(nestGovernanceAddress).getNestMiningAddress();
    }
    
    /// @dev The initialization function takes `_ntokenCounter` as argument, 
    ///     which shall be migrated from Nest v3.0
    function start(uint32 _ntokenCounter) public onlyGovernance
    {
        require(flag == NTCTRL_FLAG_UNINITIALIZED, "Nest:NTC:!flag");
        ntokenCounter = _ntokenCounter;
        flag = NTCTRL_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_ACTIVE));
    }

    modifier whenActive() 
    {
        require(flag == NTCTRL_FLAG_ACTIVE, "Nest:NTC:!flag");
        _;
    }

    function setParams(uint256 _openFeeNestAmount) override external onlyGovernance
    {
        uint256 _old = openFeeNestAmount;
        openFeeNestAmount = _openFeeNestAmount;
        emit ParamsSetup(address(msg.sender), _old, _openFeeNestAmount);
    }

    /// @dev  Bad tokens should be banned 
    function disable(address token) external onlyGovernance
    {
        NTokenTag storage _to = nTokenTagList[token];
        _to.state = 1;
        emit NTokenDisabled(token);
    }

    function enable(address token) external onlyGovernance
    {
        NTokenTag storage _to = nTokenTagList[token];
        _to.state = 0;
        emit NTokenEnabled(token);
    }

    /// @dev Stop service for emergency
    function pause() external onlyGovernance
    {
        require(flag == NTCTRL_FLAG_ACTIVE, "Nest:NTC:!flag");
        flag = NTCTRL_FLAG_PAUSED;
        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_PAUSED));
    }

    /// @dev Resume service 
    function resume() external onlyGovernance
    {
        require(flag == NTCTRL_FLAG_PAUSED, "Nest:NTC:!flag");
        flag = NTCTRL_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_ACTIVE));
    }

    /* ========== OPEN ========== */

    /// @notice  Open a NToken for a token by anyone (contracts aren't allowed)
    /// @dev  Create and map the (Token, NToken) pair in NestPool
    /// @param tokenAddress  The address of token contract
    function open(address tokenAddress) override external noContract whenActive
    {
        // 开通nToken报价

        // token必须没有对应的nToken
        require(getNTokenAddress(tokenAddress) == address(0), "Nest:NTC:EX(token)");

        // token的标记为0
        require(nTokenTagList[tokenAddress].state == 0,
            "Nest:NTC:DIS(token)");

        nTokenTagList[tokenAddress] = NTokenTag(
            address(msg.sender),                                // owner
            uint128(0),                                         // nestFee
            uint64(block.timestamp),                            // startTime
            0,                                                  // state
            0                                                   // _reserved
        );
        
        // 创建nToken代币合约
        // create ntoken
        NToken ntoken = new NToken(strConcat("NToken",
                getAddressStr(ntokenCounter)),
                strConcat("N", getAddressStr(ntokenCounter))
                //address(governance),
                //address(0),
                // NOTE: here `bidder`, we use `C_NestPool` to separate new NTokens 
                //   from old ones, whose bidders are the miners creating NTokens
                //address(NEST_MINING_ADDRESS)
        );

        address governance = _governance;
        ntoken.update(governance);

        // 计数
        // increase the counter
        ntokenCounter = ntokenCounter + 1;  // safe math
        //addNTokenMapping(token, address(ntoken));
        ntokenMapping[tokenAddress] = ntokenMapping[address(ntoken)] = address(ntoken);

        // is token valid ?
        IERC20 tokenERC20 = IERC20(tokenAddress);
        TransferHelper.safeTransferFrom(tokenAddress, address(msg.sender), address(this), 1);
        require(tokenERC20.balanceOf(address(this)) >= 1, 
            "Nest:NTC:!TEST(token)");
        TransferHelper.safeTransfer(tokenAddress, address(msg.sender), 1);

        // 支付nest
        // charge nest
        IERC20(NEST_TOKEN_ADDRESS).transferFrom(address(msg.sender), address(governance), openFeeNestAmount);

        // raise an event
        emit NTokenOpened(tokenAddress, address(ntoken), address(msg.sender));
    }

    /* ========== VIEWS ========== */

    function NTokenTagOf(address token) override public view returns (NTokenTag memory) 
    {
        return nTokenTagList[token];
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