//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Callback  {

    uint x = 2;

    function x_ () public returns(uint256) {
        return x + 1;
    }

    // uint y = x_();

    function y_ (uint y) public returns(uint256){
        return x_() * 2;
    }

    // function z_ () public returns(uint){
    //     return y_(x_());
    // }

    uint public z = y_(x_());
}