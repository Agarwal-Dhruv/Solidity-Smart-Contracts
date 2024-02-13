// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBUSD {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface ITOKEN {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
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
    mapping(address => uint256) public lifetimeWithdrawnBUSD;
    mapping(address => uint256) public lifetimeWithdrawnToken;
    mapping(address => uint256) public dailyWithdrawalBUSD;
    mapping(address => uint256) public dailyWithdrawalToken;

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

    modifier canWithdrawBUSD(address _user, uint256 _amount) {
        require(
            block.timestamp >= lastWithdrawalTimestamp[_user] + 1 days,
            "Withdrawal cooldown period has not passed"
        );

        require(
            lifetimeWithdrawnBUSD[_user] + _amount <= maxLimitBUSD,
            "Exceeds lifetime withdrawal limit"
        );

        require(
            getDailyWithdrawalBUSD(_user) + _amount <= dailyLimitBUSD,
            "Exceeds daily withdrawal limit"
        );

        _;
    }

    modifier canWithdrawToken(address _user, uint256 _amount) {
        require(
            block.timestamp >= lastWithdrawalTimestamp[_user] + 1 days,
            "Withdrawal cooldown period has not passed"
        );

        require(
            lifetimeWithdrawnToken[_user] + _amount <= maxLimitToken,
            "Exceeds lifetime withdrawal limit"
        );

        require(
            getDailyWithdrawalToken(_user) + _amount <= dailyLimitToken,
            "Exceeds daily withdrawal limit"
        );

        _;
    }

    function depositBUSD(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Calculate deposit fee
        uint256 feeAmount = (amount * depositFeePercentage) / 100;

        // Transfer BUSD from the sender to this contract
        require(
            busdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        // Transfer the fee to the fee address
        if (feeAmount != 0) {
            require(
                busdToken.transferFrom(address(this), feeAddress, feeAmount),
                "Fee transfer failed"
            );
        }

        // Increase the maximum withdrawal limit for BUSD
        maxLimitBUSD += (amount * 2);
    }

    function depositToken(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Calculate deposit fee
        uint256 feeAmount = (amount * depositFeePercentage) / 100;

        // Transfer tokens from the sender to this contract
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        // Transfer the fee to the fee address
        if (feeAmount != 0) {
            require(
                token.transferFrom(address(this), feeAddress, feeAmount),
                "Fee transfer failed"
            );
        }
    }

    function withdrawBUSD(
        uint256 amount
    ) external canWithdrawBUSD(msg.sender, amount) {
        // Check contract's BUSD balance.
        require(
            busdToken.balanceOf(address(this)) >= amount,
            "Contract does not have enough balance"
        );

        // Update withdrawal records
        lastWithdrawalTimestamp[msg.sender] = block.timestamp;
        lifetimeWithdrawnBUSD[msg.sender] += amount;
        dailyWithdrawalBUSD[msg.sender] += amount;

        // Transfer BUSD back to the sender
        require(busdToken.transfer(msg.sender, amount), "Transfer failed");
    }

    function withdrawToken(
        uint256 amount
    ) external canWithdrawToken(msg.sender, amount) {
        // Check contract's token balance.
        require(
            token.balanceOf(address(this)) >= amount,
            "Contract does not have enough balance"
        );

        // Update withdrawal records
        lastWithdrawalTimestamp[msg.sender] = block.timestamp;
        lifetimeWithdrawnToken[msg.sender] += amount;
        dailyWithdrawalToken[msg.sender] += amount;

        // Transfer tokens back to the sender
        require(token.transfer(msg.sender, amount), "Transfer failed");
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

    function getDailyWithdrawalBUSD(
        address _user
    ) internal view returns (uint256) {
        if (block.timestamp >= lastWithdrawalTimestamp[_user] + 1 days) {
            return 0;
        }
        return dailyWithdrawalBUSD[_user];
    }

    function getDailyWithdrawalToken(
        address _user
    ) internal view returns (uint256) {
        if (block.timestamp >= lastWithdrawalTimestamp[_user] + 1 days) {
            return 0;
        }
        return dailyWithdrawalToken[_user];
    }
}
