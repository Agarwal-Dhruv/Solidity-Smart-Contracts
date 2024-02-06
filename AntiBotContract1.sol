// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AntiBot {

    uint256 public _antiBotEndTime;
    bool public _antiBotEnabled;

    mapping(address => bool) public _isBlacklisted;

    function setAntiBotTimer(uint256 timer_) public {
        require(antiBotEnabled(), "Anti-Bot Not Activated");
        require(block.timestamp < antiBotEndTime(), "Already in Anti-Bot Time");
        timer_ = block.timestamp + timer_;
        _antiBotEndTime = timer_;
    }

    function setAntiBotEnabled(bool enabled_) public {
        require(!_antiBotEnabled, "Anti-Bot Already Activated");
        _antiBotEnabled = enabled_;
    }

    function antiBotEndTime() public view returns(uint) {
        return _antiBotEndTime;
    }

    function antiBotEnabled() public view returns(bool) {
        return _antiBotEnabled;
    }

    function blacklistAddress(address address_) public {
        _isBlacklisted[address_] = true;
    }

    function removeBlacklistedAddress(address address_) public {
        _isBlacklisted[address_] = false;
    }

    function checkAddress(address address_) public view returns(bool){
        return _isBlacklisted[address_];
    }
}
