//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Test {

    function addNum(uint8 num1, uint8 num2) public pure {
        uint256 x = uint256(num1);
        uint256 y = uint256(num2);
        uint256 temp = x+y;
        if((temp)>2**8){revert("this exceeds uint8");}
    }

    function subNum(uint8 num1,uint8 num2) public pure returns(uint256){
        uint256 x = uint256(num1);
        uint256 y = uint256(num2);
        uint256 temp = x-y;
        return temp;
    }

    // function multiplyNum(uint8 num1,uint8 num2) public pure {
    //     unchecked{
    //     }
    // }

    // function dividenum(uint8 num1,uint8 num2) public pure {
    //     unchecked{
    //     }
    // }
}