pragma solidity ^0.4.11;

import "../../dao/DaoOwnable.sol";
import "../AuditorRegistry.sol";

// This is the base contract that your contract AuditorRegistry extends from.
contract AuditorRegistryImpl is AuditorRegistry, DaoOwnable {

    uint public creationTime = now;

    // This struct keeps all data for a Auditor.
    struct Auditor {
        // Keeps the address of this record creator.
        address owner;
        // Keeps the time when this record was created.
        uint time;
        // Keeps the index of the keys array for fast lookup
        uint keysIndex;
        // Auditor Address
        address auditorAddress;

        uint256[2] karma;
    }

    // This mapping keeps the records of this Registry.
    mapping(address => Auditor) records;

    // Keeps the total numbers of records in this Registry.
    uint public numRecords;

    // Keeps a list of all keys to interate the records.
    address[] public keys;

    // This is the function that actually insert a record.
    function register(address key) onlyDaoOrOwner {
        if (records[key].time == 0) {
            records[key].time = now;
            records[key].owner = msg.sender;
            records[key].keysIndex = keys.length;
            records[key].auditorAddress = key;
            keys.length++;
            keys[keys.length - 1] = key;
            numRecords++;
        } else {
            throw;
        }
    }

    function applyKarmaDiff(address key, uint256[2] diff) onlyDaoOrOwner {
        Auditor auditor = records[key];
        auditor.karma[0] += diff[0];
        auditor.karma[1] += diff[1];
    }

    // Unregister a given record
    function unregister(address key) onlyDaoOrOwner {
        if (records[key].owner == msg.sender) {
            uint keysIndex = records[key].keysIndex;
            delete records[key];
            numRecords--;
            keys[keysIndex] = keys[keys.length - 1];
            records[keys[keysIndex]].keysIndex = keysIndex;
            keys.length--;
        }
    }

    // Transfer ownership of a given record.
    function transfer(address key, address newOwner) onlyDaoOrOwner {
        if (records[key].owner == msg.sender) {
            records[key].owner = newOwner;
        } else {
            throw;
        }
    }

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool) {
        return records[key].time != 0;
    }

    function getAuditor(address key) constant returns(address auditorAddress, uint256[2] karma) {
        Auditor record = records[key];
        auditorAddress = record.auditorAddress;
        karma = record.karma;
    }

    // Returns the owner of the given record. The owner could also be get
    // by using the function getAuditor but in that case all record attributes
    // are returned.
    function getOwner(address key) constant returns(address) {
        return records[key].owner;
    }

    // Returns the registration time of the given record. The time could also
    // be get by using the function getAuditor but in that case all record attributes
    // are returned.
    function getTime(address key) constant returns(uint) {
        return records[key].time;
    }

    //@dev Get list of all registered auditor
    //@return Returns array of addresses registered as Auditor with register times
    function getAllAuditors() constant returns(address[] addresses, uint256[2][] karmas) {
        addresses = new address[](numRecords);
        karmas = new uint256[2][](numRecords);
        uint i;
        for(i = 0; i < numRecords; i++) {
            Auditor auditor = records[keys[i]];
            addresses[i] = auditor.auditorAddress;
            karmas[i] = auditor.karma;
        }
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}