pragma solidity ^0.4.11;

import "../registry/DSPRegistry.sol";
import "../registry/DSPTypeAware.sol";
import "./SecurityDepositAware.sol";

contract DSPRegistrar is DSPTypeAware, SecurityDepositAware {
    DSPRegistry public dspRegistry;

    event DSPRegistered(address dspAddress);
    event DSPUnregistered(address dspAddress);
    event DSPParametersChanged(address dspAddress);

    //@dev Retrieve information about registered DSP
    //@return Address of registered DSP and time when registered
    function findDsp(address addr) constant returns(address dspAddress, DSPType dspType, bytes32[5] url, uint256[2] karma, address recordOwner) {
        return dspRegistry.getDSP(addr);
    }

    //@dev Register organisation as DSP
    //@param dspAddress address of wallet to register
    function registerDsp(address dspAddress, DSPType dspType, bytes32[5] url) {
        receiveSecurityDeposit(dspAddress);
        dspRegistry.register(dspAddress, dspType, url, msg.sender);
        DSPRegistered(dspAddress);
    }

    //@dev check if DSP registered
    function isDspRegistered(address key) constant returns(bool) {
        return dspRegistry.isRegistered(key);
    }

    //@dev Unregister DSP and return unused deposit
    //@param Address of DSP to be unregistered
    function unregisterDsp(address dspAddress) {
        returnDeposit(dspAddress, securityDepositRegistry);
        dspRegistry.unregister(dspAddress, msg.sender);
        DSPUnregistered(dspAddress);
    }

    //@dev Change url of DSP
    //@param address of DSP to change
    //@param new url
    function updateUrl(address key, bytes32[5] url) {
        dspRegistry.updateUrl(key, url, msg.sender);
        DSPParametersChanged(key);
    }

    //@dev transfer ownership of this DSP record
    //@param address of DSP
    //@param address of new owner
    function transferDSPRecord(address key, address newOwner) {
        dspRegistry.transfer(key, newOwner, msg.sender);
    }
}
