// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./auriumToken.sol";

contract GodlMLM is PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct User {
        address referrer;
        uint256 level;
        mapping(uint256 => uint256) referralCount;
        mapping(uint256 => address[]) referrals;
    }

    IERC20 public paxgToken;
    AuriumToken public godlToken;
    address public deployer;
    mapping(address => uint256) public temporaryBalances;
    mapping(address => bool) public reinvestFlags;
    mapping(address => User) public users;
    mapping(address => bool) public whitelistAddr;
    mapping(address => bool) public isExistingUser;
    uint256 public totalUsers;
    uint256 public constant MAX_REFERRAL_LEVEL = 5;
    uint256[] public downlineLimits = [1, 2, 3, 4, 5];
    uint256[] public depositTiers = [
        100000000000000000, // 0.1 PAXG
        250000000000000000, // 0.25 PAXG
        500000000000000000, // 0.5 PAXG
        1000000000000000000, // 1 PAXG
        5000000000000000000 // 5 PAXG
    ];

    uint256[][] public tierBonusPercentages = [
        [5, 0, 0, 0, 0],
        [4, 5, 0, 0, 0],
        [3, 4, 5, 0, 0],
        [2, 3, 4, 5, 0],
        [1, 2, 3, 4, 5]
    ];

    event NewUser(address indexed user, address indexed referrer);
    event Reward(
        address indexed user,
        address indexed referrer,
        uint256 amount
    );
    event LevelUp(address indexed user, uint256 level);
    event Withdraw(address indexed user, uint256 amount);
    event ReinvestFlagChanged(address indexed user, bool reinvestFlag);

    function initialize(
        address paxgTokenAddress,
        address godlTokenAddress
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        require(
            paxgTokenAddress != address(0),
            "PAXG token address is not valid"
        );
        require(
            godlTokenAddress != address(0),
            "GODL token address is not valid"
        );

        paxgToken = IERC20(paxgTokenAddress);
        godlToken = AuriumToken(godlTokenAddress);
    }

    function join(address referrer, uint level) public whenNotPaused {
        if (referrer == address(0)) {
            require(
                isWhitelistAddr(msg.sender),
                "Referrer address is not valid"
            );
        }

        if (!isWhitelistAddr(msg.sender)) {
            require(
                isExistingUser[referrer],
                "Referrer address is not joined in the program"
            );
        }

        require(!isExistingUser[msg.sender], "User already joined");
        require(level > 0 && level <= depositTiers.length, "Invalid level");

        totalUsers++;

        users[msg.sender].referrer = referrer;
        // Add referral user to the referrer's referral list
        if (isWhitelistAddr(msg.sender)) {
            uint256 currentReferralLevel = users[referrer].referralCount[level];
            users[referrer].referrals[currentReferralLevel].push(msg.sender);
            users[referrer].referralCount[level]++;
        }

        isExistingUser[msg.sender] = true;
        buyLevelFor(msg.sender, level);
        
        emit NewUser(msg.sender, referrer);
    }

    function setReinvestFlag(bool reinvest) public whenNotPaused {
        require(users[msg.sender].referrer != address(0), "User not joined");
        reinvestFlags[msg.sender] = reinvest;

        emit ReinvestFlagChanged(msg.sender, reinvest);
    }

    function buyLevelFor(address _for, uint256 level) public whenNotPaused {
        require(_for != address(0), "Invalid address");
        require(level > 0 && level <= depositTiers.length, "Invalid level");
        require(isExistingUser[_for], "User not joined");
        require(
            users[_for].level < level,
            "User level is already equal or higher"
        );

        uint256 amount = depositTiers[level - 1];
        uint initialBalance = paxgToken.balanceOf(address(this));
        paxgToken.safeTransferFrom(msg.sender, address(this), amount);
        uint afterTransferBalance = paxgToken.balanceOf(address(this));
        uint amtToDistribute = afterTransferBalance - initialBalance;
        _distributeRewards(msg.sender, amount);
        uint afterDistributeBalance = paxgToken.balanceOf(address(this));
        uint amtToMint = amtToDistribute - afterDistributeBalance;
        _mintGodl(msg.sender, amtToMint);

        users[_for].level = level;

        if (reinvestFlags[_for]) {
            uint256 tempBalance = temporaryBalances[_for];
            temporaryBalances[_for] = 0;
            paxgToken.safeTransfer(address(this), tempBalance);
            _mintGodl(_for, tempBalance);
            _distributeRewards(_for, tempBalance);
        }

        emit LevelUp(_for, level);
    }

    function _distributeRewards(address user, uint256 amount) public {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than zero");

        address currentReferrer = users[user].referrer;
        for (
            uint256 i = 0;
            i < MAX_REFERRAL_LEVEL && i < users[user].level;
            i++
        ) {
            if (currentReferrer == address(0)) {
                break;
            }

            if (
                users[currentReferrer].level - 1 < tierBonusPercentages.length
            ) {
                uint256 bonusPercentage = tierBonusPercentages[
                    users[currentReferrer].level - 1
                ][i];
                uint256 reward = (amount * bonusPercentage) / 100;
                if (reward > 0) {
                    if (reinvestFlags[currentReferrer]) {
                        temporaryBalances[currentReferrer] += reward;
                    } else {
                        paxgToken.safeTransfer(currentReferrer, reward);
                    }

                    emit Reward(user, currentReferrer, reward);
                }
            }

            currentReferrer = users[currentReferrer].referrer;
        }
    }

    function _mintGodl(address to, uint256 paxgAmount) public whenNotPaused {
        // Mint GODL tokens for the user
        godlToken.mint(paxgAmount);
        // console.log("contract paxg balance", godlToken.balanceOf(address(this)));

        // Use the transfer function of the GODL contract to trigger the deflationary mechanism
        godlToken.transfer(to, paxgAmount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getUser(
        address user,
        uint256 referralCount_,
        uint256 referrals_
    ) public view returns (address, uint256, uint256, address[] memory) {
        User storage userStruct = users[user];
        return (
            userStruct.referrer,
            userStruct.level,
            userStruct.referralCount[referralCount_],
            userStruct.referrals[referrals_]
        );
    }

    function getDepositTiers() public view returns (uint256[] memory) {
        return depositTiers;
    }

    function getTierBonusPercentages()
        public
        view
        returns (uint256[][] memory)
    {
        return tierBonusPercentages;
    }

    function getTemporaryBalance(address user) public view returns (uint256) {
        return temporaryBalances[user];
    }

    function getReinvestFlag(address user) public view returns (bool) {
        return reinvestFlags[user];
    }

    // method to allow backend to iterate the entire reffereal tree of a user by levels (max5)
    function getReferralsAtLevel(
        address user,
        uint256 level
    ) public view returns (address[] memory) {
        return users[user].referrals[level];
    }

    function setWhitelistAddr(address addr) public onlyOwner {
        require(
            !isExistingUser[addr],
            "Address is already joined in the program"
        );
        whitelistAddr[addr] = true;
    }

    function isWhitelistAddr(address addr) public view returns (bool) {
        return whitelistAddr[addr];
    }
}
