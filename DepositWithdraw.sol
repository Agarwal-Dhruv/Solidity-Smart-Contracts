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

contract DoubleDeposit {
    address public owner;
    address public feeAddress;
    uint256 public dailyLimitBUSD; 
    uint256 public dailyLimitToken;
    uint256 public maxLimitBUSD;
    uint256 public maxLimitToken;
    uint256 public depositFeePercentage; // Fee in percentage (e.g., 5 for 5%)

    mapping(address => uint256) public lastWithdrawalTimestamp;
    mapping(address => uint256) public totalWithdrawn;

    IBUSD public busdToken;
    ITOKEN public token;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _busdToken, address _token) {
        owner = msg.sender;
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
        require(amount <= dailyLimitBUSD, "Exceeds daily withdrawal limit");
        require(totalWithdrawn[msg.sender] + amount <= maxLimitBUSD, "Exceeds maximum withdrawal limit");
        
        // Check if 24 hours have passed since the last withdrawal
        require(block.timestamp - lastWithdrawalTimestamp[msg.sender] >= 1 days, "Daily withdrawal limit has not reset yet");
        
        // Update withdrawal records
        lastWithdrawalTimestamp[msg.sender] = block.timestamp;
        totalWithdrawn[msg.sender] += amount;

        // Transfer BUSD back to the sender
        require(busdToken.transfer(msg.sender, amount), "Transfer failed");
    }

      function withdrawToken(uint256 amount) external {
        
        // Check contract's BUSD balance.
        require(token.balanceOf(address(this)) >= amount, "Contract does not have enough balance");
        // // User can withdraw double the amount he has deposited.
        // require(amount <= deposits[msg.sender] * 2, "Withdrawal amount exceeds limit");
        require(amount <= dailyLimitToken, "Exceeds daily withdrawal limit");
        require(totalWithdrawn[msg.sender] + amount <= maxLimitBUSD, "Exceeds maximum withdrawal limit");
        
        // Check if 24 hours have passed since the last withdrawal
        require(block.timestamp - lastWithdrawalTimestamp[msg.sender] >= 1 days, "Daily withdrawal limit has not reset yet");
        
        // Update withdrawal records
        lastWithdrawalTimestamp[msg.sender] = block.timestamp;
        totalWithdrawn[msg.sender] += amount;

        // Transfer BUSD back to the sender
        require(busdToken.transfer(msg.sender, amount), "Transfer failed");
    }


    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = newFeeAddress;
    }

    function setDepositFeePercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 100, "Percentage should be 0-100");
        depositFeePercentage = newPercentage;
    }

    function setDailyLimitBUSD(uint256 _dailyLimit) external onlyOwner {
        dailyLimitBUSD = _dailyLimit;
    }

    function setDailyLimitToken(uint256 _dailyLimit) external onlyOwner {
        dailyLimitToken = _dailyLimit;
    }
    
    function setMaxLimitBUSD(uint256 _maxLimit) external onlyOwner {
        maxLimitBUSD = _maxLimit;
    }

    function setMaxLimitToken(uint256 _maxLimit) external onlyOwner {
        maxLimitToken = _maxLimit;
    }
}
