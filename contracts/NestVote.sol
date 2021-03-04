// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "./lib/AddressPayable.sol";

import "./interface/INestMining.sol";
import "./interface/INestVote.sol";

//import "./lib/SafeERC20.sol";
//import "./lib/ReentrancyGuard.sol";
import './lib/TransferHelper.sol';

// import "hardhat/console.sol";


/// @title NestVote
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

contract NestVote is INestVote {// is ReentrancyGuard {

    using SafeMath for uint256;

    /* ========== STATE ============== */

    uint32 public voteDuration = 7 days;
    uint32 public acceptance = 51;
    uint256 public proposalStaking = 100_000 * 1e18;

    
    Proposal[] public proposalList;
    mapping(uint256 => mapping(address => uint256)) public stakedNestAmount;

    address private C_NestToken;
    //address private C_NestPool;
    address private C_NestDAO;
    address private C_NestMining;

    address public governance;
   
    uint8 public  flag;
    uint8 constant NESTVOTE_FLAG_UNINITIALIZED = 0;
    uint8 constant NESTVOTE_FLAG_INITIALIZED   = 1;


    /* ========== EVENTS ========== */

    event NIPSubmitted(address proposer, uint256 id);
    event NIPVoted(address voter, uint256 id, uint256 amount);
    event NIPWithdraw(address voter, uint256 id, uint256 blnc);
    event NIPRevoke(address voter, uint256 id, uint256 amount);
    event NIPExecute(address executor, uint256 id);

    /* ========== CONSTRUCTOR ========== */

    receive() external payable {}

    // NOTE: to support open-zeppelin/upgrades, leave it blank
    constructor() public
    { 
        governance = msg.sender;
        //C_NestPool = NestPool;
        flag = NESTVOTE_FLAG_INITIALIZED;
    }

    // // NOTE: can only be executed once
    // function initialize(address NestPool) external
    // {
    //     require(flag == NESTVOTE_FLAG_UNINITIALIZED, "Vote:init:!flag" );

    //     governance = msg.sender;
    //     C_NestPool = NestPool;
    //     flag = NESTVOTE_FLAG_INITIALIZED;

    // }


    /* ========== MODIFIERS ========== */

    modifier onlyGovernance() 
    {
        require(msg.sender == governance);
        _;
    }

    modifier noContract() 
    {
        require(address(msg.sender) == address(tx.origin), "Nest:Vote:BAN(contract)");
        _;
    }

    /* ========== GOVERNANCE ========== */

    // function loadGovernance() external 
    // { 
    //     governance = INestPool(C_NestPool).governance();
    // }


    // function setGovernance(address _gov) external onlyGovernance
    // { 
    //     INestPool(C_NestPool).setGovernance(_gov);
    // }

    // function loadContracts() public onlyGovernance
    // {
    //     C_NestToken = INestPool(C_NestPool).addrOfNestToken();
    //     C_NestDAO = INestPool(C_NestPool).addrOfNestDAO();
    //     C_NestMining = INestPool(C_NestPool).addrOfNestMining();
    // }

    function releaseGovTo(address gov) public onlyGovernance
    {
        governance = gov;
    }

    function setParams(uint32 voteDuration_, uint32 acceptance_, uint256 proposalStaking_) 
        public onlyGovernance
    {
        acceptance = acceptance_;
        voteDuration = voteDuration_;
        proposalStaking = proposalStaking_;
    }

    /* ========== VOTE ========== */
    
    // 发起投票
    function propose(address contract_, string memory description) override external
    {
        uint256 id = proposalList.length;
        proposalList.push(Proposal(
            string(description),
            uint32(0),                   // state
            uint32(block.timestamp),    //startTime
            uint32(block.timestamp + voteDuration),  //endTime
            uint64(0),                  // voters
            uint128(0),                 // stakedNestAmount
            contract_,                 //contractAddr
            address(msg.sender),        // proposer
            address(0)                 // executor
         ));

        // 抵押nest
        IERC20(C_NestToken).transferFrom(address(msg.sender), address(this), proposalStaking);

        emit NIPSubmitted(msg.sender, id);
    }

    function vote(uint256 id, uint256 amount) override external noContract
    {
        // 加载投票结构
        Proposal memory p = proposalList[id];
        // 检查是否超过截止时间
        require (block.timestamp <= p.endTime, "Nest:Vote:!time");
        // 增加投票账本
        uint256 blncs = stakedNestAmount[id][address(msg.sender)];
        stakedNestAmount[id][address(msg.sender)] = blncs.add(amount); 
        // 增加投票的nest
        p.stakedNestAmount = uint128(uint256(p.stakedNestAmount).add(amount));
        if (blncs == 0) {
            p.voters = uint64(uint256(p.voters).add(1));

        }
        proposalList[id] = p;

        // 转入nest
        IERC20(C_NestToken).transferFrom(address(msg.sender), address(this), amount);

        emit NIPVoted(msg.sender, id, amount);
    }

    // 取回投票的nest
    function withdraw(uint256 id) override external noContract
    {
        Proposal memory p = proposalList[id];
        require (p.state > 0, "Nest:Vote:!state");

        uint256 blnc = stakedNestAmount[id][address(msg.sender)];
        p.stakedNestAmount = uint128(uint256(p.stakedNestAmount).sub(blnc));
        stakedNestAmount[id][address(msg.sender)] = 0;

        proposalList[id] = p;

        IERC20(C_NestToken).transfer(address(msg.sender), blnc);

        emit NIPWithdraw(msg.sender, id, blnc);
    }

    // 撤销投票
    function revoke(uint256 id, uint256 amount) override external noContract
    {
        Proposal memory p = proposalList[id];

        require (uint256(block.timestamp) <= uint256(p.endTime), "Nest:Vote:!time");

        uint256 blnc = stakedNestAmount[id][address(msg.sender)];
        require(blnc >= amount, "Nest:Vote:!amount"); 
        if (blnc == amount) {
            p.voters = uint64(uint256(p.voters).sub(1));
        }

        p.stakedNestAmount = uint128(uint256(p.stakedNestAmount).sub(amount));
        stakedNestAmount[id][address(msg.sender)] = blnc.sub(amount);

        proposalList[id] = p;

        IERC20(C_NestToken).transfer(address(msg.sender), amount);

        emit NIPRevoke(msg.sender, id, amount);
    }

    uint constant NEST_TOTAL_SUPPLY = 1000000000 ether;
    address nnincome = address(0);
    function minedNestAmount() private view returns (uint) {

        // nest挖出的量按照此算法计算，可能存在用户未取回的nest
        // 未取回的nest包括用户挖矿抵押的nest和挖到的nest
        // 忽略此差异
        IERC20 nest = IERC20(C_NestToken);
        return NEST_TOTAL_SUPPLY - nest.balanceOf(C_NestMining) - nest.balanceOf(nnincome);
    }

    // 执行投票
    function execute(uint256 id) override external
    {
        // 计算流通量
        uint256 _total_mined = minedNestAmount();
        uint256 _burned = IERC20(C_NestToken).balanceOf(address(0x1));
        uint256 _repurchased = IERC20(C_NestToken).balanceOf(C_NestDAO);

        uint256 _circulation = _total_mined.sub(_repurchased).sub(_burned);

        Proposal storage p = proposalList[id];
        require (p.state == 0, "Nest:Vote:!state");
        require (p.endTime < block.timestamp, "Nest:Vote:!time");

        if (p.stakedNestAmount > _circulation.mul(acceptance).div(100)) {
            address _contract = p.contractAddr;
            (bool success, /*bytes memory result*/) = _contract.delegatecall(abi.encodeWithSignature("run()"));
            require(success, "Nest:Vote:!exec");
            p.state = 1;
        } else {
            p.state = 2;
        }

        // TODO: 可以通过故意触发execute方法来让投票作废?
        p.executor = address(msg.sender);

        proposalList[id] = p;
        
        // 退回nest
        IERC20(C_NestToken).transfer(p.proposer, proposalStaking);

        emit NIPExecute(msg.sender, id);
    }

    function stakedNestNum(uint256 id) override public view returns (uint256) 
    {
        Proposal storage p = proposalList[id];
        //return (uint256(p.stakedNestAmount).div(1e18));
        return (uint256(p.stakedNestAmount));
    }

    function numberOfVoters(uint256 id) public view returns (uint256) 
    {
        Proposal storage p = proposalList[id];
        return (uint256(p.voters));
    }

    /// @dev 获取投票信息
    /// @param proposeIndex 投票编号
    /// @return 投票信息结构体
    function getProposeInfo(uint proposeIndex) override external view returns (Proposal memory) {
        return proposalList[proposeIndex];
    }

    /// @dev 获取累计投票提案数量
    /// @return 累计投票提案数量
    function getProposeCount() override external view returns (uint) {
        return proposalList.length;
    }
}