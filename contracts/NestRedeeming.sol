// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./lib/IERC20.sol";
import "./interface/INestLedger.sol";
import "./interface/INestPriceFacade.sol";
import "./interface/INestRedeeming.sol";
import "./NestBase.sol";

/// @dev The contract is for redeeming nest token and getting ETH in return
contract NestRedeeming is NestBase, INestRedeeming {

    constructor(address nestTokenAddress) {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    /// @dev Governance information
    struct GovernanceInfo {
        address addr;
        uint96 flag;
    }

    /// @dev Redeeming information
    struct RedeemInfo {
        
        // Redeem quota consumed
        // block.number * quotaPerBlock - quota
        uint128 quota;

        // Redeem threshold by circulation of ntoken, when this value equal to config.activeThreshold, redeeming is enabled without checking the circulation of the ntoken
        // When config.activeThreshold modified, it will check whether repo is enabled again according to the circulation
        uint32 threshold;
    }

    Config _config;
    mapping(address=>RedeemInfo) redeemLedger;
    address _nestLedgerAddress;
    address _nestPriceFacadeAddress;
    address immutable NEST_TOKEN_ADDRESS;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implemention contract address
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);

        (
            //address nestTokenAddress
            ,
            //address nestNodeAddress
            ,
            //address nestLedgerAddress
            _nestLedgerAddress, 
            //address nestMiningAddress
            ,
            //address ntokenMiningAddress
            ,
            //address nestPriceFacadeAddress
            _nestPriceFacadeAddress, 
            //address nestVoteAddress
            ,
            //address nestQueryAddress
            , 
            //address nnIncomeAddress
            ,
            //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) override external onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    receive() payable external {
    }

    /// @dev Redeem ntokens for ethers
    /// @notice Ethfee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount The amount of ntoken
    function redeem(address ntokenAddress, uint amount) override external payable {
        
        // 1. Load configuration
        Config memory config = _config;

        // 2. Check redeeming stat
        RedeemInfo storage redeemInfo = redeemLedger[ntokenAddress];
        RedeemInfo memory ri = redeemInfo;
        if (ri.threshold != config.activeThreshold) {
            // Since nest has started redeeming and has a large circulation, we will not check its circulation separately here
            require(IERC20(ntokenAddress).totalSupply() >= uint(config.activeThreshold) * 10000 ether, "NestRedeeming:!totalSupply");
            redeemInfo.threshold = config.activeThreshold;
        }

        // 3. Query price
        // Record the current balance, used to check whether there is a call price when the return
        uint balance = address(this).balance;
        (
            /* uint latestPriceBlockNumber */, 
            uint latestPriceValue,
            /* uint triggeredPriceBlockNumber */,
            /* uint triggeredPriceValue */,
            uint triggeredAvgPrice,
            /* uint triggeredSigma */
        ) = INestPriceFacade(_nestPriceFacadeAddress).latestPriceAndTriggeredPriceInfo { value: msg.value } (ntokenAddress);
        // Calculate return quantity
        balance = address(this).balance - (balance - msg.value);
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }

        // 4. Calculate the number of eth that can be exchanged for redeem
        uint value = amount * 1 ether / latestPriceValue;
        uint quota;

        // 5. Calculation of redeem quota
        // nest redeeming quota
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            quota = block.number * uint(config.nestPerBlock) * 1 ether - ri.quota;
            if (quota > uint(config.nestLimit) * 1 ether) {
                quota = uint(config.nestLimit) * 1 ether;
            }
            redeemInfo.quota = uint128(block.number * uint(config.nestPerBlock) * 1 ether - (quota - amount));
        } 
        // ntoken redeeming quota
        else {
            quota = block.number * uint(config.ntokenPerBlock) * 1 ether - ri.quota;
            if (quota > uint(config.ntokenLimit) * 1 ether) {
                quota = uint(config.ntokenLimit) * 1 ether;
            }
            redeemInfo.quota = uint128(block.number * uint(config.ntokenPerBlock) * 1 ether - (quota - amount));
        }

        // 6. Check the redeeming amount and price deviation
        // This check is not required
        // require(quota >= amount, "NestDAO:!amount");
        require(
            latestPriceValue <= triggeredAvgPrice * (10000 + uint(config.priceDeviationLimit)) / 10000 && 
            latestPriceValue >= triggeredAvgPrice * (10000 - uint(config.priceDeviationLimit)) / 10000, "NestRedeeming:!price");
        
        // 7. Ntoken transferred to redeem
        address nestLedgerAddress = _nestLedgerAddress;
        TransferHelper.safeTransferFrom(ntokenAddress, msg.sender, address(nestLedgerAddress), amount);
        //payable(msg.sender).transfer(value);
        
        // 8. Settlement
        // If a token is not a real token, it should also have no funds in the account book and cannot complete the settlement. 
        // Therefore, it is no longer necessary to check whether the token is a legal token
        INestLedger(nestLedgerAddress).pay(ntokenAddress, address(0), msg.sender, value);
    }

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) override public view returns (uint) {

        // 1. Load configuration
        Config memory config = _config;

        // 2. Check redeem state
        RedeemInfo storage redeemInfo = redeemLedger[ntokenAddress];
        RedeemInfo memory ri = redeemInfo;
        if (ri.threshold != config.activeThreshold) {
            // Since nest has started redeeming and has a large circulation, we will not check its circulation separately here
            if (IERC20(ntokenAddress).totalSupply() < uint(config.activeThreshold) * 10000 ether) return 0;
        }

        // 3. Calculation of redeem quota
        uint quota;
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            quota = block.number * uint(config.nestPerBlock) * 1 ether - ri.quota;
            if (quota > uint(config.nestLimit) * 1 ether) {
                quota = uint(config.nestLimit) * 1 ether;
            }
        } else {
            quota = block.number * uint(config.ntokenPerBlock) * 1 ether - ri.quota;
            if (quota > uint(config.ntokenLimit) * 1 ether) {
                quota = uint(config.ntokenLimit) * 1 ether;
            }
        } 

        return quota;
    }
}