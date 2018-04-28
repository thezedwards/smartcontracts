pragma solidity ^0.4.18;

import "./SSPTypeAware.sol";


contract SSPRegistry is SSPTypeAware {

  // This is the function that actually insert a record.
  function register(address key, SSPType sspType, uint16 publisherFee, address recordOwner, bytes masterKeyPublic) public;

  // Updates the values of the given record.
  function updatePublisherFee(address key, uint16 newFee, address sender) public;

  function applyKarmaDiff(address key, uint256[2] diff) public;

  // Unregister a given record
  function unregister(address key, address sender) public;

  //Transfer ownership of record
  function transfer(address key, address newOwner, address sender) public;

  function getOwner(address key) public view returns (address);

  // Tells whether a given key is registered.
  function isRegistered(address key) public view returns (bool);

  function getMemberCount() public view returns (uint256);

  function getMemberAddress(uint256 index) public view returns (address);

  function getMember(address key) public view returns (address sspAddress, SSPType sspType, uint16 publisherFee, uint256[2] karma, address recordOwner, bytes masterKeyPublic);

  function kill() public;
}
