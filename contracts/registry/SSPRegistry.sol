pragma solidity ^0.4.11;

import "./SSPTypeAware.sol";

contract SSPRegistry is SSPTypeAware{
    // This is the function that actually insert a record.
    function register(address key, SSPType sspType, uint16 publisherFee, address recordOwner);

    // Updates the values of the given record.
    function updatePublisherFee(address key, uint16 newFee, address sender);

    function applyKarmaDiff(address key, uint256[2] diff);

    // Unregister a given record
    function unregister(address key, address sender);

    //Transfer ownership of record
    function transfer(address key, address newOwner, address sender);

    function getOwner(address key) constant returns(address);

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool);

    function getSSP(address key) constant returns(address sspAddress, SSPType sspType, uint16 publisherFee, uint256[2] karma, address recordOwner);

    function getAllSSP() constant returns(address[] addresses, SSPType[] sspTypes, uint16[] publisherFees, uint256[2][] karmas, address[] recordOwners);

    function kill();
}