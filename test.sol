//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Test {

    uint8 internal sum;

    function addNum(uint8 num1, uint8 num2) public pure{
        // sum=num1;
        // sum=sum+num2;
        unchecked {
            if((num1+num2)>256){revert("this exceeds uint8");}
        }
        
    }
    // function returnSum() public view returns(uint8) {
    //     return sum;
    // }

}