pragma solidity ^0.4.11;

import "../registry/SSPRegistry.sol";
import "../registry/SSPRegistry.sol";
import "./SecurityDepositAware.sol";

contract SSPRegistrar is SecurityDepositAware{
    SSPRegistry internal sspRegistry;

    event SSPRegistered(address sspAddress);
    event SSPUnregistered(address sspAddress);

    //@dev Get direct link to SSPRegistry contract
    function getSspRegistry() constant returns(address sspRegistryAddress) {
        return sspRegistry;
    }

    //@dev Retrieve information about registered SSP
    //@return Address of registered SSP and time when registered
    function findSsp(address sspAddr) constant returns(address sspAddress, uint16 publisherFee, uint256[2] karma) {
        return sspRegistry.getSSP(sspAddr);
    }

    //@dev Register organisation as SSP
    //@param sspAddress address of wallet to register
    function registerSsp(address sspAddress, uint16 publisherFee) {
        if (!sspRegistry.isRegistered(sspAddress)) {
            if (receiveSecurityDeposit(sspAddress)) {
                sspRegistry.register(sspAddress, publisherFee);
                SSPRegistered(sspAddress);
            }
        }
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
}
