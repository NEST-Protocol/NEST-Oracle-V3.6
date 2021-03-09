// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/IERC20.sol";
import "./lib/SafeMath.sol";
import "./interface/INestLedger.sol";
import "./interface/INestQuery.sol";
import "./interface/INestRedeeming.sol";
import "./NestBase.sol";

/// @dev The contract is for redeeming nest token and getting ETH in return
contract NestRedeeming is NestBase, INestRedeeming {

    constructor(address nestTokenAddress) {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    /// @dev 治理地址信息
    struct GovernanceInfo {
        address addr;
        uint96 flag;
    }

    /// @dev 回购信息
    struct RedeemInfo {
        // 已经消耗的回购额度
        // block.number * quotaPerBlock - quota
        uint128 quota;
        // 回购状态，1表示正在回购
        uint8 state;
    }

    mapping(address=>RedeemInfo) redeemLedger;

    address immutable NEST_TOKEN_ADDRESS;
    address _nestLedgerAddress;
    address _nestQueryAddress;
    
    /// @dev 在实现合约中重写，用于加载其他的合约地址。重写时请条用super.update(nestGovernanceAddress)，并且重写方法不要加上onlyGovernance
    /// @param nestGovernanceAddress 治理合约地址
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);

        (
            , //address nestTokenAddress,
            _nestLedgerAddress, //address nestLedgerAddress,
              
            , //address nestMiningAddress,
            , //address nestPriceFacadeAddress,
              
            , //address nestVoteAddress,
            _nestQueryAddress, //address nestQueryAddress,
            , //address nnIncomeAddress,
              //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev Redeem ntokens for ethers
    /// @notice Ethfee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount  The amount of ntoken
    function redeem(address ntokenAddress, uint amount) override external payable {
        //require(ntokenAddress == address(0) && amount == 0 && false, "NestDAO:not implement");

        require(msg.value == 0.01 ether, "NestDAO:!fee");
        RedeemInfo storage redeemInfo = redeemLedger[ntokenAddress];
        if (uint(redeemInfo.state) == 0) {
            require(IERC20(ntokenAddress).totalSupply() >= 5000000 ether, "NestDAO:!totalSupply");
            redeemInfo.state = 1;
        }

        (
            /* uint latestPriceBlockNumber */, 
            uint latestPriceValue,
            /* uint triggeredPriceBlockNumber */,
            /* uint triggeredPriceValue */,
            uint triggeredAvgPrice,
            /* uint triggeredSigma */
        ) = INestQuery(_nestQueryAddress).latestPriceAndTriggeredPriceInfo(ntokenAddress);

        uint value = amount * 1 ether / latestPriceValue;
        //uint prevQuota = redeemInfo.quota;
        //uint quota = _quotaOf(prevQuota, ntokenAddress);
        uint quota;
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            quota = block.number * 1000 ether - redeemInfo.quota;
            if (quota > 300000 ether) {
                quota = 300000 ether;
            }
            redeemInfo.quota = uint128(block.number * 1000 ether - (quota - amount));
            //nestLedger = nestLedger + msg.value - value;
        } else {
            quota = block.number * 10 ether - redeemInfo.quota;
            if (quota > 3000 ether) {
                quota = 3000 ether;
            }
            redeemInfo.quota = uint128(block.number * 10 ether - (quota - amount));
            //UINT storage balance = ntokenLedger[ntokenAddress];
            //balance.value = balance.value + msg.value - value;
        }
        require(quota >= amount, "NestDAO:!amount");
        require(latestPriceValue <= triggeredAvgPrice * 105 / 100 && latestPriceValue >= triggeredAvgPrice * 95 / 100, "NestDAO:!price");
        TransferHelper.safeTransferFrom(ntokenAddress, msg.sender, address(this), amount);
        //payable(msg.sender).transfer(value);
        
        // TODO: 考虑改为一个结算方法（settle）
        INestLedger(_nestLedgerAddress).addReward { value: msg.value } (ntokenAddress);
        INestLedger(_nestLedgerAddress).pay(ntokenAddress, address(0), msg.sender, value);
    }

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) override public view returns (uint) {

        RedeemInfo storage redeemInfo = redeemLedger[ntokenAddress];
        if (uint(redeemInfo.state) == 0) {
            if (IERC20(ntokenAddress).totalSupply() < 5000000 ether) return 0;
        }

        uint quota;
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            quota = block.number * 1000 ether - quota;
            if (quota > 300000 ether) {
                quota = 300000 ether;
            }
        } else {
            quota = block.number * 10 ether - quota;
            if (quota > 3000 ether) {
                quota = 3000 ether;
            }
        } 

        return quota;
    }
}