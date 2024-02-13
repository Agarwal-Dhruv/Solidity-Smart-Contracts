pragma solidity 0.8.0;
contract Wallet {
    address public owner;
    uint public foo;

    constructor(address addr,uint x){
        owner = addr;
        foo = x;
    }
}