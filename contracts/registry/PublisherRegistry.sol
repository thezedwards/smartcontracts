pragma solidity ^0.4.0;

import "../zeppelin/ownership/Ownable.sol";

contract PublisherRegistry is Ownable{
    // This struct keeps all data for a publisher.
    struct Publisher {
        // Keeps the address of this record creator.
        address owner;
        // Keeps the time when this record was created.
        uint time;
        // Keeps the index of the keys array for fast lookup
        uint keysIndex;
        // publisher Address
        address publisherAddress;
    
        bytes32[3] url;

        uint256[2] karma;
    }

    // This mapping keeps the records of this Registry.
    mapping(address => Publisher) records;

    // Keeps the total numbers of records in this Registry.
    uint public numRecords;

    // Keeps a list of all keys to interate the records.
    address[] public keys;

    // This is the function that actually insert a record.
    function register(address key, bytes32[3] url) onlyOwner {
        if (records[key].time == 0) {
            records[key].time = now;
            records[key].owner = msg.sender;
            records[key].keysIndex = keys.length;
            records[key].publisherAddress = key;
            records[key].url = url;
            keys.length++;
            keys[keys.length - 1] = key;
            numRecords++;
        } else {
            throw;
        }
    }

    // Updates the values of the given record.
    function updateUrl(address key, bytes32[3] url) onlyOwner {
        // Only the owner can update his record.
        if (records[key].owner == msg.sender) {
            records[key].url = url;
        }
    }


    function applyKarmaDiff(address key, uint256[2] diff) {
        Publisher publisher = records[key];
        publisher.karma[0] += diff[0];
        publisher.karma[1] += diff[1];
    }

    // Unregister a given record
    function unregister(address key) onlyOwner {
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
    function transfer(address key, address newOwner) onlyOwner {
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

    function getPublisher(address key) returns(address publisherAddress, bytes32[3] url, uint time) {
        Publisher record = records[key];
        publisherAddress = record.publisherAddress;
        url = record.url;
        time = record.time;
    }

    // Returns the owner of the given record. The owner could also be get
    // by using the function getDSP but in that case all record attributes
    // are returned.
    function getOwner(address key) returns(address) {
        return records[key].owner;
    }

    // Returns the registration time of the given record. The time could also
    // be get by using the function getDSP but in that case all record attributes
    // are returned.
    function getTime(address key) returns(uint) {
        return records[key].time;
    }

    //@dev Get list of all registered publishers
    //@return Returns array of addresses registered as DSP with register times
    function getAllPublishers() returns(address[] addresses, bytes32[3][] urls, uint[] times) {
        addresses = new address[](numRecords);
        times = new uint[](numRecords);
        urls = new bytes32[3][](numRecords);
        uint i;
        for(i = 0; i < numRecords; i++) {
            Publisher publisher = records[keys[i]];
            addresses[i] = publisher.publisherAddress;
            urls[i] = publisher.url;
            times[i] = publisher.time;
        }
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}
