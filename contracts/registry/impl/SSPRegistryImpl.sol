pragma solidity ^0.4.18;

import "../../dao/DaoOwnable.sol";
import "../SSPRegistry.sol";


// This is the base contract that your contract SSPRegistry extends from.
contract SSPRegistryImpl is SSPRegistry, DaoOwnable {

  // STRUCTURES

  // This struct keeps all data for a SSP.
  struct SSP {
    // Keeps the address of this record creator.
    address owner;
    // Keeps the time when this record was created.
    uint256 time;
    // Keeps the index of the keys array for fast lookup
    uint256 keysIndex;
    // SSP Address
    address sspAddress;

    SSPType sspType;

    uint16 publisherFee;

    bytes masterKeyPublic;

    uint256[2] karma;
  }

  // PUBLIC FUNCTIONS

  // This is the function that actually insert a record.
  function register(address key, SSPType sspType, uint16 publisherFee, address recordOwner, bytes masterKeyPublic) public onlyDaoOrOwner {
    require(records[key].time == 0);
    records[key].time = now;
    records[key].owner = recordOwner;
    records[key].keysIndex = keys.length;
    records[key].sspAddress = key;
    records[key].sspType = sspType;
    records[key].publisherFee = publisherFee;
    records[key].masterKeyPublic = masterKeyPublic;
    keys.length++;
    keys[keys.length - 1] = key;
    numRecords++;
  }

  // Updates the values of the given record.
  function updatePublisherFee(address key, uint16 newFee, address sender) public onlyDaoOrOwner {
    // Only the owner can update his record.
    require(records[key].owner == sender);
    records[key].publisherFee = newFee;
  }

  function applyKarmaDiff(address key, uint256[2] diff) public onlyDaoOrOwner {
    SSP storage ssp = records[key];
    ssp.karma[0] += diff[0];
    ssp.karma[1] += diff[1];
  }

  // Unregister a given record
  function unregister(address key, address sender) public onlyDaoOrOwner {
    require(records[key].owner == sender);
    uint256 keysIndex = records[key].keysIndex;
    delete records[key];
    numRecords--;
    keys[keysIndex] = keys[keys.length - 1];
    records[keys[keysIndex]].keysIndex = keysIndex;
    keys.length--;
  }

  // Transfer ownership of a given record.
  function transfer(address key, address newOwner, address sender) public onlyDaoOrOwner {
    require(records[key].owner == sender);
    records[key].owner = newOwner;
  }

  // Tells whether a given key is registered.
  function isRegistered(address key) public view returns (bool) {
    return records[key].time != 0;
  }

  function getMemberCount() public view returns (uint256) {
    return keys.length;
  }

  function getMemberAddress(uint256 index) public view returns (address) {
    return keys[index];
  }

  function getMember(address key) public view returns (address sspAddress, SSPType sspType, uint16 publisherFee, uint256[2] karma, address recordOwner, bytes masterKeyPublic) {
    SSP storage record = records[key];
    sspAddress = record.sspAddress;
    sspType = record.sspType;
    publisherFee = record.publisherFee;
    karma = record.karma;
    recordOwner = record.owner;
    masterKeyPublic = record.masterKeyPublic;
  }

  // Returns the owner of the given record. The owner could also be get
  // by using the function getSSP but in that case all record attributes
  // are returned.
  function getOwner(address key) public view returns (address) {
    return records[key].owner;
  }

  // Returns the registration time of the given record. The time could also
  // be get by using the function getSSP but in that case all record attributes
  // are returned.
  function getTime(address key) public view returns (uint256) {
    return records[key].time;
  }

  function kill() public onlyOwner {
    selfdestruct(owner);
  }

  // FIELDS

  // This mapping keeps the records of this Registry.
  mapping(address => SSP) records;

  // Keeps the total numbers of records in this Registry.
  uint256 public numRecords;

  // Keeps a list of all keys to interate the records.
  address[] public keys;
}
