# INestVote

## 1. Interface Description
   This interface defines the methods for voting

## 2. Method Description

### 2.1. Modify configuration

```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;
```
```javascript
    /// @dev Voting contract configuration structure
    struct Config {

        // Proportion of votes required (10000 based). 5100
        uint32 acceptance;

        // Voting time cycle (seconds). 5 * 86400
        uint64 voteDuration;

        // The number of nest votes need to be staked. 100000 nest
        uint96 proposalStaking;
    }
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
```

### 2.3. Initiate a voting proposal

```javascript
    /// @dev Initiate a voting proposal
    /// @param contractAddress The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
    /// @param brief Brief of this propose
    function propose(address contractAddress, string memory brief) external;
```
    Note: This method will triggers the NIPSubmitted event, See also 3.1.

### 2.4. vote

```javascript
    /// @dev vote
    /// @param index Index of proposal
    /// @param value Amount of nest to vote
    function vote(uint index, uint value) external;
```
    Note: This method will triggers the NIPVote event, See also 3.2.
    
### 2.5. Withdraw the nest of the vote

```javascript
    /// @dev Withdraw the nest of the vote. If the target vote is in the voting state, the corresponding number of votes will be cancelled
    /// @param index Index of the proposal
    function withdraw(uint index) external;
```

### 2.6. Execute the proposal

```javascript
    /// @dev Execute the proposal
    /// @param index Index of the proposal
    function execute(uint index) external;
```
    Note: This method will triggers the NIPExecute event, See also 3.3.

### 2.7. Cancel the proposal

```javascript
    /// @dev Cancel the proposal
    /// @param index Index of the proposal
    function cancel(uint index) external;
```

### 2.8. Get proposal information

```javascript
    /// @dev Get proposal information
    /// @param index Index of the proposal
    /// @return Proposal information
    function getProposeInfo(uint index) external view returns (ProposalView memory);
```
```javascript
    // Proposal
    struct ProposalView {

        // Index of proposal
        uint index;
        
        // The immutable field and the variable field are stored separately
        /* ========== Immutable field ========== */

        // Brief of this proposal
        string brief;

        // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
        address contractAddress;

        // Voting start time
        uint48 startTime;

        // Voting stop time
        uint48 stopTime;

        // Proposer
        address proposer;

        // Staked nest amount
        uint96 staked;

        /* ========== Mutable field ========== */

        // Gained value
        // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the total 
        // number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of votes
        uint96 gainValue;

        // The state of this proposal
        uint32 state;  // 0: proposed | 1: accepted | 2: cancelled

        // The executor of this proposal
        address executor;

        // The execution time (if any, such as block number or time stamp) is placed in the contract and is limited by the contract itself

        // Circulation of nest
        uint96 nestCirculation;
    }
```

### 2.9. Get the cumulative number of voting proposals

```javascript
    /// @dev Get the cumulative number of voting proposals
    /// @return The cumulative number of voting proposals
    function getProposeCount() external view returns (uint);
```

### 2.10. List proposals by page

```javascript
    /// @dev List proposals by page
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price proposals
    function list(uint offset, uint count, uint order) external view returns (ProposalView[] memory);
```

### 2.11. Get Circulation of nest

```javascript
    /// @dev Get Circulation of nest
    /// @return Circulation of nest
    function getNestCirculation() external view returns (uint);
```

## 3. Event Description

### 3.1. Event of submitting a voting proposal

```javascript 
    /// @dev Event of submitting a voting proposal
    /// @param proposer Proposer address
    /// @param contractAddress The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
    /// @param index Index of proposal
    event NIPSubmitted(address proposer, address contractAddress, uint index);
```

### 3.2. Voting event

```javascript 
    /// @dev Voting event
    /// @param voter Voter address
    /// @param index Index of proposal
    /// @param amount Amount of nest to vote
    event NIPVote(address voter, uint index, uint amount);
```

### 3.3. Proposal execute event

```javascript 
    /// @dev Proposal execute event
    /// @param executor Executor address
    /// @param index Index of proposal
    event NIPExecute(address executor, uint index);
```
