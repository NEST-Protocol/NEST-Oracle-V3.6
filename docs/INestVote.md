# NEST投票合约

## 1. 合约说明
    NEST投票合约。

## 2. 接口说明

### 2.1. 发起投票

    /// @dev 发起投票
    /// @param contractAddress 投票执行合约地址(需要实现IVotePropose接口)
    /// @param brief 投票内容描述
    function propose(address contractAddress, string memory brief) external;

    投票合约需要实现如下接口
    /// @dev 投票合约需要实现的接口
    interface IVotePropose {

        /// @dev 投票通过后需要执行的代码
        function run() external;
    }

### 2.2. 进行投票

    /// @dev 进行投票
    /// @param proposeIndex 投票编号
    /// @param value 投票的权重
    function vote(uint proposeIndex, uint value) external;

### 2.3. 撤销投票

    /// @dev 撤销投票
    /// @param proposeIndex 投票编号
    /// @param value 投票的权重
    function revoke(uint proposeIndex, uint value) external;

### 2.4. 执行投票

    /// @dev 执行投票
    /// @param proposeIndex 投票编号
    function execute(uint proposeIndex) external;

### 2.5. 取回投票的nest

    /// @dev 取回投票的nest
    /// @param proposeIndex 投票编号
    function withdraw(uint proposeIndex) external;

### 2.6. 已经质押的nest数量

    /// @dev 已经质押的nest数量
    /// @param proposeIndex 投票编号
    function stakedNestNum(uint proposeIndex) external view returns (uint);

### 2.7. 获取投票信息

    /// @dev 获取投票信息
    /// @param proposeIndex 投票编号
    /// @return 投票信息结构体
    function getProposeInfo(uint proposeIndex) external view returns (Proposal memory);

    // 提案
    struct Proposal {
        // 提案描述
        string description;
        uint32 state;  // 0: proposed | 1: accepted | 2: rejected
        uint32 startTime;
        uint32 endTime;
        uint64 voters;
        uint128 stakedNestAmount;
        address contractAddr;
        address proposer;
        address executor;
    }
