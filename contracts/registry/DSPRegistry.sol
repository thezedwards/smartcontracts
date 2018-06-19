pragma solidity ^0.4.18;

import "./DSPTypeAware.sol";


// This is the base contract that your contract DSPRegistry extends from.
contract DSPRegistry is DSPTypeAware {

    // This is the function that actually insert a record.
    function register(address key, DSPType dspType, bytes32[5] url, address recordOwner, bytes masterKeyPublic) public;

    // Updates the values of the given record.
    function updateUrl(address key, bytes32[5] url, address sender) public;

    function applyKarmaDiff(address key, uint256[2] diff) public;

    // Unregister a given record
    function unregister(address key, address sender) public;

    // Transfer ownership of a given record.
    function transfer(address key, address newOwner, address sender) public;

    function getOwner(address key) public view returns (address);

    // Tells whether a given key is registered.
    function isRegistered(address key) public view returns (bool);

    function getMemberCount() public view returns (uint256);

    function getMemberAddress(uint256 index) public view returns (address);

    function getMember(address key) public view returns (address dspAddress, DSPType dspType, bytes32[5] url, uint256[2] karma, address recordOwner, bytes masterKeyPublic);

    function kill() public;
}
