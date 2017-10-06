pragma solidity ^0.4.11;

import "./DSPTypeAware.sol";

// This is the base contract that your contract DSPRegistry extends from.
contract DSPRegistry is DSPTypeAware{
    // This is the function that actually insert a record.
    function register(address key, DSPType dspType, bytes32[5] url, address recordOwner);

    // Updates the values of the given record.
    function updateUrl(address key, bytes32[5] url, address sender);

    function applyKarmaDiff(address key, uint256[2] diff);

    // Unregister a given record
    function unregister(address key, address sender);

    // Transfer ownership of a given record.
    function transfer(address key, address newOwner, address sender);

    // Tells whether a given key is registered.
    function isRegistered(address key) constant returns(bool);

    function getDSP(address key) constant returns(address dspAddress, DSPType dspType, bytes32[5] url, uint256[2] karma, address recordOwner);

    //@dev Get list of all registered dsp
    //@return Returns array of addresses registered as DSP with register times
    function getAllDSP() constant returns(address[] addresses, DSPType[] dspTypes, bytes32[5][] urls, uint256[2][] karmas, address[] recordOwners) ;

    function kill();
}