// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/SafeMath.sol";
import "./lib/IERC20.sol";
//import "./lib/AddressPayable.sol";

import './lib/TransferHelper.sol';
import "./interface/INestMining.sol";
import "./interface/INestVote.sol";
import "./interface/IVotePropose.sol";
import "./interface/INestGovernance.sol";
import "./NestBase.sol";

/// @title NestVote
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

contract NestVote is NestBase, INestVote {// is ReentrancyGuard {

    using SafeMath for uint;

    struct UINT {
        uint value;
    }

    /// @dev 配置结构体
    struct Config {

        // 投票通过需要的比例（万分制）。5100
        uint32 acceptance;

        // 投票时间周期。7 * 86400秒
        uint64 voteDuration;

        // 投票需要抵押的nest数量。100000 nest
        uint128 proposalStaking;
    }

    // 提案
    struct Proposal {
        
        /* ========== 变动字段 ========== */
        // 获得的投票量
        // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
        uint96 gainValue;

        // 提案状态
        uint32 state;  // 0: proposed | 1: accepted | 2: rejected

        // 提案执行者
        address executor;

        // 将固定字段和变动字段分开存储，
        /* ========== 固定字段 ========== */

        // 提案简介
        string brief;

        // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
        address contractAddress;

        // 投票开始时间
        uint64 startTime;

        // 提案者
        address proposer;

        // 投票截止时间
        uint64 stopTime;

        // // 投票人数计数
        // uint64 voters;

        // 执行时间（如果有，例如区块号或者时间戳）放在合约里面，由合约自行限制
    }

    /* ========== STATE ============== */

    uint8 public  flag;
    uint8 constant NESTVOTE_FLAG_UNINITIALIZED = 0;
    uint8 constant NESTVOTE_FLAG_INITIALIZED   = 1;
    uint constant NEST_TOTAL_SUPPLY = 1000000000 ether;
    
    uint32 public voteDuration = 7 days;
    uint32 public acceptance = 51;
    uint public proposalStaking = 100000 * 1e18;
    
    Config _config;
    Proposal[] public _proposalList;
    mapping(uint =>mapping(address =>UINT)) public _stakedLedger;
    
    address _nestLedgerAddress;
    address _nestTokenAddress;
    address _nestMiningAddress;
    address _nnIncomeAddress;

    /* ========== EVENTS ========== */

    event NIPSubmitted(address proposer, uint id);
    event NIPVoted(address voter, uint id, uint amount);
    event NIPWithdraw(address voter, uint id, uint blnc);
    event NIPRevoke(address voter, uint id, uint amount);
    event NIPExecute(address executor, uint id);

    /* ========== CONSTRUCTOR ========== */

    receive() external payable {}

    // NOTE: to support open-zeppelin/upgrades, leave it blank
    constructor()
    { 
        flag = NESTVOTE_FLAG_INITIALIZED;
        //NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);
        //_nestTokenAddress = INestDAO(nestDaoAddress).getNestTokenAddress();
        //_nestMiningAddress = INestDAO(nestDaoAddress).getNestMiningAddress();
        //_nnIncomeAddress = INestDAO(nestDaoAddress).getNnIncomeAddress();

        (
            _nestTokenAddress, //address nestTokenAddress,
            _nestLedgerAddress, //address nestLedgerAddress,
              
            _nestMiningAddress, //address nestMiningAddress,
            , //address nestPriceFacadeAddress,
              
            , //address nestVoteAddress,
            , //address nestQueryAddress,
            _nnIncomeAddress, //address nnIncomeAddress,
             //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev 设置配置
    /// @param config 配置结构体
    function setConfig(Config memory config) public onlyGovernance {
        _config = config;
    }

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() public view returns (Config memory) {
        return _config;
    }

    /* ========== VOTE ========== */
    
    /// @dev 发起投票提案
    /// @param contractAddress 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
    /// @param brief 提案简介
    function propose(address contractAddress, string memory brief) override external 
    {
        Config memory config = _config;

        uint index = _proposalList.length;

        // 创建投票结构
        _proposalList.push(Proposal(
        
            uint96(0), 
            
            uint32(0), 

            address(0),

            // 提案简介
            //string brief;
            brief,

            // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
            //address contractAddress;
            contractAddress,

            // 投票开始时间
            //uint64 startTime;
            uint64(block.timestamp),

            // 提案者
            //address proposer;
            msg.sender,

            // 投票截止时间
            //uint64 stopTime;
            uint64(block.timestamp + uint(config.voteDuration))

        ));

        // 抵押nest
        IERC20(_nestTokenAddress).transferFrom(address(msg.sender), address(this), uint(config.proposalStaking));

        emit NIPSubmitted(msg.sender, index);
    }

    /// @dev 投票
    /// @param index 投票编号
    /// @param value 投票的nest数量
    function vote(uint index, uint value) override external noContract
    {
        // 1. 加载投票结构
        Proposal memory p = _proposalList[index];

        // 2. 检查
        // 检查是否在截止时间内
        // 注意，截止时间不包括stopTime
        require (block.timestamp >= uint(p.startTime) && block.timestamp < uint(p.stopTime), "NestVote:!time");

        // 3. 增加投票账本
        UINT storage balance = _stakedLedger[index][msg.sender];
        balance.value += value;

        // 4. 更新投票信息
        // 增加投票的nest
        // 更新得票量
        _proposalList[index].gainValue = uint96(uint(p.gainValue) + value);

        // 5. 抵押nest
        IERC20(_nestTokenAddress).transferFrom(msg.sender, address(this), value);

        emit NIPVoted(msg.sender, index, value);
    }

    // 取回投票的nest
    function withdraw(uint index) override external noContract
    {
        // 1. 加载投票结构
        Proposal memory p = _proposalList[index];

        // 2. 检查
        // TODO: 投票通过，但是没有执行，也可以取回吗
        require (uint(p.state) > 0 || block.timestamp >= uint(p.stopTime), "NestVote:!state");

        // 3. 更新账本
        UINT storage balance = _stakedLedger[index][msg.sender];
        uint balanceValue = balance.value;
        //p.gainValue = uint128(uint(p.gainValue) - balanceValue);
        balance.value = 0;

        //_proposalList[index] = p;

        // 4. 退回抵押的nest
        IERC20(_nestTokenAddress).transfer(address(msg.sender), balanceValue);

        emit NIPWithdraw(msg.sender, index, balanceValue);
    }

    // 撤销投票
    function revoke(uint index, uint value) override external noContract
    {
        // 1. 加载投票结构
        Proposal memory p = _proposalList[index];

        // 2. 检查
        require(block.timestamp >= uint(p.stopTime) && block.timestamp < uint(p.stopTime), "NestVote:!time");
        require(uint(p.state) == 0, "NestVote:!state");

        // 3. 更新账本
        UINT storage balance = _stakedLedger[index][msg.sender];
        uint balanceValue = balance.value;
        require(balanceValue >= value, "NestVote:!value"); 
        //p.gainValue = uint128(uint(p.gainValue) - value);
        balance.value = balanceValue - value;

        _proposalList[index].gainValue = uint96(uint(p.gainValue) - value);

        // 4. 退回抵押的nest
        IERC20(_nestTokenAddress).transfer(address(msg.sender), value);

        emit NIPRevoke(msg.sender, index, value);
    }

    // 执行投票
    function execute(uint index) override external
    {
        Config memory config = _config;

        // 1. 加载投票结构
        Proposal memory p = _proposalList[index];

        // 2. 检查
        //require (uint(p.state) == 1, "NestVote:!state");
        require (block.timestamp >= uint(p.stopTime), "NestVote:!time");

        // 3. 检查得票率
        // 判断投票是否通过
        IERC20 nest = IERC20(_nestTokenAddress);

        // 计算nest流通量
        uint nestCirculation = NEST_TOTAL_SUPPLY 
            - nest.balanceOf(_nestMiningAddress)
            - nest.balanceOf(_nnIncomeAddress)
            - nest.balanceOf(_nestLedgerAddress)
            - nest.balanceOf(address(0x1));

        require(uint(p.gainValue) >= nestCirculation * uint(config.acceptance) / 10000, "NestVote:!vote");

        // 3. 授予执行权限
        address governance = _governance;
        INestGovernance(governance).setGovernance(p.contractAddress, 1);

        // 4. 执行
        _proposalList[index].state = uint32(2);
        _proposalList[index].executor = address(msg.sender);
        IVotePropose(p.contractAddress).run();

        // 4. 删除执行权限
        INestGovernance(governance).setGovernance(p.contractAddress, 0);
        
        // 退回nest
        // TODO: 考虑config.proposalStaking参数变化的情况
        nest.transfer(p.proposer, uint(config.proposalStaking));

        emit NIPExecute(msg.sender, index);
    }

    // function stakedNestNum(uint index) override public view returns (uint) 
    // {
    //     Proposal storage p = proposalList[index].gainValue;
    //     //return (uint(p.stakedNestAmount).div(1e18));
    //     return (uint(p.stakedNestAmount));
    // }

    // function numberOfVoters(uint id) public view returns (uint) 
    // {
    //     Proposal storage p = proposalList[id];
    //     return (uint(p.voters));
    // }

    /// @dev 获取投票信息
    /// @param index 投票编号
    /// @return 投票信息结构体
    function getProposeInfo(uint index) override external view returns (ProposalView memory) {
        
        Proposal memory p = _proposalList[index];
        return ProposalView(
            // 提案简介
            //string brief;
            p.brief,

            // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
            //address contractAddress;
            p.contractAddress,

            // 提案者
            //address proposer;
            p.proposer,

            // 投票开始时间
            //uint64 startTime;
            p.startTime,

            // 投票截止时间
            //uint64 stopTime;
            p.stopTime,

            // 获得的投票量
            // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
            //uint96 gainValue;
            p.gainValue,

            // 提案状态
            //uint32 state;  // 0: proposed | 1: accepted | 2: rejected
            p.state,

            // 提案执行者
            //address executor;
            p.executor
        );
    }

    /// @dev 获取累计投票提案数量
    /// @return 累计投票提案数量
    function getProposeCount() override external view returns (uint) {
        return _proposalList.length;
    }
}