pragma solidity ^0.4.11;

contract PublisherRegistry {
    // This is the function that actually insert a record.
    function register(address key, bytes32[3] url);

    // Updates the values of the given record.
    function updateUrl(address key, bytes32[3] url);


    function applyKarmaDiff(address key, uint256[2] diff);

    // Unregister a given record
    function unregister(address key);

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool);

    function getPublisher(address key) constant returns(address publisherAddress, bytes32[3] url, uint256[2] karma);

    //@dev Get list of all registered publishers
    //@return Returns array of addresses registered as DSP with register times
    function getAllPublishers() constant returns(address[] addresses, bytes32[3][] urls, uint256[2][] karmas);

    function kill();
}
