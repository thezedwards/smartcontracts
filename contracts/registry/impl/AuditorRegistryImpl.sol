pragma solidity ^0.4.18;

import "../../dao/DaoOwnable.sol";
import "../AuditorRegistry.sol";


// This is the base contract that your contract AuditorRegistry extends from.
contract AuditorRegistryImpl is AuditorRegistry, DaoOwnable {

  // STRUCTURES

  // This struct keeps all data for a Auditor.
  struct Auditor {
    // Keeps the address of this record creator.
    address owner;
    // Keeps the time when this record was created.
    uint256 time;
    // Keeps the index of the keys array for fast lookup
    uint256 keysIndex;
    // Auditor Address
    address auditorAddress;

    bytes masterKeyPublic;

    uint256[2] karma;
  }

  // PUBLIC FUNCTIONS

  // This is the function that actually insert a record.
  function register(address key, address recordOwner, bytes masterKeyPublic) public onlyDaoOrOwner {
    require(records[key].time == 0);
    records[key].time = now;
    records[key].owner = recordOwner;
    records[key].keysIndex = keys.length;
    records[key].auditorAddress = key;
    records[key].masterKeyPublic = masterKeyPublic;
    keys.length++;
    keys[keys.length - 1] = key;
    numRecords++;
  }

  function applyKarmaDiff(address key, uint256[2] diff) public onlyDaoOrOwner {
    Auditor storage auditor = records[key];
    auditor.karma[0] += diff[0];
    auditor.karma[1] += diff[1];
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

  function getMember(address key) public view returns (address auditorAddress, uint256[2] karma, address recordOwner, bytes masterKeyPublic) {
    Auditor storage record = records[key];
    auditorAddress = record.auditorAddress;
    karma = record.karma;
    recordOwner = record.owner;
    masterKeyPublic = record.masterKeyPublic;
  }

  // Returns the owner of the given record. The owner could also be get
  // by using the function getAuditor but in that case all record attributes
  // are returned.
  function getOwner(address key) public view returns (address) {
    return records[key].owner;
  }

  // Returns the registration time of the given record. The time could also
  // be get by using the function getAuditor but in that case all record attributes
  // are returned.
  function getTime(address key) public view returns (uint256) {
    return records[key].time;
  }

  function kill() public onlyOwner {
      selfdestruct(owner);
  }

  // FIELDS

  // This mapping keeps the records of this Registry.
  mapping(address => Auditor) records;

  // Keeps the total numbers of records in this Registry.
  uint256 public numRecords;

  // Keeps a list of all keys to interate the records.
  address[] public keys;
}
