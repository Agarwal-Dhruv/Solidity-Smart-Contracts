// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IAntiBot{

    function setAntiBotTimer(uint256 timer_) external;

    function setAntiBotEnabled(bool enabled_) external;

    function antiBotEndTime() external view returns(uint);

    function antiBotEnabled() external view returns(bool);

    function blacklistAddress(address address_) external;

    function removeBlacklistedAddress(address address_) external;

    function checkAddress(address address_) external view returns(bool);
}

contract AntiBot {

    uint256 private _antiBotEndTime;
    bool private _antiBotEnabled;

    mapping(address => bool) public _isBlacklisted;

    function setAntiBotTimer(uint256 timer_) public {
        require(antiBotEnabled(), "Anti-Bot not Activated");
        _antiBotEndTime = block.timestamp + timer_;
    }

    function setAntiBotEnabled(bool enabled_) public {
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