pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";

// This is the base contract that your contract DepositRegistry extends from.
contract DepositRegistry is Ownable {
    // This is the function that actually insert a record.
    function register(address key, uint256 amount);

    // Unregister a given record
    function unregister(address key);

    // Tells whether a given key is registered.
    function isRegistered(address key) returns(bool);

    function getDeposit(address key) returns(uint256 amount);

    function getDepositRecord(address key) returns(address owner, uint time, uint256 amount);

    function hasEnough(address key, uint256 amount) constant returns(bool);

    function spend(address key, uint256 amount) onlyOwner returns(bool);

    function refill(address key, uint256 amount);

    function kill();
}