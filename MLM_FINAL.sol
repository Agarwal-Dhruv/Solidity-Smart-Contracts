// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Interface for Auium Protocol's ERC20 token.
 */
interface IAuriumToken {
    function mint(uint256) external;

    function transfer(address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

/**
 * @title Contract that manages the entire GODL network for GODL token/
 * @notice This contract performs the entire logic of GODL Network including user registration, reward distribution / reinvestment and reward tier level management.
 */
contract GodlAmbassadorInfluencerNetwork is PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // PAXG token contract address.
    IERC20 private paxgToken_;
    // GODL token contract address.
    IAuriumToken private godlToken_;
    // Contract deployer wallet address.
    address private deployer_;
    // List of addresses that are in the top-line.
    address[] private toplineList_;
    // Total number of users in the GODL network, including the top-line.
    uint256 private totalUsers_;
    // Fee receiver address where join fee is sent at the time of registration.
    address private feeReceiver_;

    // ----- START: GODL Network Reward Configuration ----- //

    // Maximum referral levels that constitute any user's downline in the GODL network.
    uint256 private constant MAX_REFERRAL_LEVEL = 5;
    // Total PAXG rewards generated till date. This includes both, distributed and re-invested ones.
    uint256 private totalRewardsGenerated_;
    // Total PAXG rewardsre-invested for auto-purchase till date.
    uint256 private totalRewardsReinvested_;
    // Reward percentages for every downline. For example, first downline (0th index) gives 5% as rewards (in PAXG).
    uint256[] private rewardPercents_;
    // Reward tier package cost for all the five levels.
    uint256[] private rewardTierCosts_;
    // Reward Percents in 2D for reward calculations.
    uint256[][] private rewardPercentsIn2D_;

    // ----- END: GODL Network Reward Configuration ----- //

    struct User {
        uint256 uniqueId; // User's unique id that is used for network links.
        uint256 referrer; // The referrer's uniqueId. Zero in case of top-line.
        uint256 level; // Current reward tier level.
        bool reinvestFlag; // User can opt-in for re-investment which enables user's next reward tier auto-purchase mode.
        mapping(uint256 => uint256) referralCount; // No. of referrals at a given level.
        mapping(uint256 => uint256[]) referrals; // Referral ids at a given level.
        uint256 totalRewards; // Total PAXG rewards till date.
        uint256 rewardBalance; // User's PAXG rewards that are kept in the contract for auto-purchase of the next reward tier.
        uint256 registrationTime; // Time when user registered the GODL network.
    }

    // User's id to wallet address to store all the wallet addresses that have joined the GODL Network.
    mapping(uint256 => address) private idToWalletAddress;
    // User's wallet address to User struct mapping.
    mapping(address => User) private user;
    // User's wallet address to boolean true / false that maps status for the user being in top-line.
    mapping(address => bool) private isInTopline;
    // User's wallet address to index of "toplineList_" array
    mapping(address => uint256) private addressToToplineIndex;

    event NewToplineAddress(uint256 indexed newToplineCount); // UA: Do something here with names and what to emit?
    event NewUser(
        address indexed user,
        address indexed referrer,
        uint256 registrationTime
    );
    event Reward(
        address indexed user,
        address indexed referrer,
        uint256 amount
    );
    event LevelUp(address indexed user, uint256 level);
    event SetAutoPurchase(address indexed user, bool autoPurchase);
    event UpdateWalletAddress(
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );
    event UpdateFeeReceiver(
        address indexed oldFeeReceiver,
        address indexed newFeeReceiver
    );

    /**
     * @notice Function to initialize the contract.
     * @dev Contract uses OpenZeppelin's Initializable.sol to deploy upgradeable contracts.
     * @param _paxgToken : PAXG token contract address.
     * @param _godlToken: GODL token contract address.
     */
    function initialize(address _paxgToken, address _godlToken)
        public
        initializer
    {
        __Ownable_init();
        __Pausable_init();

        require(
            _paxgToken != address(0),
            "Initialize: PAXG token cannot be zero address."
        );
        require(
            _godlToken != address(0),
            "Initialize: GODL token cannot be zero address."
        );

        paxgToken_ = IERC20(_paxgToken);
        godlToken_ = IAuriumToken(_godlToken);
        deployer_ = _msgSender();

        rewardPercents_ = [5, 4, 3, 2, 1];
        rewardTierCosts_ = [
            10000000000000000, // 0.01 PAXG
            25000000000000000, // 0.025 PAXG
            50000000000000000, // 0.05 PAXG
            100000000000000000, // 0.1 PAXG
            500000000000000000 // 0.5 PAXG
        ];
        rewardPercentsIn2D_ = [
            [5, 0, 0, 0, 0],
            [5, 4, 0, 0, 0],
            [5, 4, 3, 0, 0],
            [5, 4, 3, 2, 0],
            [5, 4, 3, 2, 1]
        ];
    }

    /**
     * @notice Function to join the GODL network.
     * @dev User joining, reward distribution in uplines and auto-purchase, all the three happens in this function.
     * @param _referrer : Referrer address that the user wishes to join with.
     * @param _level : Reward tier level that the user wishes to purchase.
     */
    function join(address _referrer, uint256 _level) public whenNotPaused {
        // Check that the _msgSender() is an EOA.

        // Check if user is already in the network.
        require(
            !isExistingUser(_msgSender()),
            "join : Sender is already a user in the GODL network."
        );

        // Only topline addresses can join the GODL network without any referrer address
        if (_referrer == address(0)) {
            require(
                isInTopline[_msgSender()],
                "join : Referrer address is invalid or the sender is not among the topline."
            );
            user[_msgSender()].referrer = 0;
        } else {
            // If referrer address is a valid ethereum address, this address must exist in the GODL network.
            require(
                isExistingUser(_referrer),
                "join : Referrer address does not exist in the network."
            );
            user[_msgSender()].referrer = user[_referrer].uniqueId;
        }

        // Tier level has to be between 1 and 5.
        require(
            _level > 0 && _level <= MAX_REFERRAL_LEVEL,
            "join : Invalid level."
        );

        // Update users data
        totalUsers_++;
        idToWalletAddress[totalUsers_] = _msgSender();

        // Sender struct is created here and is initialized with the referrer address and joining timestamp
        user[_msgSender()].uniqueId = totalUsers_;
        user[_msgSender()].registrationTime = block.timestamp;

        // Add referral user to the referrer's referral list
        if (!isInTopline[_msgSender()]) {
            uint256 i = 1;
            uint256 uplineCount = 1;
            address[] memory uplineUsers = new address[](5);
            uplineUsers[0] = _referrer;

            while (i < 5) {
                User storage userStruct = user[uplineUsers[i - 1]];
                if (userStruct.referrer != 0) {
                    uplineCount++;
                    uplineUsers[i] = idToWalletAddress[userStruct.referrer];
                } else {
                    break;
                }
                i++;
            }

            for (uint256 j = 0; j < uplineCount; j++) {
                User storage userStruct = user[uplineUsers[j]];
                userStruct.referralCount[j + 1]++;
                userStruct.referrals[j + 1].push(user[_msgSender()].uniqueId);
            }
        }

        buyLevelFor(_msgSender(), _level);

        emit NewUser(_msgSender(), _referrer, block.timestamp);
    }

    /**
     * @notice Function to buy / upgrade reward-tier package
     * @dev This function can be used to buy / upgrade the current level for any given user
     * @param _for : User address whose package level will be upgraded
     * @param _level : Level that user wish to upgrade
     */
    function buyLevelFor(address _for, uint256 _level) public whenNotPaused {
        require(_for != address(0), "buyLevelFor : Invalid address.");
        require(
            _level > 0 && _level <= MAX_REFERRAL_LEVEL,
            "buyLevelFor : Invalid level."
        );
        require(
            isExistingUser(_msgSender()),
            "buyLevelFor : Sender has not yet joined the GODL network."
        );
        require(
            user[_for].level < _level,
            "buyLevelFor : User current level is already equal or higher than the given level."
        );

        uint256 initialPaxgBalance = paxgToken_.balanceOf(address(this));
        uint256 rewardTierCost = getRewardTierCost(user[_for].level, _level);
        paxgToken_.safeTransferFrom(
            _msgSender(),
            address(this),
            rewardTierCost
        );

        uint256 paxgReceived = paxgToken_.balanceOf(address(this)) -
            initialPaxgBalance;

        // 1% to fee receiver
        uint256 paxgSentToFeeReceiver = rewardTierCost / 100;

        // distribute rewards
        (
            uint256 totalRewardDistributed,
            uint256 remainingRewardPercent
        ) = _distributeRewards(_msgSender(), rewardTierCost);

        // rest goes to fee receiver
        paxgSentToFeeReceiver +=
            (rewardTierCost * remainingRewardPercent) /
            100;

        paxgToken_.safeTransfer(feeReceiver_, paxgSentToFeeReceiver);

        uint256 paxgAmtToMintGodl = paxgReceived -
            totalRewardDistributed -
            paxgSentToFeeReceiver;

        _mintGodl(_msgSender(), paxgAmtToMintGodl);

        user[_for].level = _level;

        emit LevelUp(_for, _level);
    }

    /**
     * @notice Function to update the reward tier auto-purchase package feature on / off.
     * @param _reinvestFlag : Boolean true / false to set the auto-purchase on / off.
     */
    function setAutoPurchase(bool _reinvestFlag) public whenNotPaused {
        require(
            isExistingUser(_msgSender()),
            "setAutoPurchase : User has not yet joined the GODL network."
        );

        if (user[_msgSender()].rewardBalance > 0) {
            paxgToken_.safeTransfer(
                _msgSender(),
                user[_msgSender()].rewardBalance
            );
        }

        user[_msgSender()].reinvestFlag = _reinvestFlag;

        emit SetAutoPurchase(_msgSender(), _reinvestFlag);
    }

    /**
     * @notice Function to update the wallet addresses, in case user wish to change the existing one.
     * @dev Wallet address is mapped with a unique id. Updating this mapping will reflect the change in
     * the entire network graph of the given wallet address.
     * @param _newWalletAddress : New wallet address to replace the old one.
     */
    function updateWalletAddress(address _newWalletAddress)
        public
        whenNotPaused
    {
        require(
            isExistingUser(_msgSender()),
            "updateWalletAddress : The given sender does not exist in the GODL Network."
        );
        require(
            _newWalletAddress != address(0),
            "updateWalletAddress : New wallet address cannot be the zero address."
        );
        require(
            !isExistingUser(_newWalletAddress),
            "updateWalletAddress: New wallet address cannot be an existing user in the GODL Network."
        );

        if (user[_msgSender()].rewardBalance > 0) {
            paxgToken_.safeTransfer(
                _msgSender(),
                user[_msgSender()].rewardBalance
            );
        }

        uint256 uniqueId = user[_msgSender()].uniqueId;
        idToWalletAddress[uniqueId] = _newWalletAddress;

        // Initialize a new mapping with the _neWalletAddress
        user[_newWalletAddress].uniqueId = uniqueId;
        user[_newWalletAddress].referrer = user[_msgSender()].referrer;
        user[_newWalletAddress].level = user[_msgSender()].level;
        user[_newWalletAddress].reinvestFlag = user[_msgSender()].reinvestFlag;
        for (uint256 i = 0; i < 5; i++) {
            user[_newWalletAddress].referralCount[i] = user[_msgSender()]
                .referralCount[i];
            user[_newWalletAddress].referrals[i] = user[_msgSender()].referrals[
                i
            ];
        }
        user[_newWalletAddress].totalRewards = user[_msgSender()].totalRewards;
        user[_newWalletAddress].rewardBalance = 0;
        user[_newWalletAddress].registrationTime = user[_msgSender()]
            .registrationTime;

        // Clear the old mapping
        user[_msgSender()].uniqueId = 0;
        user[_msgSender()].referrer = 0;
        user[_msgSender()].level = 0;
        user[_msgSender()].reinvestFlag = false;
        for (uint256 i = 0; i < 5; i++) {
            user[_msgSender()].referralCount[i] = 0;
            user[_msgSender()].referrals[i] = new uint256[](0);
        }
        user[_msgSender()].totalRewards = 0;
        user[_msgSender()].rewardBalance = 0;
        user[_msgSender()].registrationTime = 0;

        // If in topline, remove the old address and add the new one.
        if (isInTopline[_msgSender()]) {
            isInTopline[_msgSender()] = false;
            isInTopline[_newWalletAddress] = true;

            // fetch the array index and replace the old address with the new one.
            uint256 toplineIndex = addressToToplineIndex[_msgSender()];
            toplineList_[toplineIndex - 1] = _newWalletAddress;
        }

        emit UpdateWalletAddress(_msgSender(), _newWalletAddress);
    }

    /**
     * @dev This function performs the entire logic of PAXG reward distribution during user joining process and is responsible
     * for upgrading reward tier packages for users that have their auto-purchase mode on.
     * @param _user : User address that is in the process of joining the GODL network.
     * @param _amount : Amount of PAXG to distribute in rewards.
     */
    function _distributeRewards(address _user, uint256 _amount)
        internal
        returns (uint256 totalRewardDistributed, uint256 remainingRewardPercent)
    {
        require(
            _user != address(0),
            "_distributeRewards : Invalid user address."
        );
        require(
            _amount > 0,
            "_distributeRewards : Amount must be greater than zero."
        );
        address currentReferrer = idToWalletAddress[user[_user].referrer];
        remainingRewardPercent = 15;

        for (uint256 i = 0; i < MAX_REFERRAL_LEVEL; i++) {
            if (currentReferrer == address(0)) {
                break;
            }

            if (user[currentReferrer].level - 1 < rewardPercentsIn2D_.length) {
                uint256 bonusPercentage = rewardPercentsIn2D_[
                    user[currentReferrer].level - 1
                ][i];
                uint256 reward = (_amount * bonusPercentage) / 100;

                if (reward > 0) {
                    if (user[currentReferrer].reinvestFlag) {
                        user[currentReferrer].rewardBalance += reward;
                        totalRewardsReinvested_ += reward;

                        // Check here if the temporaryBalance exceeds or matches the desired amount of next tier/level purchase.
                        // If yes, buy the next tier for this referrer.
                        if (
                            user[currentReferrer].level < 5 &&
                            user[currentReferrer].rewardBalance >=
                            getRewardTierCost(
                                user[currentReferrer].level,
                                (user[currentReferrer].level + 1)
                            )
                        ) {
                            buyLevelFor(
                                currentReferrer,
                                (user[currentReferrer].level + 1)
                            );
                        }
                    } else {
                        paxgToken_.safeTransfer(currentReferrer, reward);
                    }
                    user[currentReferrer].totalRewards += reward;
                    totalRewardsGenerated_ += reward;
                    totalRewardDistributed += reward;
                    emit Reward(_user, currentReferrer, reward);

                    remainingRewardPercent =
                        remainingRewardPercent -
                        (MAX_REFERRAL_LEVEL - i);

                }
            }

            currentReferrer = idToWalletAddress[user[currentReferrer].referrer];
        }
    }

    /**
     * @dev This function handles the minting of GODL token using the Aurium protocol.
     * @param _to : User address that will receive the newly minted GODL tokens.
     * @param _paxgAmount : PAXG amount that is transferred to the GODL token contract to mint the GODL token with the intrinsic value the contract holds.
     */
    function _mintGodl(address _to, uint256 _paxgAmount)
        internal
        whenNotPaused
    {
        // Before balance of GODL
        uint256 initialBalance = godlToken_.balanceOf(address(this));

        // approve PAXG for address(this)
        paxgToken_.approve(address(godlToken_), _paxgAmount);

        // Mint GODL tokens for the user.
        godlToken_.mint(_paxgAmount);

        // After balance of GODL
        uint256 afterBalance = godlToken_.balanceOf(address(this));

        // Use the transfer function of the GODL contract to trigger the deflationary mechanism.
        godlToken_.transfer(_to, (afterBalance - initialBalance));
    }

    // ---------- START: Owner Functions ---------- //

    /**
     * @notice Function to add addresses that will constitute the topline.
     * @dev toplineList_ will hold all the user addresses that will be the root level of the network.
     * @param _toplineList : An array of addresses to add in the toplineList_.
     */
    function addUserInTopline(address[] memory _toplineList) public onlyOwner {
        require(
            _toplineList.length <= 20,
            "addUserInTopline: Topline list must not exceed 20 addresses."
        );

        for (uint256 i = 0; i < _toplineList.length; i++) {
            // Require if the given address already address in the topline.
            require(
                !isInTopline[_toplineList[i]],
                "addUserInTopline: Given user is already added in the topline."
            );
            // Require if the given address has already joined the network.
            require(
                !isExistingUser(_toplineList[i]),
                "addUserInTopline: Given user has already joined the network."
            );

            toplineList_.push(_toplineList[i]);
            isInTopline[_toplineList[i]] = true;
            addressToToplineIndex[_msgSender()] = toplineList_.length;
        }

        emit NewToplineAddress(_toplineList.length);
    }

    /**
     * @notice Function to update feeReceiver.
     * @param feeReceiver : New fee receiver address.
     */
    function setFeeReceiver(address feeReceiver) public onlyOwner {
        address oldFeeReceiver = feeReceiver_;
        feeReceiver_ = feeReceiver;

        emit UpdateFeeReceiver(oldFeeReceiver, feeReceiver_);
    }

    /**
     * @notice Function to pause the GODL Network contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Function to unpasue the GODL Network contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // ---------- END: Owner Functions ---------- //

    // ---------- START: Getter Functions ---------- //

    /**
     * @notice Function to get the PAXG token contract address.
     * @dev PAXG token is set during the time of initialization and is never changed during the course of this contract's life.
     * @return paxgToken : PAXG token address.
     */
    function getPaxgToken() public view returns (address paxgToken) {
        return address(paxgToken_);
    }

    /**
     * @notice Function to get the GODL token contract address.
     * @dev GODL token is set during the time of initialization and is never changed during the course of this contract's life.
     * @return godlToken : GODL token address.
     */
    function getGodlToken() public view returns (address godlToken) {
        return address(godlToken_);
    }

    /**
     * @notice Function to get the contract deployer's wallet address.
     * @dev Deployer address is set during the time of initialization.
     * @return deployer : Deployer's wallet address.
     */
    function getDeployerAddress() public view returns (address deployer) {
        return deployer_;
    }

    /**
     * @notice Function to get the total number of user that constitue the topline of the network tree.
     * @return toplineCount : Topline count.
     */
    function getToplineCount() public view returns (uint256 toplineCount) {
        return toplineList_.length;
    }

    /**
     * @notice Function to get the user's wallet address that are in the topline.
     * @param _index : Index of the topline address array.
     * @return  toplineUserAddress : Topline user's wallet address.
     */
    function getToplineUserAddress(uint256 _index)
        public
        view
        returns (address toplineUserAddress)
    {
        require(
            _index < getToplineCount(),
            "getToplineUserAddress: Invalid index. It must be less than the total topline count."
        );

        return toplineList_[_index];
    }

    /**
     * @notice Function to check if a given user address is in the network topline or not.
     * @param _userAddress: User's Ethereum wallet address.
     * @return inTopline : Boolean true / false if the user really is in the topline.
     */
    function checkIfUserIsInTopline(address _userAddress)
        public
        view
        returns (bool inTopline)
    {
        return isInTopline[_userAddress];
    }

    /**
     * @notice Function to get the topline index of a given wallet address.
     * @dev The index is incremented by one. To use it, decrease the retrun value by one.
     * @return toplineIndex : Topline index of the given wallet address.
     */
    function getToplineIndexByAddress(address _userAddress)
        public
        view
        returns (uint256 toplineIndex)
    {
        return addressToToplineIndex[_userAddress];
    }

    /**
     * @notice Funciton to get the total number of users in the GODL network, including the top-line.
     * @return totalUsers : Total user count.
     */
    function getTotalUsers() public view returns (uint256 totalUsers) {
        return totalUsers_;
    }

    /**
     * @notice Function to get the fee receiver address.
     * @return feeReceiver : Fee receiver address.
     */
    function getFeeReceiver() public view returns (address feeReceiver) {
        return feeReceiver_;
    }

    /**
     * @notice Function to get the maximum reward tier levels for the GODL Network.
     * @return maxTierLevels : Max reward tier levels.
     */
    function getMaxRewardTierLevels()
        public
        pure
        returns (uint256 maxTierLevels)
    {
        return MAX_REFERRAL_LEVEL;
    }

    /**
     * @notice Function to get the total PAXG rewards that have been generated so far.
     * @return totalRewardsGenerated : Total PAXG rewards generated so far.
     */
    function getTotalRewardsGenerated()
        public
        view
        returns (uint256 totalRewardsGenerated)
    {
        return totalRewardsGenerated_;
    }

    /**
     * @notice Function to get the total PAXG rewards that have been re-invested so far.
     * @return totalRewardsReinvested : Total PAXG rewards re-invested so far.
     */
    function getTotalRewardsReinvested()
        public
        view
        returns (uint256 totalRewardsReinvested)
    {
        return totalRewardsReinvested_;
    }

    /**
     * @notice Function to get the complete list of reward percents for every reward tier level.
     * @return rewardPercents : Array of length five, containing all the reward percents.
     */
    function getRewardPercents()
        public
        view
        returns (uint256[] memory rewardPercents)
    {
        return rewardPercents_;
    }

    /**
     * @notice Function to get the total reward percentages that is charged as fee when a user joins the network.
     * @return totalRewardPercent : Total fee to be charged.
     */
    function getTotalRewardPercents()
        public
        view
        returns (uint256 totalRewardPercent)
    {
        for (uint256 i = 0; i < rewardPercents_.length; i++) {
            totalRewardPercent += rewardPercents_[i];
        }

        return totalRewardPercent;
    }

    /**
     * @notice Function to get the reward tier cost (in PAXG) for a given reward tier level.
     * @dev rewardTierCost is calculated by adding all the costs from the user's current level upto a given reward tier level.
     * @param _currentLevel : Current reward tier level of the user.
     * @param _levelToPurchase : Reward Tier Level to purchase.
     * @return rewardTierCost : Total cost (in PAXG) to buy a given reward tier level.
     */
    function getRewardTierCost(uint256 _currentLevel, uint256 _levelToPurchase)
        public
        view
        returns (uint256 rewardTierCost)
    {
        require(
            _levelToPurchase > 0 && _levelToPurchase <= MAX_REFERRAL_LEVEL,
            "getRewardTierCost : Invalid level."
        );

        for (uint256 i = _currentLevel; i < _levelToPurchase; i++) {
            rewardTierCost += rewardTierCosts_[i];
        }

        return rewardTierCost;
    }

    /**
     * @notice Function to get the complete list of reward tier costs associated with every reward tiew level.
     * @return rewardTierCosts : Array of length five, containing all the reward tier costs.
     */
    function getAllRewardTierCosts()
        public
        view
        returns (uint256[] memory rewardTierCosts)
    {
        return rewardTierCosts_;
    }

    /**
     * @notice Function to get the wallet address mapped with the user's unique id.
     * @return userAddress : User address mapped with the provided unique id.
     */
    function getUserAddressFromId(uint256 _uniqueId)
        public
        view
        returns (address userAddress)
    {
        require(
            _uniqueId > 0 && _uniqueId <= totalUsers_,
            "getUserAddressFromId: Given unique id is invalid."
        );

        return idToWalletAddress[_uniqueId];
    }

    /**
     * @notice Function to fetch the user unique id from the wallet address.
     * @param _userAddress : User's wallet address.
     * @return uniqueId : User's unique id that represents the user in the GODL Network.
     */
    function getUserIdFromWalletAddress(address _userAddress)
        public
        view
        returns (uint256 uniqueId)
    {
        require(
            isExistingUser(_userAddress),
            "getUserIdFromWalletAddress: User has not yet joined the GODL Network."
        );

        return user[_userAddress].uniqueId;
    }

    /**
     * @notice Function to get an existing user's data from the User struce.
     * @param _userAddress : User's wallet address.
     * @return referrer : Referrer's wallet address.
     * @return currentLevel : Current reward tier level of the user.
     * @return reinvestFlag : Boolean true / false describing the mode.
     * @return referralCount : Array of referral counts for all the reward tiers.
     * @return totalRewards : Total rewards generated for hte user till date.
     * @return rewardBalance : Accumulated PAXG rewards of all the reward tier levels.
     * @return registrationTime : EPOCH time in seconds when the user joined the GODL network.
     */
    function getUser(address _userAddress)
        public
        view
        returns (
            address referrer,
            uint256 currentLevel,
            bool reinvestFlag,
            uint256[] memory referralCount,
            uint256 totalRewards,
            uint256 rewardBalance,
            uint256 registrationTime
        )
    {
        require(
            isExistingUser(_userAddress),
            "getUser: Given user has not yet joined the network."
        );

        referralCount = new uint256[](MAX_REFERRAL_LEVEL);
        for (uint256 i = 0; i < MAX_REFERRAL_LEVEL; i++) {
            referralCount[i] = user[_userAddress].referralCount[i + 1];
        }

        return (
            idToWalletAddress[user[_userAddress].referrer],
            user[_userAddress].level,
            user[_userAddress].reinvestFlag,
            referralCount,
            user[_userAddress].totalRewards,
            user[_userAddress].rewardBalance,
            user[_userAddress].registrationTime
        );
    }

    /**
     * @notice Function to get all the referral addresses of a given user for all the five downline levels.
     * @param _userAddress : User address that exists in the GODL network.
     * @return level1Referrals : User's level 1 referral address list.
     * @return level2Referrals : User's level 2 referral address list.
     * @return level3Referrals : User's level 3 referral address list.
     * @return level4Referrals : User's level 4 referral address list.
     * @return level5Referrals : User's level 5 referral address list.
     */
    function getUserReferrals(address _userAddress)
        public
        view
        returns (
            address[] memory level1Referrals,
            address[] memory level2Referrals,
            address[] memory level3Referrals,
            address[] memory level4Referrals,
            address[] memory level5Referrals
        )
    {
        require(
            isExistingUser(_userAddress),
            "getUser: Given user has not yet joined the network."
        );

        level1Referrals = new address[](user[_userAddress].referralCount[1]);
        level2Referrals = new address[](user[_userAddress].referralCount[2]);
        level3Referrals = new address[](user[_userAddress].referralCount[3]);
        level4Referrals = new address[](user[_userAddress].referralCount[4]);
        level5Referrals = new address[](user[_userAddress].referralCount[5]);

        level1Referrals = getUserReferralAddresses(_userAddress, 1);
        level2Referrals = getUserReferralAddresses(_userAddress, 2);
        level3Referrals = getUserReferralAddresses(_userAddress, 3);
        level4Referrals = getUserReferralAddresses(_userAddress, 4);
        level5Referrals = getUserReferralAddresses(_userAddress, 5);
    }

    function getUserReferralAddresses(address _userAddress, uint256 _level)
        public
        view
        returns (address[] memory referralAddresses)
    {
        require(
            isExistingUser(_userAddress),
            "getUser: Given user has not yet joined the network."
        );

        require(
            _level > 0 && _level <= MAX_REFERRAL_LEVEL,
            "getUserReferralAddresses : Invalid level."
        );

        referralAddresses = new address[](
            user[_userAddress].referralCount[_level]
        );

        for (uint256 i = 0; i < user[_userAddress].referralCount[_level]; i++) {
            referralAddresses[i] = idToWalletAddress[
                user[_userAddress].referrals[_level][i]
            ];
        }
        return referralAddresses;
    }

    // ---------- END: Getter Functions ---------- //

    // ---------- START: Helper Functions ---------- //

    /**
     * @notice Function to check if the given wallet address has registered in the GODL network.
     * @dev For a non-existing user, registrationTime is not yet and is thus is always zero.
     * @param _userAddress : User wallet address.
     * @return exists : Boolean true / false if the user is already registered.
     */
    function isExistingUser(address _userAddress)
        public
        view
        returns (bool exists)
    {
        return (user[_userAddress].registrationTime > 0);
    }

    // ---------- END: Helper Functions ---------- //
}
