// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/INToken.sol";

/// @title NNRewardPool
/// @author MLY0813 - <mly0813@nestprotocol.org>
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

// The contract is based on Nest_NToken from Nest Protocol v3.0. Considering compatibility, the interface
// keeps the same. 

contract NToken is INToken {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 public _totalSupply = 0 ether;                                        
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // TODO: 改为immutable
    uint256 public createdAtHeight;
    uint256 public lastestMintAtHeight;
    address public governance;

    /// @dev The address of NestPool (Nest Protocol v3.5)
    address C_NestPool;
    address C_NestMining;
    
    /// @notice Constructor
    /// @dev Given the address of NestPool, NToken can get other contracts by calling addrOfxxx()
    /// @param _name The name of NToken
    /// @param _symbol The symbol of NToken
    /// @param gov The address of admin
    /// @param nestMining NestMining合约地址
    constructor (string memory _name, string memory _symbol, address gov, address nestMining) public {
    	name = _name;                                                               
    	symbol = _symbol;
    	createdAtHeight = block.number;
    	lastestMintAtHeight = block.number;
    	governance = gov;
    	//C_NestPool = NestPool;
        C_NestMining = nestMining; //INestPool(C_NestPool).addrOfNestMining();
    }

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "Nest:NTK:!gov");
        _;
    }

    // /// @dev To ensure that all of governance-addresses be consist with each other
    // function loadGovernance() external 
    // { 
    //     governance = INestPool(C_NestPool).governance();
    // }

    // function loadContracts() external onlyGovernance
    // {
    //     C_NestMining = INestPool(C_NestPool).addrOfNestMining();
    // }

    // function resetNestPool(address _NestPool) external onlyGovernance
    // {
    //     C_NestPool = _NestPool;
    // }

    /// @dev Mint 
    /// @param amount The amount of NToken to add
    /// @param account The account of NToken to add
    function mint(uint256 amount, address account) override public {
        require(address(msg.sender) == C_NestMining, "Nest:NTK:!Auth");
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        lastestMintAtHeight = block.number;
    }

    /// @notice The view of totalSupply
    /// @return The total supply of ntoken
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    /// @dev The view of balances
    /// @param owner The address of an account
    /// @return The balance of the account
    function balanceOf(address owner) override public view returns (uint256) {
        return _balances[owner];
    }
    
    
    /// @notice The view of variables about minting 
    /// @dev The naming follows Nestv3.0
    /// @return createBlock The block number where the contract was created
    /// @return recentlyUsedBlock The block number where the last minting went
    function checkBlockInfo() 
        override public view 
        returns(uint256 createBlock, uint256 recentlyUsedBlock) 
    {
        return (createdAtHeight, lastestMintAtHeight);
    }

    function allowance(address owner, address spender) override public view returns (uint256) 
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) override public returns (bool) 
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) override public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


    function transferFrom(address from, address to, uint256 value) override public returns (bool) 
    {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    /// @dev The ABI keeps unchanged with old NTokens, so as to support token-and-ntoken-mining
    /// @return The address of bidder
    function checkBidder() override public view returns(address) {
        return C_NestPool;
    }
}