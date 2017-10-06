pragma solidity ^0.4.11;

contract AuditorRegistry {
    // This is the function that actually insert a record.
    function register(address key, address recordOwner);

    function applyKarmaDiff(address key, uint256[2] diff);

    // Unregister a given record
    function unregister(address key, address sender);

    //Transfer ownership of record
    function transfer(address key, address newOwner, address sender);

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool);

    function getAuditor(address key) constant returns(address auditorAddress, uint256[2] karma, address recordOwner);

    //@dev Get list of all registered dsp
    //@return Returns array of addresses registered as DSP with register times
    function getAllAuditors() constant returns(address[] addresses, uint256[2][] karmas, address[] recordOwners);

    function kill();
}
