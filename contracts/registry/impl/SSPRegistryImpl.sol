pragma solidity ^0.4.11;

import "../../zeppelin/ownership/Ownable.sol";
import "../SSPRegistry.sol";


// This is the base contract that your contract SSPRegistry extends from.
contract SSPRegistryImpl is SSPRegistry, Ownable {

    uint public creationTime = now;

    // This struct keeps all data for a SSP.
    struct SSP {
    // Keeps the address of this record creator.
    address owner;
    // Keeps the time when this record was created.
    uint time;
    // Keeps the index of the keys array for fast lookup
    uint keysIndex;
    // SSP Address
    address sspAddress;

    uint16 publisherFee;

    uint256[2] karma;
    }

    // This mapping keeps the records of this Registry.
    mapping(address => SSP) records;

    // Keeps the total numbers of records in this Registry.
    uint public numRecords;

    // Keeps a list of all keys to interate the records.
    address[] public keys;

    // This is the function that actually insert a record.
    function register(address key, uint16 publisherFee) {
        if (records[key].time == 0) {
            records[key].time = now;
            records[key].owner = msg.sender;
            records[key].keysIndex = keys.length;
            records[key].sspAddress = key;
            records[key].publisherFee = publisherFee;
            keys.length++;
            keys[keys.length - 1] = key;
            numRecords++;
        } else {
            throw;
        }
    }

    // Updates the values of the given record.
    function updatePublisherFee(address key, uint16 newFee) onlyOwner {
        // Only the owner can update his record.
        if (records[key].owner == msg.sender) {
            records[key].publisherFee = newFee;
        }
    }

    function applyKarmaDiff(address key, uint256[2] diff) {
        SSP ssp = records[key];
        ssp.karma[0] += diff[0];
        ssp.karma[1] += diff[1];
    }

    // Unregister a given record
    function unregister(address key) {
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

    function getSSP(address key) returns(address sspAddress, uint16 publisherFee, uint256[2] karma) {
        SSP record = records[key];
        sspAddress = record.sspAddress;
        publisherFee = record.publisherFee;
        karma = record.karma;
    }

    // Returns the owner of the given record. The owner could also be get
    // by using the function getSSP but in that case all record attributes
    // are returned.
    function getOwner(address key) returns(address) {
        return records[key].owner;
    }

    function getAllSSP() returns(address[] addresses, uint16[] publisherFees, uint256[2][] karmas) {
        addresses = new address[](numRecords);
        publisherFees = new uint16[](numRecords);
        karmas = new uint256[2][](numRecords);
        uint i;
        for(i = 0; i < numRecords; i++) {
            SSP ssp = records[keys[i]];
            addresses[i] = ssp.sspAddress;
            publisherFees[i] = ssp.publisherFee;
            karmas[i] = ssp.karma;
        }
    }

    // Returns the registration time of the given record. The time could also
    // be get by using the function getSSP but in that case all record attributes
    // are returned.
    function getTime(address key) returns(uint) {
        return records[key].time;
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}