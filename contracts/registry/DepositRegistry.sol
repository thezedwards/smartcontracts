pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";

// This is the base contract that your contract DepositRegistry extends from.
contract DepositRegistry is Ownable {

    // The owner of this registry.
    address public owner = msg.sender;

    uint public creationTime = now;

    // This struct keeps all data for a Deposit.
    struct Deposit {
        // Keeps the address of this record creator.
        address owner;
        // Keeps the time when this record was created.
        uint time;
        // Keeps the index of the keys array for fast lookup
        uint keysIndex;
        // Deposit left
        uint256 amount;
    }

    // This mapping keeps the records of this Registry.
    mapping(address => Deposit) records;

    // Keeps the total numbers of records in this Registry.
    uint public numDeposits;

    // Keeps a list of all keys to interate the records.
    address[] public keys;

    // This is the function that actually insert a record. 
    function register(address key, uint256 amount) onlyOwner {
        if (records[key].time == 0) {
            records[key].time = now;
            records[key].owner = msg.sender;
            records[key].keysIndex = keys.length;
            keys.length++;
            keys[keys.length - 1] = key;
            records[key].amount = amount;
            numDeposits++;
        } else {
            throw;
        }
    }

    // Unregister a given record
    function unregister(address key) onlyOwner {
        if (records[key].owner == msg.sender) {
            uint keysIndex = records[key].keysIndex;
            delete records[key];
            numDeposits--;
            keys[keysIndex] = keys[keys.length - 1];
            records[keys[keysIndex]].keysIndex = keysIndex;
            keys.length--;
        }
    }

    // Transfer ownership of a given record.
    function transfer(address key, address newOwner) {
        if (records[key].owner == msg.sender) {
            records[key].owner = newOwner;
        } else {
            throw;
        }
    }

    // Tells whether a given key is registered.
    function isRegistered(address key) returns(bool) {
        return records[key].time != 0;
    }

    function getDeposit(address key) returns(uint256 amount) {
        Deposit record = records[key];
        amount = record.amount;
    }

    function getDepositRecord(address key) returns(address owner, uint time, uint256 amount) {
        Deposit record = records[key];
        owner = record.owner;
        time = record.time;
        amount = record.amount;
    }

    // Returns the registration time of the given record. The time could also
    // be get by using the function getDeposit but in that case all record attributes
    // are returned.
    function getTime(address key) returns(uint) {
        return records[key].time;
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}