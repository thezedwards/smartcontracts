pragma solidity ^0.4.11;

import "../DepositRegistry.sol";
import "../../dao/DaoOwnable.sol";

// This is the base contract that your contract DepositRegistry extends from.
contract DepositRegistryImpl is DepositRegistry, DaoOwnable {

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
    function register(address key, uint256 amount) onlyDaoOrOwner {
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
    function unregister(address key) onlyDaoOrOwner {
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

    function hasEnough(address key, uint256 amount) constant returns(bool) {
        Deposit deposit = records[key];
        return deposit.amount >= amount;
    }

    function spend(address key, uint256 amount) onlyDaoOrOwner returns(bool){
        if (isRegistered(key) && hasEnough(key, amount)) {
            Deposit deposit = records[key];
            deposit.amount = deposit.amount - amount;
            return true;
        } else {
            return false;
        }
    }

    function refill(address key, uint256 amount) onlyDaoOrOwner {
        if (isRegistered(key)) {
            Deposit deposit = records[key];
            deposit.amount = deposit.amount + amount;
        } else {
            throw;
        }
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}