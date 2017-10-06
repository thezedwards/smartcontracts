pragma solidity ^0.4.11;

// This is the base contract that your contract DepositRegistry extends from.
contract DepositRegistry {
    // This is the function that actually insert a record.
    function register(address key, uint256 amount, address depositOwner);

    // Unregister a given record
    function unregister(address key, address sender);

    function transfer(address key, address newOwner, address sender);

    function spend(address key, uint256 amount);

    function refill(address key, uint256 amount);

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool);

    function getDepositOwner(address key) constant returns(address);

    function getDeposit(address key) constant returns(uint256 amount);

    function getDepositRecord(address key) constant returns(address owner, uint time, uint256 amount, address depositOwner);

    function hasEnough(address key, uint256 amount) constant returns(bool);

    function kill();
}