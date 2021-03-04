// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INToken {
    // mint ntoken for value
    function mint(uint256 amount, address account) external;

    // the block height where the ntoken was created
    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);
    // the owner (auction winner) of the ntoken
    function checkBidder() external view returns(address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}