// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/SafeMath.sol";
import "../lib/IERC20.sol";
import "./Nest_3_VoteFactory.sol";
import "../interface/INest_NToken.sol";

contract Nest_NToken is INest_NToken {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;                                 //  账本
    mapping (address => mapping (address => uint256)) private _allowed;             //  授权账本
    uint256 private _totalSupply = 0 ether;                                         //  总量
    string public name;                                                             //  名称
    string public symbol;                                                           //  简称
    uint8 public decimals = 18;                                                     //  精度
    uint256 public _createBlock;                                                    //  创建区块
    uint256 public _recentlyUsedBlock;                                              //  最近使用区块
    Nest_3_VoteFactory _voteFactory;                                                //  投票合约
    address _bidder;                                                                //  拥有者
    
    /**
    * @dev 初始化方法
    * @param _name token名称
    * @param _symbol token简称
    * @param voteFactory 投票合约地址
    * @param bidder 中标者地址
    */
    constructor (string memory _name, string memory _symbol, address voteFactory, address bidder) {
    	name = _name;                                                               
    	symbol = _symbol;
    	_createBlock = block.number;
    	_recentlyUsedBlock = block.number;
    	_voteFactory = Nest_3_VoteFactory(address(voteFactory));
    	_bidder = bidder;
    }
    
    /**
    * @dev 重置投票合约方法
    * @param voteFactory 投票合约地址
    */
    function changeMapping (address voteFactory) override public onlyOwner {
    	_voteFactory = Nest_3_VoteFactory(address(voteFactory));
    }
    
    /**
    * @dev 增发
    * @param value 增发数量
    */
    function increaseTotal(uint256 value) override public {
        address offerMain = address(_voteFactory.checkAddress("nest.nToken.offerMain"));
        require(address(msg.sender) == offerMain, "No authority");
        _balances[offerMain] = _balances[offerMain].add(value);
        _totalSupply = _totalSupply.add(value);
        _recentlyUsedBlock = block.number;
    }

    /**
    * @dev 查询token总量
    * @return token总量
    */
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev 查询地址余额
    * @param owner 要查询的地址
    * @return 返回对应地址的余额
    */
    function balanceOf(address owner) override public view returns (uint256) {
        return _balances[owner];
    }
    
    /**
    * @dev 查询区块信息
    * @return createBlock 初始区块数
    * @return recentlyUsedBlock 最近挖矿增发区块
    */
    function checkBlockInfo() override public view returns(uint256 createBlock, uint256 recentlyUsedBlock) {
        return (_createBlock, _recentlyUsedBlock);
    }

    /**
     * @dev 查询 owner 对 spender 的授权额度
     * @param owner 发起授权的地址
     * @param spender 被授权的地址
     * @return 已授权的金额
     */
    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev 转账方法
    * @param to 转账目标
    * @param value 转账金额
    * @return 转账是否成功
    */
    function transfer(address to, uint256 value) override public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev 授权方法
     * @param spender 授权目标
     * @param value 授权数量
     * @return 授权是否成功
     */
    function approve(address spender, uint256 value) override public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev 已授权状态下，从 from地址转账到to地址
     * @param from 转出的账户地址 
     * @param to 转入的账户地址
     * @param value 转账金额
     * @return 授权转账是否成功
     */
    function transferFrom(address from, address to, uint256 value) override public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev 增加授权额度
     * @param spender 授权目标
     * @param addedValue 增加的额度
     * @return 增加授权额度是否成功
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev 减少授权额度
     * @param spender 授权目标
     * @param subtractedValue 减少的额度
     * @return 减少授权额度是否成功
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev 转账方法
    * @param to 转账目标
    * @param value 转账金额
    */
    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    /**
    * @dev 查询创建者
    * @return 创建者地址
    */
    function checkBidder() override public view returns(address) {
        return _bidder;
    }
    
    /**
    * @dev 转让创建者
    * @param bidder 新创建者地址
    */
    function changeBidder(address bidder) override public {
        require(address(msg.sender) == _bidder);
        _bidder = bidder; 
    }
    
    // 仅限管理员操作
    modifier onlyOwner(){
        require(_voteFactory.checkOwners(msg.sender));
        _;
    }
}