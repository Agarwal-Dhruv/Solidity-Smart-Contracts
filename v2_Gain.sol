// testToken - 0x2d142cdDe947A667f2eDDcB75A162048DEce31A4
// godlNetwork v1 - 0x69C17ee4D20E7339900aFe6859B1166079bbe39e

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./GodlAmbassadorInfluencerNetwork.sol";

contract GodlNetwork_V2 {
    IERC20 public paxgToken_;
    IAuriumToken public godlToken_;
    address public deployer_;
    address[] public toplineList_;
    uint256 public totalUsers_;
    address public feeReceiver_;
    uint256 public MAX_REFERRAL_LEVEL = 5;
    uint256 public totalRewardsGenerated_;
    uint256 public totalRewardsReinvested_;
    uint256[] public rewardPercents_;
    uint256[] public rewardTierCosts_;
    uint256[][] public rewardPercentsIn2D_;

    struct User {
        uint256 uniqueId;
        uint256 referrer;
        uint256 level;
        bool reinvestFlag;
        mapping(uint256 => uint256) referralCount;
        mapping(uint256 => uint256[]) referrals;
        uint256 totalRewards;
        uint256 rewardBalance;
        uint256 registrationTime;
    }

    mapping(uint256 => address) public idToWalletAddress;
    mapping(address => User) public user;
    mapping(address => bool) public isInTopline;
    mapping(address => uint256) public addressToToplineIndex;

    GodlAmbassadorInfluencerNetwork public v1;

    constructor(address _previousContractAddress) {
        v1 = GodlAmbassadorInfluencerNetwork(_previousContractAddress);
    }

    function migrateContractData() public {
        paxgToken_ = IERC20(v1.getPaxgToken());
        godlToken_ = IAuriumToken(v1.getGodlToken());
        deployer_ = v1.getDeployerAddress();
        totalUsers_ = v1.getTotalUsers();
        feeReceiver_ = v1.getFeeReceiver();
        totalRewardsGenerated_ = v1.getTotalRewardsGenerated();
        totalRewardsReinvested_ = v1.getTotalRewardsReinvested();
        for (uint256 i = 0; i < v1.getToplineCount(); i++) {
            toplineList_.push(v1.getToplineUserAddress(i));
        }
    }

    function something() public view returns (address) {
        return v1.getDeployerAddress();
    }

    function migrateUserData(uint256 i) public {
        // for (uint256 i = 1; i <= v1.getTotalUsers(); i++) {
        address userAddress = v1.getUserAddressFromId(i);
        (
            address referrer,
            uint256 currentLevel,
            bool reinvestFlag,
            uint256[] memory referralCount,
            uint256 totalRewards,
            uint256 rewardBalance,
            uint256 registrationTime
        ) = v1.getUser(userAddress);

        User storage _user = user[userAddress];

        _user.uniqueId = i;
        _user.level = currentLevel;
        _user.reinvestFlag = reinvestFlag;
        _user.totalRewards = totalRewards;
        _user.rewardBalance = rewardBalance;
        _user.registrationTime = registrationTime;

        if (!v1.checkIfUserIsInTopline(userAddress)) {
            _user.referrer = v1.getUserIdFromWalletAddress(referrer);
        }

        // }
    }

    function migrateUserReferrals(address userAddress) public {
        for (uint256 j = 0; j < 5; j++) {
            (
                address[] memory level1Referrals,
                address[] memory level2Referrals,
                address[] memory level3Referrals,
                address[] memory level4Referrals,
                address[] memory level5Referrals
            ) = v1.getUserReferrals(userAddress);

            // for (uint256 i = 0; i < 5; i++) {
            // user[userAddress].referrals[i] = level
            // }
        }
    }
}
