pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";

// This is the base contract that your contract DSPRegistry extends from.
contract DSPRegistry is Ownable {

    uint public creationTime = now;

    // This struct keeps all data for a DSP.
    struct DSP {
        // Keeps the address of this record creator.
        address owner;
        // Keeps the time when this record was created.
        uint time;
        // Keeps the index of the keys array for fast lookup
        uint keysIndex;
        // DSP Address
        address dspAddress;
    }

    // This mapping keeps the records of this Registry.
    mapping(address => DSP) records;

    // Keeps the total numbers of records in this Registry.
    uint public numRecords;

    // Keeps a list of all keys to interate the records.
    address[] public keys;

    // This is the function that actually insert a record.
    function register(address key) onlyOwner {
        if (records[key].time == 0) {
            records[key].time = now;
            records[key].owner = msg.sender;
            records[key].keysIndex = keys.length;
            records[key].dspAddress = key;
            keys.length++;
            keys[keys.length - 1] = key;
            numRecords++;
        } else {
            throw;
        }
    }

    // Updates the values of the given record.
    function update(address key) onlyOwner {
        // Only the owner can update his record.
        if (records[key].owner == msg.sender) {
            // Something could be here
        }
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

    function getDSP(address key) returns(address dspAddress, uint time) {
        DSP record = records[key];
        dspAddress = record.dspAddress;
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

    //@dev Get list of all registered dsp
    //@return Returns array of addresses registered as DSP with register times
    function getAllDSP() returns(address[] addresses, uint[] times) {
        addresses = new address[](numRecords);
        times = new uint[](numRecords);
        uint i;
        for(i = 0; i < numRecords; i++) {
            DSP dsp = records[keys[i]];
            addresses[i] = dsp.dspAddress;
            times[i] = dsp.time;
        }
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}