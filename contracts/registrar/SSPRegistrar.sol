pragma solidity ^0.4.11;

import "../registry/SSPRegistry.sol";
import "../registry/SSPRegistry.sol";
import "./SecurityDepositAware.sol";
import "../registry/impl/SecurityDepositRegistry.sol";

contract SSPRegistrar is SecurityDepositAware{
    SSPRegistry public sspRegistry;

    event SSPRegistered(address sspAddress);
    event SSPUnregistered(address sspAddress);

    //@dev Retrieve information about registered SSP
    //@return Address of registered SSP and time when registered
    function findSsp(address sspAddr) constant returns(address sspAddress, uint16 publisherFee, uint256[2] karma) {
        return sspRegistry.getSSP(sspAddr);
    }

    //@dev Register organisation as SSP
    //@param sspAddress address of wallet to register
    function registerSsp(address sspAddress, uint16 publisherFee) {
        if (!sspRegistry.isRegistered(sspAddress)) {
            receiveSecurityDeposit(sspAddress);
            sspRegistry.register(sspAddress, publisherFee);
            SSPRegistered(sspAddress);
        }
    }

    function isSspRegistered(address key) constant returns(bool) {
        return sspRegistry.isRegistered(key);
    }

    //@dev Unregister SSP and return unused deposit
    //@param Address of SSP to be unregistered
    function unregisterSsp(address sspAddress) {
        if (sspRegistry.isRegistered(sspAddress)) {
            returnDeposit(sspAddress, securityDepositRegistry);
            sspRegistry.unregister(sspAddress);
            SSPUnregistered(sspAddress);
        }
    }

    function getSspRegistryFromRegistrar() constant returns (SSPRegistry) {
        return sspRegistry;
    }
}
