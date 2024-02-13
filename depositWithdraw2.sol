// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBUSD {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface ITOKEN {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

import "@openzeppelin/contracts/access/Ownable.sol";

contract DoubleDeposit is Ownable {
    address public feeAddress;
    uint256 public dailyLimitBUSD;
    uint256 public dailyLimitToken;
    uint256 public maxLimitBUSD;
    uint256 public maxLimitToken;
    uint256 public depositFeePercentage; // Fee in percentage (e.g., 5 for 5%)
    uint256 public increaseMaxLimitBUSD; // Amount to increase maxLimitBUSD by

    mapping(address => uint256) public lastWithdrawalTimestamp;
    mapping(address => uint256) public totalWithdrawn;
    mapping(address => uint256) public lifetimeWithdrawnBUSD;
    mapping(address => uint256) public lifetimeWithdrawnToken;

    IBUSD public busdToken;
    ITOKEN public token;

    constructor(address _busdToken, address _token) {
        busdToken = IBUSD(_busdToken);
        token = ITOKEN(_token);
    }

    function depositBUSD(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        uint256 feeAmount = (amount * depositFeePercentage) / 100;

        require(
            busdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        if (feeAmount != 0) {
            require(
                busdToken.transferFrom(address(this), feeAddress, feeAmount),
                "Fee transfer failed"
            );
        }

        maxLimitBUSD += increaseMaxLimitBUSD;
        lifetimeWithdrawnBUSD[msg.sender] += increaseMaxLimitBUSD;
    }

    function depositToken(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        uint256 feeAmount = (amount * depositFeePercentage) / 100;

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        if (feeAmount != 0) {
            require(
                token.transferFrom(address(this), feeAddress, feeAmount),
                "Fee transfer failed"
            );
        }
    }

    function withdrawBUSD(uint256 amount) external {
        require(
            busdToken.balanceOf(address(this)) >= amount,
            "Contract does not have enough balance"
        );
        require(amount <= dailyLimitBUSD, "Exceeds daily withdrawal limit");
        require(
            totalWithdrawn[msg.sender] + amount <= maxLimitBUSD,
            "Exceeds maximum withdrawal limit"
        );
        require(
            block.timestamp - lastWithdrawalTimestamp[msg.sender] >= 1 days,
            "Daily withdrawal limit has not reset yet"
        );

        lastWithdrawalTimestamp[msg.sender] = block.timestamp;
        totalWithdrawn[msg.sender] += amount;

        require(busdToken.transfer(msg.sender, amount), "Transfer failed");
    }

    function withdrawToken(uint256 amount) external {
        require(
            token.balanceOf(address(this)) >= amount,
            "Contract does not have enough balance"
        );
        require(amount <= dailyLimitToken, "Exceeds daily withdrawal limit");
        require(
            totalWithdrawn[msg.sender] + amount <= maxLimitToken,
            "Exceeds maximum withdrawal limit"
        );
        require(
            block.timestamp - lastWithdrawalTimestamp[msg.sender] >= 1 days,
            "Daily withdrawal limit has not reset yet"
        );

        lastWithdrawalTimestamp[msg.sender] = block.timestamp;
        totalWithdrawn[msg.sender] += amount;

        require(token.transfer(msg.sender, amount), "Transfer failed");
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

    function setIncreaseMaxLimitBUSD(uint256 _increaseAmount)
        external
        onlyOwner
    {
        increaseMaxLimitBUSD = _increaseAmount;
    }
}
