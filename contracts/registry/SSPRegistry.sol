pragma solidity ^0.4.11;

contract SSPRegistry {
    // This is the function that actually insert a record.
    function register(address key, uint16 publisherFee);

    // Updates the values of the given record.
    function updatePublisherFee(address key, uint16 newFee);

    function applyKarmaDiff(address key, uint256[2] diff);

    // Unregister a given record
    function unregister(address key);

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool);

    function getSSP(address key) constant returns(address sspAddress, uint16 publisherFee, uint256[2] karma);

    function getAllSSP() constant returns(address[] addresses, uint16[] publisherFees, uint256[2][] karmas);

    function kill();
}