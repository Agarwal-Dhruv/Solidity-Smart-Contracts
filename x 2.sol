 // SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
 
contract x{

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

User public user;

    function setUser(uint a, uint b, uint c, bool tf, uint d, uint[] memory e, uint f, uint g, uint h) public{
        user.uniqueId = a;
        user.referrer = b;
        user.level = c;
        user.reinvestFlag = tf;
        user.referralCount[0] = d;
        user.referrals[0] = e;
        user.totalRewards = f;
        user.rewardBalance = g;
        user.registrationTime = h;
    }
}
