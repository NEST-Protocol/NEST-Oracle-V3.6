// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/SafeMath.sol";
import "./interface/INToken.sol";
import "./interface/INestGovernance.sol";
import "./NestBase.sol";

// The contract is based on Nest_NToken from Nest Protocol v3.0. Considering compatibility, the interface
// keeps the same. 

contract NToken is NestBase, INToken {
    using SafeMath for uint256;

    // TODO: 使用UINT结构体
    mapping (address => uint256) private _balances;
    // TODO: 使用UINT结构体
    mapping (address => mapping (address => uint256)) private _allowed;
    uint8 constant public decimals = 18;
    string public name;
    string public symbol;
    //uint256 public _totalSupply = 0 ether;                                        
    //uint256 public lastestMintAtHeight;
    
    // token状态，高128位表示_totalSupply，低128位表示lastestMintAtHeight
    uint256 _state;
    uint256 immutable public createdAtHeight;

    address C_NestMining;
    
    /// @notice Constructor
    /// @dev Given the address of NestPool, NToken can get other contracts by calling addrOfxxx()
    /// @param _name The name of NToken
    /// @param _symbol The symbol of NToken
    constructor (string memory _name, string memory _symbol) {
    	name = _name;                                                               
    	symbol = _symbol;
    	createdAtHeight = block.number;
    	//lastestMintAtHeight = block.number;
        _state = block.number;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);
        C_NestMining = INestGovernance(nestGovernanceAddress).getNestMiningAddress();
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

        // _totalSupply和lastestMintAtHeight共用一个存储
        //_totalSupply = _totalSupply.add(amount);
        //lastestMintAtHeight = block.number;
        _state = (((_state >> 128) + amount) << 128) | block.number;
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
    
    
    /// @notice The view of variables about minting 
    /// @dev The naming follows Nestv3.0
    /// @return createBlock The block number where the contract was created
    /// @return recentlyUsedBlock The block number where the last minting went
    function checkBlockInfo() 
        override public view 
        returns(uint256 createBlock, uint256 recentlyUsedBlock) 
    {
        return (createdAtHeight, _state & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
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
        //return C_NestPool;
        return C_NestMining;
    }
}