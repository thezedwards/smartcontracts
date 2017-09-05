pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";

// This is the base contract that your contract DSPRegistry extends from.
contract DSPRegistry {

    // This is the function that actually insert a record.
    function register(address key, bytes32[3] url);

    // Updates the values of the given record.
    function updateUrl(address key, bytes32[3] url);

    function applyKarmaDiff(address key, uint256[2] diff);

    // Unregister a given record
    function unregister(address key);

    // Tells whether a given key is registered.
    function isRegistered(address key) returns(bool);

    function getDSP(address key) returns(address dspAddress, bytes32[3] url, uint time);

    //@dev Get list of all registered dsp
    //@return Returns array of addresses registered as DSP with register times
    function getAllDSP() returns(address[] addresses, bytes32[3][] urls, uint[] times) ;

    function kill();
}