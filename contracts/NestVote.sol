// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "./lib/SafeMath.sol";
import "./lib/IERC20.sol";
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
    
    // NOTE: to support open-zeppelin/upgrades, leave it blank
    constructor()
    { 
    }

    struct UINT {
        uint value;
    }

    // 提案
    struct Proposal {

        // 将固定字段和变动字段分开存储，
        /* ========== 固定字段 ========== */

        // 提案简介
        string brief;

        // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
        address contractAddress;

        // 投票开始时间
        uint48 startTime;

        // 投票截止时间
        uint48 stopTime;

        // 提案者
        address proposer;

        // 抵押的nest
        uint96 staked;

        /* ========== 变动字段 ========== */
        // 获得的投票量
        // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
        uint96 gainValue;

        // 提案状态
        uint32 state;  // 0: proposed | 1: accepted | 2: cancelled

        // 提案执行者
        address executor;

        // 执行时间（如果有，例如区块号或者时间戳）放在合约里面，由合约自行限制
    }
    
    Config _config;
    Proposal[] public _proposalList;
    mapping(uint =>mapping(address =>UINT)) public _stakedLedger;
    
    address _nestLedgerAddress;
    address _nestTokenAddress;
    address _nestMiningAddress;
    address _nnIncomeAddress;

    uint32 constant PROPOSAL_STATE_PROPOSED = 0;
    uint32 constant PROPOSAL_STATE_ACCEPTED = 1;
    uint32 constant PROPOSAL_STATE_CANCELLED = 2;

    uint constant NEST_TOTAL_SUPPLY = 1000000000 ether;

    /* ========== EVENTS ========== */

    event NIPSubmitted(address proposer, uint id);
    event NIPVoted(address voter, uint id, uint amount);
    event NIPWithdraw(address voter, uint id, uint blnc);
    event NIPRevoke(address voter, uint id, uint amount);
    event NIPExecute(address executor, uint id);

    /* ========== CONSTRUCTOR ========== */

    receive() external payable {}

    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);

        (
            //address nestTokenAddress
            _nestTokenAddress, 
            //address nestLedgerAddress
            _nestLedgerAddress, 
            //address nestMiningAddress
            _nestMiningAddress, 
            //address nestPriceFacadeAddress
            ,
            //address nestVoteAddress
            ,
            //address nestQueryAddress
            ,
            //address nnIncomeAddress
            _nnIncomeAddress, 
            //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev 修改配置
    /// @param config 配置结构体
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev 获取配置
    /// @return 配置结构体
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /* ========== VOTE ========== */
    
    /// @dev 发起投票提案
    /// @param contractAddress 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
    /// @param brief 提案简介
    function propose(address contractAddress, string memory brief) override external noContract
    {
        // 目标地址不能已经拥有治理权限，防止治理权限被覆盖
        require(!INestGovernance(_governance).checkGovernance(contractAddress, 0), "NestVote:!governance");
     
        Config memory config = _config;
        uint index = _proposalList.length;

        // 创建投票结构
        _proposalList.push(Proposal(
        
            // 提案简介
            //string brief;
            brief,

            // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
            //address contractAddress;
            contractAddress,

            // 投票开始时间
            //uint48 startTime;
            uint48(block.timestamp),

            // 投票截止时间
            //uint48 stopTime;
            uint48(block.timestamp + uint(config.voteDuration)),

            // 提案者
            //address proposer;
            msg.sender,

            config.proposalStaking,

            uint96(0), 
            
            PROPOSAL_STATE_PROPOSED, 

            address(0)
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
        require (p.state == uint(PROPOSAL_STATE_PROPOSED), "NestVote:!state");

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
        //Proposal memory p = _proposalList[index];

        // 2. 检查
        //require (uint(p.state) > PROPOSAL_STATE_PROPOSED || block.timestamp >= uint(p.stopTime), "NestVote:!state");
        //if (uint(p.state) == uint(PROPOSAL_STATE_PROPOSED))

        // 3. 更新账本
        UINT storage balance = _stakedLedger[index][msg.sender];
        uint balanceValue = balance.value;
        balance.value = 0;

        // 4. 提案状态取回，需要更新得票量
        if (uint(_proposalList[index].state) == PROPOSAL_STATE_PROPOSED) {
            _proposalList[index].gainValue = uint96(_proposalList[index].gainValue - balanceValue);
        }

        // 4. 退回抵押的nest
        IERC20(_nestTokenAddress).transfer(address(msg.sender), balanceValue);

        emit NIPWithdraw(msg.sender, index, balanceValue);
    }

    // // 撤销投票
    // function revoke(uint index, uint value) override external noContract
    // {
    //     // 1. 加载投票结构
    //     Proposal memory p = _proposalList[index];

    //     // 2. 检查
    //     require(block.timestamp >= uint(p.stopTime) && block.timestamp < uint(p.stopTime), "NestVote:!time");
    //     require(uint(p.state) == 0, "NestVote:!state");

    //     // 3. 更新账本
    //     UINT storage balance = _stakedLedger[index][msg.sender];
    //     uint balanceValue = balance.value;
    //     require(balanceValue >= value, "NestVote:!value"); 
    //     //p.gainValue = uint128(uint(p.gainValue) - value);
    //     balance.value = balanceValue - value;

    //     _proposalList[index].gainValue = uint96(uint(p.gainValue) - value);

    //     // 4. 退回抵押的nest
    //     IERC20(_nestTokenAddress).transfer(address(msg.sender), value);

    //     emit NIPRevoke(msg.sender, index, value);
    // }

    // 执行投票
    function execute(uint index) override external noContract
    {
        Config memory config = _config;

        // 1. 加载投票结构
        Proposal memory p = _proposalList[index];

        // 2. 检查
        require (uint(p.state) == uint(PROPOSAL_STATE_PROPOSED), "NestVote:!state");
        require (block.timestamp >= uint(p.stopTime), "NestVote:!time");
        // 目标地址不能已经拥有治理权限，防止治理权限被覆盖
        address governance = _governance;
        require(!INestGovernance(governance).checkGovernance(p.contractAddress, 0), "NestVote:!governance");

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
        INestGovernance(governance).setGovernance(p.contractAddress, 1);

        // 4. 执行
        _proposalList[index].state = PROPOSAL_STATE_ACCEPTED;
        _proposalList[index].executor = address(msg.sender);
        IVotePropose(p.contractAddress).run();

        // 4. 删除执行权限
        INestGovernance(governance).setGovernance(p.contractAddress, 0);
        
        // 退回nest
        nest.transfer(p.proposer, uint(p.staked));

        emit NIPExecute(msg.sender, index);
    }

    // 取消投票
    function calcel(uint index) override external noContract {
        // 1. 加载投票结构
        Proposal memory p = _proposalList[index];

        // 2. 检查
        require (uint(p.state) == uint(PROPOSAL_STATE_PROPOSED), "NestVote:!state");
        require (block.timestamp >= uint(p.stopTime), "NestVote:!time");

        // 3. 更新状态
        _proposalList[index].state = PROPOSAL_STATE_CANCELLED;

        // 4. 退回抵押的nest
        IERC20(_nestTokenAddress).transfer(p.proposer, uint(p.staked));
    }

    /// @dev 获取投票信息
    /// @param index 投票编号
    /// @return 投票信息结构体
    function getProposeInfo(uint index) override external view returns (ProposalView memory) {
        
        Proposal memory proposal = _proposalList[index];
        return ProposalView(
            //uint index;
            index,
            // 将固定字段和变动字段分开存储，
            /* ========== 固定字段 ========== */
            // 提案简介
            //string brief;
            proposal.brief,
            // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
            //address contractAddress;
            proposal.contractAddress,
            // 投票开始时间
            //uint48 startTime;
            proposal.startTime,
            // 投票截止时间
            //uint48 stopTime;
            proposal.stopTime,
            // 提案者
            //address proposer;
            proposal.proposer,
            // 抵押的nest
            //uint96 staked;
            proposal.staked,
            /* ========== 变动字段 ========== */
            // 获得的投票量
            // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
            //uint96 gainValue;
            proposal.gainValue,
            // 提案状态
            //uint32 state;  // 0: proposed | 1: accepted | 2: cancelled
            proposal.state,
            // 提案执行者
            //address executor;
            proposal.executor
        );
    }

    /// @dev 获取累计投票提案数量
    /// @return 累计投票提案数量
    function getProposeCount() override external view returns (uint) {
        return _proposalList.length;
    }

    /// @dev 分页列出投票提案
    /// @param offset 跳过前面offset条记录
    /// @param count 返回count条记录
    /// @param order 排序方式. 0倒序, 非0正序
    /// @return 投票列表
    function list(uint offset, uint count, uint order) override external view returns (ProposalView[] memory) {
        
        Proposal[] storage proposalList = _proposalList;
        ProposalView[] memory result = new ProposalView[](count);
        Proposal memory proposal;

        // 倒序
        if (order == 0) {

            uint index = proposalList.length - offset;
            uint end = index - count;
            uint i = 0;
            while (index > end) {

                proposal = proposalList[--index];
                result[i++] = ProposalView(
                    //uint index;
                    index,
                    // 将固定字段和变动字段分开存储，
                    /* ========== 固定字段 ========== */

                    // 提案简介
                    //string brief;
                    proposal.brief,

                    // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
                    //address contractAddress;
                    proposal.contractAddress,

                    // 投票开始时间
                    //uint48 startTime;
                    proposal.startTime,

                    // 投票截止时间
                    //uint48 stopTime;
                    proposal.stopTime,

                    // 提案者
                    //address proposer;
                    proposal.proposer,

                    // 抵押的nest
                    //uint96 staked;
                    proposal.staked,

                    /* ========== 变动字段 ========== */
                    // 获得的投票量
                    // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
                    //uint96 gainValue;
                    proposal.gainValue,

                    // 提案状态
                    //uint32 state;  // 0: proposed | 1: accepted | 2: cancelled
                    proposal.state,

                    // 提案执行者
                    //address executor;
                    proposal.executor
                );
            }
        } 
        // 正序
        else {
            
            uint index = offset;
            uint end = index + count;
            uint i = 0;
            while (index < end) {

                proposal = proposalList[index];
                result[i++] = ProposalView(
                    //uint index;
                    index++,
                    // 将固定字段和变动字段分开存储，
                    /* ========== 固定字段 ========== */

                    // 提案简介
                    //string brief;
                    proposal.brief,

                    // 提案通过后，要执行的合约地址(需要实现IVotePropose接口)
                    //address contractAddress;
                    proposal.contractAddress,

                    // 投票开始时间
                    //uint48 startTime;
                    proposal.startTime,

                    // 投票截止时间
                    //uint48 stopTime;
                    proposal.stopTime,

                    // 提案者
                    //address proposer;
                    proposal.proposer,

                    // 抵押的nest
                    //uint96 staked;
                    proposal.staked,

                    /* ========== 变动字段 ========== */
                    // 获得的投票量
                    // uint96可以表示的最大值为79228162514264337593543950335，超过nest总量10000000000 ether，因此可以用uint96表示得票总量
                    //uint96 gainValue;
                    proposal.gainValue,

                    // 提案状态
                    //uint32 state;  // 0: proposed | 1: accepted | 2: cancelled
                    proposal.state,

                    // 提案执行者
                    //address executor;
                    proposal.executor
                );
            }
        }

        return result;
    }
}