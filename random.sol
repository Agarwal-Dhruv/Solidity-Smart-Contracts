//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Random{
    function getRandom() public view returns(uint256){
        return block.prevrandao;
    }
    function getRandom1() public view returns(uint256){
        return block.prevrandao;
    }
}