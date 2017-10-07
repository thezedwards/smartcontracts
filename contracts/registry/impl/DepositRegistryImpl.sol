pragma solidity ^0.4.11;

import "../DepositRegistry.sol";
import "../../dao/DaoOwnable.sol";
import '../../common/SafeMath.sol';

// This is the base contract that your contract DepositRegistry extends from.
contract DepositRegistryImpl is DepositRegistry, DaoOwnable {
    using SafeMath for uint256;

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
    function register(address key, uint256 amount, address depositOwner) onlyDaoOrOwner {
        require(records[key].time == 0);
        records[key].time = now;
        records[key].owner = depositOwner;
        records[key].keysIndex = keys.length;
        keys.length++;
        keys[keys.length - 1] = key;
        records[key].amount = amount;
        numDeposits++;
    }

    // Unregister a given record
    function unregister(address key, address sender) onlyDaoOrOwner {
        require(records[key].owner == sender);
        uint keysIndex = records[key].keysIndex;
        delete records[key];
        numDeposits--;
        keys[keysIndex] = keys[keys.length - 1];
        records[keys[keysIndex]].keysIndex = keysIndex;
        keys.length--;
    }

    // Transfer ownership of a given record.
    function transfer(address key, address newOwner, address sender) onlyDaoOrOwner {
        require(records[key].owner == sender);
        records[key].owner = newOwner;
    }

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool) {
        return records[key].time != 0;
    }

    function getDepositOwner(address key) constant returns (address) {
        return records[key].owner;
    }

    function getDeposit(address key) constant returns(uint256 amount) {
        Deposit storage record = records[key];
        amount = record.amount;
    }

    function getDepositRecord(address key) constant returns(address owner, uint time, uint256 amount, address depositOwner) {
        Deposit storage record = records[key];
        owner = record.owner;
        time = record.time;
        amount = record.amount;
        depositOwner = record.owner;
    }

    function hasEnough(address key, uint256 amount) constant returns(bool) {
        Deposit storage deposit = records[key];
        return deposit.amount >= amount;
    }

    function spend(address key, uint256 amount) onlyDaoOrOwner {
        require(isRegistered(key));
        records[key].amount = records[key].amount.sub(amount);
    }

    function refill(address key, uint256 amount) onlyDaoOrOwner {
        require(isRegistered(key));
        records[key].amount = records[key].amount.add(amount);
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}