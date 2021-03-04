// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/INestDAO.sol";

/// @dev The contract is for redeeming nest token and getting ETH in return
contract NestDAO is INestDAO/*, INestVote*/ {

    using SafeMath for uint;

    uint constant NEST_REWARD_SCALE = 0.2 ether;
    uint constant NTOKEN_REWARD_SCALE = 1 ether - NEST_REWARD_SCALE;

    struct UINT {
        uint value;
    }

    address immutable NEST_TOKEN_ADDRESS;

    constructor(address nestTokenAddress) public {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
        governanceMapping[msg.sender] = GovernanceInfo(msg.sender, 1);
    }

    uint nestLedger;
    mapping(address=>UINT) ntokenLedger;

    struct GovernanceInfo {
        address addr;
        uint96 flag;
    }

    mapping(address=>GovernanceInfo) governanceMapping;
    
    /// @dev 挖矿合约地址
    address public nestMining;
    /// @dev 价格调用入口合约地址
    address public nestPriceFacade;
    /// @dev 投票合约地址
    address public nestVote;
    /// @dev 提供价格的合约地址
    address public nestQuery;
    /// @dev NN挖矿合约
    address public nnIncome;
    /// @dev nToken管理合约地址
    address public nTokenController;

    /// @dev 获取系统内置的合约地址
    /// @param nestMiningAddress 挖矿合约地址
    /// @param nestPriceFacadeAddress 价格调用入口合约地址
    /// @param nestVoteAddress 投票合约地址
    /// @param nestQueryAddress 提供价格的合约地址
    /// @param nnIncomeAddress NN挖矿合约
    /// @param nTokenControllerAddress nToken管理合约地址
    function setBuiltinAddress(
        address nestMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) override external {
        
        if (nestMiningAddress != address(0)) {
            nestMining = nestMiningAddress;
        }
        if (nestPriceFacadeAddress != address(0)) {
            nestPriceFacade = nestPriceFacadeAddress;
        }
        if (nestVoteAddress != address(0)) {
            nestVote = nestVoteAddress;
        }
        if (nestQueryAddress != address(0)) {
            nestQuery = nestQueryAddress;
        }
        if (nnIncomeAddress != address(0)) {
            nnIncome = nnIncomeAddress;
        }
        if (nTokenControllerAddress != address(0)) {
            nTokenController = nTokenControllerAddress;
        }
    }

    /// @dev 获取系统内置的合约地址
    /// @return nestMiningAddress 挖矿合约地址
    /// @return nestPriceFacadeAddress 价格调用入口合约地址
    /// @return nestVoteAddress 投票合约地址
    /// @return nestQueryAddress 提供价格的合约地址
    /// @return nnIncomeAddress NN挖矿合约
    /// @return nTokenControllerAddress nToken管理合约地址
    function getBuiltinAddress() override external view returns (
        address nestMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) {
        return (
            nestMining,
            nestPriceFacade,
            nestVote,
            nestQuery,
            nnIncome,
            nTokenController
        );
    }

    /// @dev 获取挖矿合约地址
    /// @return 挖矿合约地址
    function getNestMiningAddress() override external view returns (address) { return nestMining; }

    /// @dev 获取价格调用入口合约地址
    /// @return 价格调用入口合约地址
    function getNestPriceFacadeAddress() override external view returns (address) { return nestPriceFacade; }

    /// @dev 获取投票合约地址
    /// @return 投票合约地址
    function getNestVoteAddress() override external view returns (address) { return nestVote; }

    /// @dev 获取提供价格的合约地址
    /// @return 提供价格的合约地址
    function getNestQueryAddress() override external view returns (address) { return nestQuery; }

    /// @dev 获取NN挖矿合约
    /// @return NN挖矿合约
    function getNnIncomeAddress() override external view returns (address) { return nnIncome; }

    /// @dev 获取nToken管理合约地址
    /// @return nToken管理合约地址
    function getNTokenControllerAddress() override external view returns (address) { return nTokenController; }

    /// @dev ntoken收益
    /// @param ntokenAddress ntoken地址
    function addReward(address ntokenAddress) override external payable {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            nestLedger += msg.value;
        } else {
            UINT storage balance = ntokenLedger[ntokenAddress];
            balance.value = balance.value + msg.value * NTOKEN_REWARD_SCALE / 1 ether;
            nestLedger = nestLedger + msg.value * NEST_REWARD_SCALE / 1 ether;
        }
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The notoken address
    function totalRewards(address ntokenAddress) override external view returns (uint) {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            return nestLedger;
        }
        return ntokenLedger[ntokenAddress].value;
    }

    /// @dev Redeem ntokens for ethers
    /// @notice Ethfee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount  The amount of ntoken
    function redeem(address ntokenAddress, uint amount) override external payable {
        require(ntokenAddress == address(0) && amount == 0 && false, "NestDAO:not implement");
    }

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) override public view returns (uint quota) {
        require(ntokenAddress == address(0) && false, "NestDAO:not implement");
        return 0;
    }

    /// @dev 检查目标地址是否具备对给定目标的治理权限
    /// @param 目标地址
    /// @param 治理目标
    /// @return true表示有权限
    function checkGovernance(address addr, uint flag) override external view returns (bool) {
        
        if (governanceMapping[addr].flag > 0) {
            return true;
        }

        return false;
    }
    
    /* 投票 */

    // /* ========== STATE ============== */

    // uint32 public voteDuration = 7 days;
    // uint32 public acceptance = 51;
    // uint256 public proposalStaking = 100_000 * 1e18;

    // // 提案
    // struct Proposal {
    //     // 提案描述
    //     string description;
    //     uint32 state;  // 0: proposed | 1: accepted | 2: rejected
    //     uint32 startTime;
    //     uint32 endTime;
    //     uint64 voters;
    //     uint128 stakedNestAmount;
    //     address contractAddr;
    //     address proposer;
    //     address executor;
    // }
    
    // Proposal[] public proposalList;
    // mapping(uint256 => mapping(address => uint256)) public stakedNestAmount;

    // address private C_NestToken;
    // address private C_NestPool;
    // address private C_NestDAO;
    // address private C_NestMining;

    // address public governance;
   
    // uint8 public  flag;
    // uint8 constant NESTVOTE_FLAG_UNINITIALIZED = 0;
    // uint8 constant NESTVOTE_FLAG_INITIALIZED   = 1;


    // /* ========== EVENTS ========== */

    // event NIPSubmitted(address proposer, uint256 id);
    // event NIPVoted(address voter, uint256 id, uint256 amount);
    // event NIPWithdraw(address voter, uint256 id, uint256 blnc);
    // event NIPRevoke(address voter, uint256 id, uint256 amount);
    // event NIPExecute(address executor, uint256 id);

    // /* ========== CONSTRUCTOR ========== */

    // receive() external payable {}

    // // NOTE: to support open-zeppelin/upgrades, leave it blank
    // constructor() public
    // {  }

    // // NOTE: can only be executed once
    // function initialize(address NestPool) external
    // {
    //     require(flag == NESTVOTE_FLAG_UNINITIALIZED, "Vote:init:!flag" );

    //     governance = msg.sender;
    //     C_NestPool = NestPool;
    //     flag = NESTVOTE_FLAG_INITIALIZED;

    // }

    // /* ========== MODIFIERS ========== */

    // modifier onlyGovernance() 
    // {
    //     require(msg.sender == governance);
    //     _;
    // }

    // modifier noContract() 
    // {
    //     require(address(msg.sender) == address(tx.origin), "Nest:Vote:BAN(contract)");
    //     _;
    // }

    // /* ========== GOVERNANCE ========== */

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

    // function releaseGovTo(address gov) public onlyGovernance
    // {
    //     governance = gov;
    // }

    // function setParams(uint32 voteDuration_, uint32 acceptance_, uint256 proposalStaking_) 
    //     public onlyGovernance
    // {
    //     acceptance = acceptance_;
    //     voteDuration = voteDuration_;
    //     proposalStaking = proposalStaking_;
    // }

    // /* ========== VOTE ========== */
    
    // // 发起投票
    // function propose(address contract_, string memory description) external
    // {
    //     uint256 id = proposalList.length;
    //     proposalList.push(Proposal(
    //         string(description),
    //         uint32(0),                   // state
    //         uint32(block.timestamp),    //startTime
    //         uint32(block.timestamp + voteDuration),  //endTime
    //         uint64(0),                  // voters
    //         uint128(0),                 // stakedNestAmount
    //         contract_,                 //contractAddr
    //         address(msg.sender),        // proposer
    //         address(0)                 // executor
    //      ));

    //     // 抵押nest
    //     ERC20(C_NestToken).transferFrom(address(msg.sender), address(this), proposalStaking);

    //     emit NIPSubmitted(msg.sender, id);
    // }

    // function vote(uint256 id, uint256 amount) external noContract
    // {
    //     // 加载投票结构
    //     Proposal memory p = proposalList[id];
    //     // 检查是否超过截止时间
    //     require (block.timestamp <= p.endTime, "Nest:Vote:!time");
    //     // 增加投票账本
    //     uint256 blncs = stakedNestAmount[id][address(msg.sender)];
    //     stakedNestAmount[id][address(msg.sender)] = blncs.add(amount); 
    //     // 增加投票的nest
    //     p.stakedNestAmount = uint128(uint256(p.stakedNestAmount).add(amount));
    //     if (blncs == 0) {
    //         p.voters = uint64(uint256(p.voters).add(1));

    //     }
    //     proposalList[id] = p;

    //     // 转入nest
    //     ERC20(C_NestToken).transferFrom(address(msg.sender), address(this), amount);

    //     emit NIPVoted(msg.sender, id, amount);
    // }

    // // 取回投票的nest
    // function withdraw(uint256 id) external noContract
    // {
    //     Proposal memory p = proposalList[id];
    //     require (p.state > 0, "Nest:Vote:!state");

    //     uint256 blnc = stakedNestAmount[id][address(msg.sender)];
    //     p.stakedNestAmount = uint128(uint256(p.stakedNestAmount).sub(blnc));
    //     stakedNestAmount[id][address(msg.sender)] = 0;

    //     proposalList[id] = p;

    //     ERC20(C_NestToken).transfer(address(msg.sender), blnc);

    //     emit NIPWithdraw(msg.sender, id, blnc);
    // }

    // // 撤销投票
    // function revoke(uint256 id, uint256 amount) external noContract
    // {
    //     Proposal memory p = proposalList[id];

    //     require (uint256(block.timestamp) <= uint256(p.endTime), "Nest:Vote:!time");

    //     uint256 blnc = stakedNestAmount[id][address(msg.sender)];
    //     require(blnc >= amount, "Nest:Vote:!amount"); 
    //     if (blnc == amount) {
    //         p.voters = uint64(uint256(p.voters).sub(1));
    //     }

    //     p.stakedNestAmount = uint128(uint256(p.stakedNestAmount).sub(amount));
    //     stakedNestAmount[id][address(msg.sender)] = blnc.sub(amount);

    //     proposalList[id] = p;

    //     ERC20(C_NestToken).transfer(address(msg.sender), amount);

    //     emit NIPRevoke(msg.sender, id, amount);
    // }

    // // 执行投票
    // function execute(uint256 id) external
    // {
    //     // 计算流通量
    //     uint256 _total_mined = INestMining(C_NestMining).minedNestAmount();
    //     uint256 _burned = ERC20(C_NestToken).balanceOf(address(0x1));
    //     uint256 _repurchased = ERC20(C_NestToken).balanceOf(C_NestDAO);

    //     uint256 _circulation = _total_mined.sub(_repurchased).sub(_burned);

    //     Proposal storage p = proposalList[id];
    //     require (p.state == 0, "Nest:Vote:!state");
    //     require (p.endTime < block.timestamp, "Nest:Vote:!time");

    //     if (p.stakedNestAmount > _circulation.mul(acceptance).div(100)) {
    //         address _contract = p.contractAddr;
    //         (bool success, bytes memory result) = _contract.delegatecall(abi.encodeWithSignature("run()"));
    //         require(success, "Nest:Vote:!exec");
    //         p.state = 1;
    //     } else {
    //         p.state = 2;
    //     }

    //     // TODO: 可以通过故意触发execute方法来让投票作废?
    //     p.executor = address(msg.sender);

    //     proposalList[id] = p;
        
    //     // 退回nest
    //     ERC20(C_NestToken).transfer(p.proposer, proposalStaking);

    //     emit NIPExecute(msg.sender, id);
    // }

    // function stakedNestNum(uint256 id) public view returns (uint256) 
    // {
    //     Proposal storage p = proposalList[id];
    //     //return (uint256(p.stakedNestAmount).div(1e18));
    //     return (uint256(p.stakedNestAmount));
    // }

    // function numberOfVoters(uint256 id) public view returns (uint256) 
    // {
    //     Proposal storage p = proposalList[id];
    //     return (uint256(p.voters));
    // }
}