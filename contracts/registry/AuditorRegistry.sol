pragma solidity ^0.4.11;

contract AuditorRegistry {
    // This is the function that actually insert a record.
    function register(address key);

    function applyKarmaDiff(address key, uint256[2] diff);

    // Unregister a given record
    function unregister(address key);

    // Tells whether a given key is registered.
    function isRegistered(address key) returns(bool);

    function getAuditor(address key) returns(address auditorAddress, uint256[2] karma);

    //@dev Get list of all registered dsp
    //@return Returns array of addresses registered as DSP with register times
    function getAllAuditors() returns(address[] addresses, uint256[2][] karmas) ;

    function kill();
}
