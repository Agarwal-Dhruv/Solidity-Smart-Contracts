contract StakeInitializable is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Info of each staking pool.
    struct PoolInfo {
        // How man allocation points are assigned to this pool
        uint256 allocPoint;
        // Last time number when reward token's distribution occured.
        uint256 lastRewardTime;
        // Accrued reward token per staked token.
        uint256 accERC20PerShare;
        // Fixed APY, if staking program is providing fixed APY.
        uint256 fixedAPY;
        // Penalty amount for early withdrawal.
        uint256 penalty;
        // Total amount of staked tokens deposited in this pool.
        uint256 totalDeposits;
    }

    // Info of each participating user.
    struct UserInfo {
        // Number of staked tokens deposited.
        uint256 amount;
        // numebr of reward tokens user is not entitled to receive.
        uint256 rewardDebt;
        // Time when users last deposited staked tokens.
        uint256 depositTime;
        // Before this time, any withdrawal will result in penalty.
        uint256 withdrawTime;
    }

    // Address of the stake factory.
    address public STAKE_FACTORY;
    // Whether this staking program is initialized.
    bool public _isInitialized;
    // Whether this staking program has time-bound locking.
    bool public _isTimeBoundLock = true;
    // Whether this staking program charges penalty on early withdrawal.
    bool public _isPenaltyCharged = true;
    // Whether this staking program has fixed APY.
    bool public _isFixedAPY;
    // Wheter this staking program allows early withdrawal on stakes.
    bool public _isEarlyWithdrawAllowed = true;
    // The staked token.
    IERC20 public _stakedToken;
    // The reward token.
    IERC20 public _rewardToken;
    // Reward tokens created per second.
    uint256 public _rewardPerSecond;
    // Time when the staking program starts generating rewards.
    uint256 public _startTime;
    // Time when the staking program ends.
    uint256 public _endTime;
    // Staking time period in days.
    uint256[] public _timePeriods;
    // Penalty percentages for early withdrawal.
    uint256[] public _penalties;
    // Fixed APY percentages, in case the staking program is providing Fixed APY.
    uint256[] public _fixedAPYs;
    // Sum of allocation points of every staking pool.
    uint256 public _totalAllocPoints;
    // Total reward tokens paid out in rewards.
    uint256 public _paidOut;
    // Total reward tokens added to the program as liquidity.
    uint256 public _totalFundedRewards;
    // Stake Fee Percent.
    uint256 public _stakeFeePercent;
    // Total fee collected in staked tokens.
    uint256 public _totalFeeCollected;
    // Fee collector address.
    address public _feeCollector;
    // The precision factor.
    uint256 public PRECISION_FACTOR;
    // Penalty and Staking Fee denomiator.
    uint256 public FEE_DENOMINATOR = 100;
    // Reward token decimals.
    uint256 public _decimalsOfRewardToken;
    // Info of each 'PoolInfo' mapped with their time periods (in days).
    mapping(uint256 => PoolInfo) public _poolInfo;
    // Info of each 'UserInfo' mapped with their wallet address for a given staking pool.
    mapping(address => mapping(uint256 => UserInfo)) public _userInfo;

    event StakingProgramInitialized(
        IERC20 indexed stakedToken,
        IERC20 indexed rewardToken,
        uint256 rewardPerSecond,
        uint256 startTime,
        uint256 endTime,
        uint256[] timePeriods,
        uint256[] penalties,
        uint256[] fixedAPYs,
        address admin,
        bool isTimeBoundLock,
        bool isPenaltyCharged,
        bool isFixedAPY
    );
    event Deposit(
        address indexed user,
        uint256 indexed period,
        uint256 indexed amount,
        uint256 depositTime,
        uint256 withdrawTime
    );
    event Withdraw(
        address indexed user,
        uint256 indexed period,
        uint256 indexed withdrawalAmount,
        uint256 rewardAmount,
        uint256 withdrawTime
    );
    event Claim(
        address indexed user,
        uint256 indexed period,
        uint256 rewardAmount,
        uint256 withdrawTime
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed period,
        uint256 indexed withdrawalAmount
    );
    event StakeFeePercentSet(uint256 indexed stakeFeePercent);
    event IsEarlyWithdrawAllowedSet(bool indexed isEarlyWithdrawAllowed);
    event FeeCollectorSet(address indexed feeCollector);
    event WithdrawFees(uint256 indexed totalFeeCollected);
    event FundLiquidity(uint256 indexed fundAmount);
    event WithdrawLiquidity(uint256 indexed withdrawAmount);

    // Check if the entered 'period_' exists / is valid
    modifier ValidatePeriod(uint256 period_) {
        if (_isTimeBoundLock) {
            require(
                _searchArray(_timePeriods, period_),
                "Invalid staking period."
            );
        } else {
            require(
                period_ == 0,
                "Invalid staking period, enter zero beacuse there is no time-bound locking"
            );
        }
        _;
    }

    /**
     * @notice Constructor
     */
    constructor() {
        STAKE_FACTORY = msg.sender;
    }

    /**
     * @notice Initialize the staking program
     *
     */
    function initialize(
        IERC20 stakedToken_,
        IERC20 rewardToken_,
        uint256 rewardPerSecond_,
        uint256 startTime_,
        uint256 endTime_,
        uint256[] memory timePeriods_,
        uint256[] memory penalties_,
        uint256[] memory fixedAPYs_,
        address admin_
    ) external {
        require(!_isInitialized, "Program already initialized.");
        require(
            msg.sender == STAKE_FACTORY,
            "Program can be initialized only by the factory."
        );
        require(
            stakedToken_ != IERC20(address(0)) &&
                rewardToken_ != IERC20(address(0)),
            "Staked token and reward token cannot be zero address"
        );
        require(
            startTime_ >= block.timestamp,
            "Start time cannot be less than the current time"
        );
        require(
            endTime_ > startTime_,
            "Staking program end time cannot be less than start time"
        );
        require(
            timePeriods_.length == penalties_.length,
            "Time period and penalty lengths must be equal"
        );
        require(admin_ != address(0), "Admin cannot be zero address.");

        // If this staking program has only one time-bound locking pool, eg. 30 Day time-period.
        if (timePeriods_.length == 1) {
            require(
                timePeriods_[0] != 0,
                "Time Period cannot be zero day. Enter an empty array to avoid time-boud locking."
            );
        }

        // If this staking program provides fixed APYs.
        if (fixedAPYs_.length > 0) {
            if (timePeriods_.length > 0) {
                // This means that the staking program has time-bound locking.
                // For every time-period, their must be a fixed APY value.
                require(
                    fixedAPYs_.length == timePeriods_.length,
                    "Every time period must have its respective fixed APY."
                );
            }
            _isFixedAPY = true;
            _fixedAPYs = fixedAPYs_;
        }

        // If this staking program does not have time-bound locking.
        if (timePeriods_.length == 0) {
            _isTimeBoundLock = false;
            _isPenaltyCharged = false;
        }

        _decimalsOfRewardToken = uint256(
            IERC20Metadata(address(rewardToken_)).decimals()
        );
        require(_decimalsOfRewardToken < 30, "Must be less than 30");

        // Make this staking program initialized.
        _isInitialized = true;
        _stakedToken = stakedToken_;
        _rewardToken = rewardToken_;
        _rewardPerSecond = rewardPerSecond_;
        _startTime = startTime_;
        _endTime = endTime_;
        _timePeriods = timePeriods_;
        _penalties = penalties_;
        PRECISION_FACTOR = uint256(
            10 ** (uint256(30) - _decimalsOfRewardToken)
        );

        // Create either time-bound locking pools or a single zero-day-lock staking pool.
        if (_isTimeBoundLock) {
            uint256 totalPools = _timePeriods.length;
            if (_isFixedAPY) {
                _totalAllocPoints = 1;
            } else {
                _totalAllocPoints = (totalPools * (totalPools + 1)) / 2; // n(n+1)/2 => Sum of an A.P. with a = d = 1
            }

            for (uint256 i = 0; i < totalPools; i++) {
                _poolInfo[_timePeriods[i]] = PoolInfo({
                    allocPoint: uint256(_isFixedAPY ? 1 : (i + 1)),
                    lastRewardTime: _startTime,
                    accERC20PerShare: 0,
                    fixedAPY: uint256(_isFixedAPY ? _fixedAPYs[i] : 0),
                    penalty: _penalties[i],
                    totalDeposits: 0
                });
            }
        } else {
            _totalAllocPoints = 1;
            _poolInfo[0] = PoolInfo({
                allocPoint: 1,
                lastRewardTime: _startTime,
                accERC20PerShare: 0,
                fixedAPY: uint256(_isFixedAPY ? _fixedAPYs[0] : 0),
                penalty: 0,
                totalDeposits: 0
            });
        }

        // Transfer ownership to the admin address who then becomes the new owner of the contract.
        transferOwnership(admin_);

        emit StakingProgramInitialized(
            _stakedToken,
            _rewardToken,
            _rewardPerSecond,
            _startTime,
            _endTime,
            _timePeriods,
            _penalties,
            _fixedAPYs,
            admin_,
            _isTimeBoundLock,
            _isPenaltyCharged,
            _isFixedAPY
        );
    }

    // Staking functions

    /**
     * @notice function stakes token in a given staking pool
     * @param amount_: amount to deposit (in staked tokens)
     * @param period_: time period in which the user wish to stake
     */
    function deposit(
        uint256 amount_,
        uint256 period_
    ) public nonReentrant ValidatePeriod(period_) {
        require(amount_ > 0, "Deposit amount must be greater than zero.");

        // Calculate true deposit amount
        uint256 beforeBalance = _stakedToken.balanceOf(address(this));
        _stakedToken.safeTransferFrom(_msgSender(), address(this), amount_);
        uint256 afterBalance = _stakedToken.balanceOf(address(this));

        uint256 stakedAmount;
        if (afterBalance - beforeBalance <= amount_) {
            stakedAmount = afterBalance - beforeBalance;
        } else {
            stakedAmount = amount_;
        }

        // Take staking fee
        if (_stakeFeePercent > 0) {
            uint256 feeAmount = (stakedAmount * _stakeFeePercent) /
                FEE_DENOMINATOR;
            stakedAmount = stakedAmount - feeAmount;
            _totalFeeCollected = _totalFeeCollected + feeAmount;
        }

        PoolInfo storage pool = _poolInfo[period_];
        UserInfo storage user = _userInfo[msg.sender][period_];

        if (!_isFixedAPY) {
            _updatePool(period_);
            user.rewardDebt =
                (user.amount * pool.accERC20PerShare) /
                PRECISION_FACTOR;
        }
        user.amount = user.amount + stakedAmount;
        user.depositTime = block.timestamp;
        user.withdrawTime = user.depositTime + (period_ * 24 * 60 * 60);
        pool.totalDeposits = pool.totalDeposits + user.amount;

        emit Deposit(
            _msgSender(),
            period_,
            user.amount,
            user.depositTime,
            user.withdrawTime
        );
    }

    /**
     * @notice function withdraws staked tokens without caring about rewards. EMERGENCY ONLY.
     * @param period_: time period from which user wish to withdraw.
     */
    function emergencyWithdraw(
        uint256 period_
    ) public nonReentrant ValidatePeriod(period_) {
        PoolInfo storage pool = _poolInfo[period_];
        UserInfo storage user = _userInfo[msg.sender][period_];

        if (user.withdrawTime > block.timestamp) {
            require(
                _isEarlyWithdrawAllowed,
                "Early withdrawal is not allowed."
            );
        }

        uint256 withdrawalAmount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalDeposits = pool.totalDeposits - withdrawalAmount;

        _stakedToken.safeTransfer(_msgSender(), withdrawalAmount);

        emit EmergencyWithdraw(_msgSender(), period_, withdrawalAmount);
    }

    // Admin functions

    /**
     * @notice function sets fee values right after the stakeing program is initialized.
     * @param stakeFeePercent_: new stake fee percent
     * @param feeCollector_: address of new fee collector
     */
    function initializeFee(
        uint256 stakeFeePercent_,
        address feeCollector_
    ) external onlyOwner {
        require(
            stakeFeePercent_ < 100,
            "Stake Fee Percent must be less than 100"
        );
        require(
            feeCollector_ != address(0),
            "Fee Collector cannot be zero address."
        );

        _stakeFeePercent = stakeFeePercent_;
        _feeCollector = feeCollector_;

        emit StakeFeePercentSet(_stakeFeePercent);
        emit FeeCollectorSet(_feeCollector);
    }

    /**
     * @notice function sets a new stake fee percent value
     * @param stakeFeePercent_: new stake fee percent
     */
    function setStakeFeePercent(uint256 stakeFeePercent_) external onlyOwner {
        require(
            stakeFeePercent_ < 100,
            "Stake Fee Percent must be less than 100"
        );
        _stakeFeePercent = stakeFeePercent_;
        emit StakeFeePercentSet(_stakeFeePercent);
    }

    /**
     * @notice function sets '_feeCollector' for a new address
     * @param feeCollector_: address of new fee collector
     */
    function setFeeCollector(address feeCollector_) external onlyOwner {
        _feeCollector = feeCollector_;
        emit FeeCollectorSet(_feeCollector);
    }

    /**
     * @notice function sets the new state for early withdraw
     * @param isEarlyWithdrawAllowed_: is early withdraw allowed or not
     */
    function setIsEarlyWithdrawAllowed(
        bool isEarlyWithdrawAllowed_
    ) external onlyOwner {
        _isEarlyWithdrawAllowed = isEarlyWithdrawAllowed_;
        emit IsEarlyWithdrawAllowedSet(_isEarlyWithdrawAllowed);
    }

    /**
     * @notice function withdraws collected fee in staked token to fee collector's wallet
     */
    function withdrawCollectedFees() external onlyOwner {
        uint256 totalFeeColleced = _totalFeeCollected;
        _stakedToken.transfer(_feeCollector, _totalFeeCollected);
        _totalFeeCollected = 0;

        emit WithdrawFees(totalFeeColleced);
    }

    /**
     * @notice function injects liquidity in reward tokens into the staking program
     * @param amount_: reward token amount
     */
    function injectLiquidity(uint256 amount_) external onlyOwner {
        _totalFundedRewards = _totalFundedRewards + amount_;
        _rewardToken.safeTransferFrom(msg.sender, address(this), amount_);

        emit FundLiquidity(amount_);
    }

    /**
     * @notice function withdraws reward tokens after the program has ended.
     * @param amount_: number of reward tokens to withdraw
     */
    function withdrawLiquidity(uint256 amount_) external onlyOwner {
        require(
            amount_ <= _totalFundedRewards,
            "Cannot withdraw more than contract balance."
        );

        _totalFundedRewards = _totalFundedRewards - amount_;
        _rewardToken.safeTransfer(msg.sender, amount_);

        emit WithdrawLiquidity(amount_);
    }

    /**
     * @notice function withdraws ERC20 tokens, if stuck.
     * @param token_: token address to withdraw.
     * @param amount_: amount to tokens to withdraw.
     * @param beneficiary_: address of user that receives the tokens.
     */
    function withdrawTokensIfStuck(
        address token_,
        uint256 amount_,
        address beneficiary_
    ) external onlyOwner {
        IERC20 token = IERC20(token_);

        require(
            token != _stakedToken,
            "Users' staked tokens cannot be withdrawn."
        );
        require(
            beneficiary_ != address(0),
            "Beneficiary cannot be zero address."
        );

        token.safeTransfer(beneficiary_, amount_);
    }

    // View Functions

    /**
     * @notice function is getting number of staked tokens deposited by a user.
     * @param user_: address of user.
     * @param period_: staking period.
     * @return deposited amount of staked tokens for a user.
     */
    function getUserDepositedAmount(
        address user_,
        uint256 period_
    ) public view ValidatePeriod(period_) returns (uint256) {
        UserInfo memory user = _userInfo[user_][period_];
        return user.amount;
    }

    /**
     * @notice function is getting epoch time to see deposit and withdraw time for a user.
     * @param user_: address of user.
     * @param period_: staking period.
     * @return time when user deposited and is expected to withdraw.
     */
    function getUserDepositWithdrawTime(
        address user_,
        uint256 period_
    ) public view ValidatePeriod(period_) returns (uint256, uint256) {
        UserInfo memory user = _userInfo[user_][period_];
        return (user.depositTime, user.withdrawTime);
    }

    /**
     * @notice function is getting number of reward tokens pending for a user.
     * @dev pending rewards = (user.amount * pool.accERC20PerShare) - user.rewardDebt.
     * @param user_: address of user.
     * @param period_: staking period.
     * @return pendingRewards : pending reward tokens for a user.
     */
    function getUserPendingRewards(
        address user_,
        uint256 period_
    ) public view ValidatePeriod(period_) returns (uint256 pendingRewards) {
        PoolInfo memory pool = _poolInfo[period_];
        UserInfo memory user = _userInfo[user_][period_];

        if (user.amount == 0) {
            return 0;
        }

        if (_isFixedAPY) {
            if (block.timestamp < _endTime) {
                pendingRewards =
                    user.amount *
                    (pool.fixedAPY / 360) *
                    (block.timestamp - user.depositTime);
            } else {
                pendingRewards =
                    user.amount *
                    (pool.fixedAPY / 360) *
                    (block.timestamp - _endTime);
            }
        } else {
            uint256 accERC20PerShare = pool.accERC20PerShare;
            uint256 totalDeposits = pool.totalDeposits;
            uint256 lastRewardTime = pool.lastRewardTime;

            if (block.timestamp > lastRewardTime && totalDeposits != 0) {
                uint256 lastTime = block.timestamp < _endTime
                    ? block.timestamp
                    : _endTime;
                uint256 timeToCompare = lastRewardTime < _endTime
                    ? lastRewardTime
                    : _endTime;
                uint256 noOfSeconds = lastTime - timeToCompare;
                uint256 rewardTokenToDistribute = (noOfSeconds *
                    _rewardPerSecond *
                    (10 ** _decimalsOfRewardToken) *
                    pool.allocPoint) / _totalAllocPoints;
                accERC20PerShare =
                    accERC20PerShare +
                    ((rewardTokenToDistribute * PRECISION_FACTOR) /
                        totalDeposits);
                pendingRewards =
                    ((user.amount * accERC20PerShare) / PRECISION_FACTOR) -
                    user.rewardDebt;
            }
        }
    }

    /**
     * @notice function is getting a user's total pending rewards in all the time periods.
     * @param user_: address of user.
     * @return pendingRewards array of pending rewards of a user for all the time periods.
     */
    function getUserTotalPendingRewards(
        address user_
    ) public view returns (uint256[] memory pendingRewards) {
        if (_isTimeBoundLock) {
            pendingRewards = new uint256[](_timePeriods.length);
            for (uint256 i = 0; i < _timePeriods.length; i++) {
                PoolInfo memory pool = _poolInfo[_timePeriods[i]];
                UserInfo memory user = _userInfo[user_][_timePeriods[i]];

                if (_isFixedAPY) {
                    if (user.amount == 0) {
                        pendingRewards[i] = 0;
                        continue;
                    }
                    uint256 noOfSeconds = block.timestamp < _endTime
                        ? (block.timestamp - user.depositTime)
                        : (_endTime - user.depositTime);
                    pendingRewards[i] =
                        user.amount *
                        (pool.fixedAPY / 100) *
                        (noOfSeconds / (360 * 24 * 60 * 60));
                } else {
                    pendingRewards[i] = getUserPendingRewards(
                        user_,
                        _timePeriods[i]
                    );
                }
            }
            return pendingRewards;
        } else {
            pendingRewards = new uint256[](1);

            PoolInfo memory pool = _poolInfo[0];
            UserInfo memory user = _userInfo[user_][0];

            if (_isFixedAPY) {
                if (user.amount == 0) {
                    pendingRewards[0] = 0;
                }
                uint256 noOfSeconds = block.timestamp < _endTime
                    ? (block.timestamp - user.depositTime)
                    : (_endTime - user.depositTime);
                pendingRewards[0] =
                    user.amount *
                    (pool.fixedAPY / 100) *
                    (noOfSeconds / (360 * 24 * 60 * 60));
            } else {
                pendingRewards[0] = getUserPendingRewards(user_, 0);
            }
            return pendingRewards;
        }
    }

    /**
     * @notice function is getting number of total reward tokens the program has yet to pay out.
     * @return number of reward tokens the program has yet to pay out.
     */
    function getTotalPendingRewards() public view returns (uint256) {
        if (block.timestamp <= _startTime) {
            return 0;
        }

        if (_isFixedAPY) {
            uint256 totalPendingRewards;
            for (uint256 i = 0; i < _timePeriods.length; i++) {
                PoolInfo memory pool = _poolInfo[_timePeriods[i]];
                totalPendingRewards =
                    totalPendingRewards +
                    (pool.totalDeposits *
                        (pool.fixedAPY / 100) *
                        (_timePeriods[i] / 360));
            }
            return totalPendingRewards;
        } else {
            uint256 lastTime = block.timestamp < _endTime
                ? block.timestamp
                : _endTime;
            return ((_rewardPerSecond * (lastTime - _startTime)) - _paidOut); // DA: if _paidOut has value in wie, it will fail
        }
    }

    // DA:what will be the input if reward per sec is less than 1
    // DA: if there are more than one lock-in period, the APYs should be diff

    // Internal Functions

    /**
     * @notice function updates reward variables of a given pool.
     * @dev This function is used only when the contract provides variable APY.
     * @param period_: time period of the pool to update.
     */
    function _updatePool(uint256 period_) internal {
        PoolInfo storage pool = _poolInfo[period_];

        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        uint256 stakedTokenSupply = pool.totalDeposits;
        if (stakedTokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 noOfSeconds = _getNoOfSeconds(
            pool.lastRewardTime,
            block.timestamp
        );
        uint256 rewardTokenToDistribute = (noOfSeconds *
            _rewardPerSecond *
            pool.allocPoint) / _totalAllocPoints;
        pool.accERC20PerShare =
            pool.accERC20PerShare +
            ((rewardTokenToDistribute *
                (10 ** _decimalsOfRewardToken) *
                PRECISION_FACTOR) / stakedTokenSupply);
        pool.lastRewardTime = block.timestamp;
    }

    /**
     * @notice function returns number of seconds over the given time
     * @param from_: time to start
     * @param to_: time to finish
     */
    function _getNoOfSeconds(
        uint256 from_,
        uint256 to_
    ) internal view returns (uint256 noOfSeconds) {
        if (to_ <= _endTime) {
            noOfSeconds = to_ - from_;
        } else if (from_ >= _endTime) {
            noOfSeconds = 0;
        } else {
            noOfSeconds = _endTime - from_;
        }
    }

    /**
     * @dev function checks if a given array contains the passed value
     * @param array_: an array of unsigned integers
     * @param value_: value to search in the given array
     */
    function _searchArray(
        uint256[] memory array_,
        uint256 value_
    ) private pure returns (bool exists) {
        for (uint256 i = 0; i < array_.length; i++) {
            if (array_[i] == value_) {
                exists = true;
                break;
            }
        }
    }

    function claimRewards(uint256 period_) public {
        // DA:Claim All/Withdraw All function - If there are multiple lock-in periods

        PoolInfo storage pool = _poolInfo[period_];
        UserInfo storage user = _userInfo[msg.sender][period_];

        require(
            block.timestamp > user.withdrawTime,
            "User cannot claim rewards right now"
        );

        uint256 pendingRewards;
        if (_isFixedAPY) {
            pendingRewards =
                user.amount *
                (pool.fixedAPY / 100) *
                (period_ / 360);
        } else {
            _updatePool(period_);
            pendingRewards =
                ((user.amount * pool.accERC20PerShare) / PRECISION_FACTOR) -
                user.rewardDebt;
        }

        require(pendingRewards > 0, "There are no pending rewards");

        user.rewardDebt =
            (user.amount * pool.accERC20PerShare) /
            PRECISION_FACTOR;
        _paidOut = _paidOut + pendingRewards;

        _rewardToken.safeTransfer(_msgSender(), pendingRewards);

        emit Claim(_msgSender(), period_, pendingRewards, block.timestamp);
    }

    /**
     * @notice function withdraws deposited tokens and rewards, if any
     * @param amount_: amount of staked tokens to withdraw.
     * @param period_: time period from which user wish to withdraw.
     */
    function withdraw(uint256 amount_, uint256 period_) public {
        require(amount_ > 0, "Withdraw amount must be greater than zero.");

        PoolInfo storage pool = _poolInfo[period_];
        UserInfo storage user = _userInfo[msg.sender][period_];

        require(
            user.amount >= amount_,
            "Withdraw amount cannot be greater than deposited amount."
        );

        uint256 pendingRewards;

        if (_isFixedAPY) {
            pendingRewards =
                user.amount *
                (pool.fixedAPY / 100) *
                (period_ / 360);
        } else {
            _updatePool(period_);
            pendingRewards =
                ((user.amount * pool.accERC20PerShare) / PRECISION_FACTOR) -
                user.rewardDebt;
        }

        // Whether to charge penalty fee or not.
        if (
            pendingRewards > 0 &&
            _isTimeBoundLock &&
            _isPenaltyCharged &&
            user.withdrawTime > block.timestamp
        ) {
            require(
                _isEarlyWithdrawAllowed,
                "Early withdrawal is not allowed."
            );
            pendingRewards =
                pendingRewards -
                ((pendingRewards * pool.penalty) / FEE_DENOMINATOR);
        }

        // DA: if there are multiple lock-in periods, then check if a pool has zero lock-in time, then it's penalty should be zero
        // DA: time periods and penalties array should be in ascending order

        user.amount = user.amount - amount_;
        user.rewardDebt =
            (user.amount * pool.accERC20PerShare) /
            PRECISION_FACTOR;
        pool.totalDeposits = pool.totalDeposits - amount_;
        _paidOut = _paidOut + pendingRewards;

        // Distribute rewards, if any
        _stakedToken.safeTransfer(_msgSender(), amount_);
        _rewardToken.safeTransfer(_msgSender(), pendingRewards);

        emit Withdraw(
            _msgSender(),
            period_,
            amount_,
            pendingRewards,
            block.timestamp
        );
    }
}