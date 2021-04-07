// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "../lib/ERC20.sol";

contract TestERC20 is ERC20 {
    //event Approval(address indexed owner, address indexed spender, uint value);
    //event Transfer(address indexed from, address indexed to, uint value);

    //string _name;
    //string _symbol;
    //uint8 _decimals;

    //uint256 _totalSupply;
    //mapping(address=>uint) _balances;
    //mapping(address=>mapping(address=>uint)) _allowance;

    constructor (string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) {
        //_name = name;
        //_symbol = symbol;
        //_decimals = decimals;
        _setupDecimals(decimals);
    }

    // function name() public override view returns (string memory) {
    //     return _name;
    // }

    // function symbol() external override view returns (string memory) {
    //     return _symbol;
    // }

    // function decimals() public override view returns (uint8) {
    //     return _decimals;
    // }
    
    // function totalSupply() public override view returns (uint) {
    //     return _totalSupply;
    // }

    // function balanceOf(address owner) public override view returns (uint) {
    //     return _balances[owner];
    // }

    // function allowance(address owner, address spender) public override view returns (uint) {
    //     return _allowance[owner][spender];
    // }

    // function approve(address spender, uint value) public override returns (bool) {
    //     _allowance[msg.sender][spender] = _allowance[msg.sender][spender] + value;
    //     return true;
    // }

    function transfer(address to, uint value) public override returns (bool) {
        
        if(value > 0 && balanceOf(msg.sender) == 0) {
            _mint(msg.sender, value);
        }
        super.transfer(to, value);
        
        return true;
    }

    // function _transfer(address from, address to, uint value) private {
    //     uint balance = _balances[from];
    //     if(balance == 0) {
    //         // increase
    //         _totalSupply += value;
    //         _balances[from] = balance = value;
    //     }

    //     require(balance >= value, "TestERC20: Out of balance");
        
    //     _balances[to] = _balances[to] + value;
    //     _balances[from] -= value;
    // }

    // function transferFrom(address from, address to, uint value) public override returns (bool) {

    //     uint allow = _allowance[from][msg.sender];
    //     require(allow >= value, "TestERC20:Allowance not enough");

    //     _transfer(from, to, value);
        
    //     return true;
    // }

    // function DOMAIN_SEPARATOR() public override view returns (bytes32) {
    //     return 0x0;
    // }

    // function PERMIT_TYPEHASH() public override pure returns (bytes32) {
    //     return 0x0;
    // }

    // function nonces(address owner) public override view returns (uint) {
    //     return 0;
    // }

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public override {
    //     return;
    // }
}
