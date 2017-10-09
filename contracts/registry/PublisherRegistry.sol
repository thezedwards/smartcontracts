pragma solidity ^0.4.11;

contract PublisherRegistry {
    // This is the function that actually insert a record.
    function register(address key, bytes32[5] url, address recordOwner);

    // Updates the values of the given record.
    function updateUrl(address key, bytes32[5] url, address sender);

    function applyKarmaDiff(address key, uint256[2] diff);

    // Unregister a given record
    function unregister(address key, address sender);

    //Transfer ownership of record
    function transfer(address key, address newOwner, address sender);

    function getOwner(address key) constant returns(address);

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool);

    function getPublisher(address key) constant returns(address publisherAddress, bytes32[5] url, uint256[2] karma, address recordOwner);

    //@dev Get list of all registered publishers
    //@return Returns array of addresses registered as DSP with register times
    function getAllPublishers() constant returns(address[] addresses, bytes32[5][] urls, uint256[2][] karmas, address[] recordOwners);

    function kill();
}
