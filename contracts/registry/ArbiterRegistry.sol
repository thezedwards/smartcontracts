pragma solidity ^0.4.11;

import '../lib/ArbiterSorter.sol';

// This is the base contract that your contract ArbiterRegistry extends from.
contract ArbiterRegistry {

    uint8 public constant trustedArbitersNumber = 10;

    // The owner of this registry.
    address public owner = msg.sender;

    uint public creationTime = now;

    // This struct keeps all data for a Arbiter.
    struct Arbiter {
        // Keeps the address of this record creator.
        address owner;
        // Keeps the time when this record was created.
        uint time;
        // Keeps the index of the keys array for fast lookup
        uint keysIndex;
        //int representation of arbiter karma
        uint64 karma;
    }

    // This mapping keeps the arbiters
    mapping(address => Arbiter) arbiters;

    // Keeps the total numbers of arbiters in this Registry.
    uint public numArbiters;

    // Keeps a list of all keys to interate the arbiters.
    address[] public keys;

    //Those with biggest karma
    Arbiter[] public mostTrusted;

    uint public numTrusted;

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }



    // This is the function that actually insert a record. 
    function register(address key, uint64 karma) onlyOwner {
        if (arbiters[key].time == 0) {
            arbiters[key].time = now;
            arbiters[key].owner = msg.sender;
            arbiters[key].keysIndex = keys.length;
            keys.length++;
            keys[keys.length - 1] = key;
            arbiters[key].karma = karma;
            numArbiters++;
        
            mostTrusted.length++;
            mostTrusted[mostTrusted.length - 1] = arbiters[key];
            numTrusted++;
            ArbiterSorter.sort(mostTrusted);
            if (numTrusted > trustedArbitersNumber) {
                mostTrusted.length--;
            }
        } else {
            throw;
        }
    }

    // Updates the values of the given record.
    function update(address key, uint64 karma) {
        // Only the owner can update his record.
        if (arbiters[key].owner == msg.sender) {
            arbiters[key].karma = karma;
        }
        ArbiterSorter.sort(mostTrusted);
    }

    // Tells whether a given key is registered.
    function isRegistered(address key) returns(bool) {
        return arbiters[key].time != 0;
    }

    function getArbiter(address key) returns(address owner, uint time, uint64 karma) {
        Arbiter arbiter = arbiters[key];
        owner = arbiter.owner;
        time = arbiter.time;
        karma = arbiter.karma;
    }

    // Returns the owner of the given record. The owner could also be get
    // by using the function getRecord but in that case all record attributes 
    // are returned.
    function getOwner(address key) returns(address) {
        return arbiters[key].owner;
    }

    // Returns the registration time of the given record. The time could also
    // be get by using the function getRecord but in that case all record attributes
    // are returned.
    function getTime(address key) returns(uint) {
        return arbiters[key].time;
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}
