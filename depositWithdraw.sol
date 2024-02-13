// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBUSD {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ITOKEN {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

import "@openzeppelin/contracts/access/Ownable.sol";

contract DoubleDeposit is Ownable{
    address public feeAddress;
    uint256 public dailyWithdrawalLimitBUSD; 
    uint256 public dailyWithdrawalLimitToken;
    uint256 public withdrawalCooldownBUSD;
    uint256 public withdrawalCooldownToken;
    uint256 public maxWithdrawalLimitBUSD;
    uint256 public maxWithdrawalLimitToken;
    uint256 public depositFeePercentage; // Fee in percentage (e.g., 5 for 5%)

    

    mapping(address => uint256) public lastWithdrawalTimestampBUSD;
    mapping(address => uint256) public lastWithdrawalTimestampToken;
    mapping(address => uint256) public totalWithdrawn;


    mapping(address => uint256) public lifetimeWithdrawnBUSD;
    mapping(address => uint256) public lifetimeWithdrawnToken;

    IBUSD public busdToken;
    ITOKEN public token;

    modifier canWithdrawBUSD(address _user, uint256 _amount) {
        require(
            block.timestamp >= lastWithdrawalTimestampBUSD[_user] + withdrawalCooldownBUSD,
            "Withdrawal cooldown period has not passed"
        );

        require(
            lifetimeWithdrawnBUSD[_user] + _amount <= maxWithdrawalLimitBUSD,
            "Exceeds lifetime withdrawal limit"
        );

        require(
            getDailyWithdrawalBUSD(_user) + _amount <= dailyWithdrawalLimitBUSD,
            "Exceeds daily withdrawal limit"
        );

        _;
    }

    modifier canWithdrawToken(address _user, uint256 _amount) {
        require(
            block.timestamp >= lastWithdrawalTimestampToken[_user] + withdrawalCooldownToken,
            "Withdrawal cooldown period has not passed"
        );

        require(
            lifetimeWithdrawnToken[_user] + _amount <= maxWithdrawalLimitToken,
            "Exceeds lifetime withdrawal limit"
        );

        require(
            getDailyWithdrawalToken(_user) + _amount <= dailyWithdrawalLimitToken,
            "Exceeds daily withdrawal limit"
        );

        _;
    }
    

    constructor(address _busdToken, address _token) {
        busdToken = IBUSD(_busdToken);
        token = ITOKEN(_token);
    }  

    function depositBUSD(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate deposit fee
        uint256 feeAmount = (amount * depositFeePercentage) / 100;

        // Transfer BUSD from the sender to this contract
        require(busdToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

         // Transfer the fee to the fee address
        if(feeAmount != 0){
        require(busdToken.transferFrom(address(this), feeAddress, feeAmount), "Fee transfer failed");
        }
    }

    function depositToken(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate deposit fee
        uint256 feeAmount = (amount * depositFeePercentage) / 100;

        // Transfer BUSD from the sender to this contract
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

         // Transfer the fee to the fee address
        if(feeAmount != 0){
        require(token.transferFrom(address(this), feeAddress, feeAmount), "Fee transfer failed");
        }
    }

    function withdrawBUSD(uint256 amount) external {
        
        // Check contract's BUSD balance.
        require(busdToken.balanceOf(address(this)) >= amount, "Contract does not have enough balance");
        // // User can withdraw double the amount he has deposited.
        // require(amount <= deposits[msg.sender] * 2, "Withdrawal amount exceeds limit");
        require(amount <= dailyWithdrawalLimitBUSD, "Exceeds daily withdrawal limit");
        require(totalWithdrawn[msg.sender] + amount <= maxWithdrawalLimitBUSD, "Exceeds maximum withdrawal limit");
        
        // Check if 24 hours have passed since the last withdrawal
        require(block.timestamp - lastWithdrawalTimestampBUSD[msg.sender] >= 1 days, "Daily withdrawal limit has not reset yet");
        
        // Update withdrawal records
        lastWithdrawalTimestampBUSD[msg.sender] = block.timestamp;
        totalWithdrawn[msg.sender] += amount;

        // Transfer BUSD back to the sender
        require(busdToken.transfer(msg.sender, amount), "Transfer failed");
    }

      function withdrawToken(uint256 amount) external {
        
        // Check contract's BUSD balance.
        require(token.balanceOf(address(this)) >= amount, "Contract does not have enough balance");
        // // User can withdraw double the amount he has deposited.
        // require(amount <= deposits[msg.sender] * 2, "Withdrawal amount exceeds limit");
        require(amount <= dailyWithdrawalLimitToken, "Exceeds daily withdrawal limit");
        require(totalWithdrawn[msg.sender] + amount <= maxWithdrawalLimitToken, "Exceeds maximum withdrawal limit");
        
        // Check if 24 hours have passed since the last withdrawal
        require(block.timestamp - lastWithdrawalTimestampToken[msg.sender] >= 1 days, "Daily withdrawal limit has not reset yet");
        
        // Update withdrawal records
        lastWithdrawalTimestampToken[msg.sender] = block.timestamp;
        totalWithdrawn[msg.sender] += amount;

        // Transfer BUSD back to the sender
        require(busdToken.transfer(msg.sender, amount), "Transfer failed");
    }

    function setFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = newFeeAddress;
    }

    function setDepositFeePercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 100, "Percentage should be 0-100");
        depositFeePercentage = newPercentage;
    }

    function setDailyLimitBUSD(uint256 _dailyLimit) external onlyOwner {
        dailyWithdrawalLimitBUSD = _dailyLimit;
    }

    function setDailyLimitToken(uint256 _dailyLimit) external onlyOwner {
        dailyWithdrawalLimitToken = _dailyLimit;
    }
    
    function setMaxLimitBUSD(uint256 _maxLimit) external onlyOwner {
        maxWithdrawalLimitBUSD = _maxLimit;
    }

    function setMaxLimitToken(uint256 _maxLimit) external onlyOwner {
        maxWithdrawalLimitToken = _maxLimit;
    }

    function getDailyWithdrawalBUSD(address _user) internal view returns (uint256) {
        if (block.timestamp >= lastWithdrawalTimestampBUSD[_user] + 1 days) {
            return 0;
        }
        return lifetimeWithdrawnBUSD[_user];
    }

    function getDailyWithdrawalToken(address _user) internal view returns (uint256) {
        if (block.timestamp >= lastWithdrawalTimestampToken[_user] + 1 days) {
            return 0;
        }
        return lifetimeWithdrawnBUSD[_user];
    }
}
