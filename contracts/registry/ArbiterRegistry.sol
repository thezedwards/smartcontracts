pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";
import "../dao/Arbiter.sol";

// This is the base contract that your contract ArbiterRegistry extends from.
contract ArbiterRegistry is Ownable{

    uint8 public constant trustedArbitersNumber = 10;

    struct ArbiterBean {
        Arbiter arbiter;
        bool exists;
    }

    // This mapping keeps the arbiters
    mapping(address => ArbiterBean) arbiters;

    // Keeps the total numbers of arbiters in this Registry.
    uint public numArbiters;

    // Keeps a list of all keys to interate the arbiters.
    address[] public keys;

    //Those with biggest karma
    Arbiter[] public mostTrusted;

    mapping(address => ArbiterBean) mostTrustedIndex;

    // This is the function that actually insert a record.
    function register(Arbiter arbiter) onlyOwner {
        address addr = address(arbiter);
        if (!arbiters[addr].exists) {
            keys.length++;
            keys[keys.length - 1] = addr;
            arbiters[addr] = ArbiterBean(arbiter, true);
            numArbiters++;
            checkTrusted(arbiter);
        } else {
            throw;
        }
    }

    function checkTrusted(Arbiter arbiter) private {
        if (mostTrusted.length < trustedArbitersNumber || mostTrusted[mostTrusted.length - 1].karma() <= arbiter.karma()) {
            if (!mostTrustedIndex[arbiter.arbiterAddress()].exists) {
                mostTrusted.push(arbiters[address(arbiter)].arbiter);
            }
            sortTrusted();
            if (mostTrusted.length > trustedArbitersNumber) {
                mostTrusted.length--;
            }
        }
    }

    // Tells whether a given key is registered.
    function isRegistered(address key) returns(bool) {
        return arbiters[key].exists;
    }

    function getArbiter(address key) returns(address arbiterAddress, int karma) {
        Arbiter arbiter = arbiters[key].arbiter;
        arbiterAddress = arbiter.arbiterAddress();
        karma = arbiter.karma();
    }

    function getRandomArbiters(uint8 number) returns (address[] arbiterAddresses) {
        for (uint8 i = 0; i < number; i++) {

        }
    }

    function sortTrusted() {

        uint n = mostTrusted.length;
        Arbiter[] memory arr = new Arbiter[](n);
        uint i;

        for (i = 0; i < n; i++) {
            arr[i] = mostTrusted[i];
        }

        Arbiter key;
        uint j;

        for (i = 1; i < arr.length; i++) {
            key = arr[i];

            for (j = i; j > 0 && arr[j - 1].karma() < key.karma(); j--) {
                arr[j] = arr[j - 1];
            }

            arr[j] = key;
        }

        for (i = 0; i < n; i++) {
            mostTrusted[i] = arr[i];
        }

    }

    function random(uint32 max) private returns (uint) {
        uint random = uint(block.blockhash(block.number-1)) % max + 1;
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}
