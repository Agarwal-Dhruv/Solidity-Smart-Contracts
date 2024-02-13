/**
 * a1matic
 *
 * author: Usquare NewTech Pvt. Ltd. - Dhruv Agarwal
 * 
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract a1matic is Ownable{

    mapping(address => uint256) private userBalance;
    address payable public creatorFeeAddress;
    uint8 public creatorFeePercentage;

    address payable public feeAddress;
    uint8 public feePercentage;

    function setCreatorFeeAddress(address payable _addr) public onlyOwner {
        creatorFeeAddress = _addr;
    }

    function setCreatorFeePercentage(uint8 _amt) public onlyOwner {
        creatorFeePercentage = _amt;
    }


    function setFeeAddress(address payable _addr) public onlyOwner {
        feeAddress = _addr;
    }

    function setFeePercentage(uint8 _amt) public onlyOwner {
        feePercentage = _amt;
    }


    function deposit() public payable{
        uint256 creatorFeeAmount = (msg.value * creatorFeePercentage) / 100;
        uint256 feeAmount = (msg.value * feePercentage) / 100;

        userBalance[msg.sender] += msg.value - creatorFeeAmount;
        userBalance[msg.sender] -= feeAmount;

        creatorFeeAddress.transfer(creatorFeeAmount);
        feeAddress.transfer(feeAmount);
    }

    function getUserBalance(address _addr) public view returns (uint256) {
        return(userBalance[_addr]);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function Withdraw(uint256 _amount) public {

        require(getContractBalance() >= _amount,"ERROR: Insufficient contract balance!");
        require(userBalance[msg.sender]>= _amount,"ERROR: Insufficient user balance!");

        payable(msg.sender).transfer(_amount);

        userBalance[msg.sender]-=_amount;
    }

    function withdrawOwner(uint256 _amount) public onlyOwner{

        require(getContractBalance() >= _amount,"ERROR: Insufficient contract balance!");

        payable(owner()).transfer(_amount);
    }

}