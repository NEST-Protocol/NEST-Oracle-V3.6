// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./interface/INToken.sol";
import "./interface/INestGovernance.sol";
import "./NestBase.sol";

// The contract is based on Nest_NToken from Nest Protocol v3.0. Considering compatibility, the interface
// keeps the same. 
/// @dev ntoken contract
contract NToken is NestBase, INToken {

    // ntoken genesis block number
    uint256 immutable public GENESIS_BLOCK_NUMBER;
    // INestMining implemention contract address
    address _nestMiningAddress;
    
    // token information
    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
    // token state，high 128 bits represent _totalSupply，low 128 bits represent lastestMintAtHeight
    uint256 _state;
    
    // Balances ledger
    mapping (address=>uint) private _balances;
    // Approve ledger
    mapping (address=>mapping(address=>uint)) private _allowed;

    /// @notice Constructor
    /// @dev Given the address of NestPool, NToken can get other contracts by calling addrOfxxx()
    /// @param _name The name of NToken
    /// @param _symbol The symbol of NToken
    constructor (string memory _name, string memory _symbol) {

    	GENESIS_BLOCK_NUMBER = block.number;
    	name = _name;                                                               
    	symbol = _symbol;
        _state = block.number;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);
        _nestMiningAddress = INestGovernance(nestGovernanceAddress).getNestMiningAddress();
    }

    /// @dev Mint 
    /// @param amount The amount of NToken to add
    /// @param account The account of NToken to add
    function mint(uint256 amount, address account) override public {

        require(address(msg.sender) == _nestMiningAddress, "NToken:!Auth");
        
        // 目标地址增加余额
        _balances[account] += amount;

        // 增加发行量
        // _totalSupply和lastestMintAtHeight共用一个存储
        //_totalSupply = _totalSupply.add(amount);
        //lastestMintAtHeight = block.number;
        _state = (((_state >> 128) + amount) << 128) | block.number;
    }
        
    /// @notice The view of variables about minting 
    /// @dev The naming follows Nestv3.0
    /// @return createBlock The block number where the contract was created
    /// @return recentlyUsedBlock The block number where the last minting went
    function checkBlockInfo() 
        override public view 
        returns(uint256 createBlock, uint256 recentlyUsedBlock) 
    {
        return (GENESIS_BLOCK_NUMBER, _state & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    /// @dev The ABI keeps unchanged with old NTokens, so as to support token-and-ntoken-mining
    /// @return The address of bidder
    function checkBidder() override public view returns(address) {
        return _nestMiningAddress;
    }

    /// @notice The view of totalSupply
    /// @return The total supply of ntoken
    function totalSupply() override public view returns (uint256) {
        //return _totalSupply;
        return _state >> 128;
    }

    /// @dev The view of balances
    /// @param owner The address of an account
    /// @return The balance of the account
    function balanceOf(address owner) override public view returns (uint256) {
        return _balances[owner];
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
        mapping(address=>uint) storage allowed = _allowed[from];
        allowed[msg.sender] -= value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        mapping(address=>uint) storage allowed = _allowed[msg.sender];
        allowed[spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        mapping(address=>uint) storage allowed = _allowed[msg.sender];
        allowed[spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowed[spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }
}