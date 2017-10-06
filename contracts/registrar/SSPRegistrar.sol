pragma solidity ^0.4.11;

import "../registry/SSPRegistry.sol";
import "../registry/SSPTypeAware.sol";
import "./SecurityDepositAware.sol";

contract SSPRegistrar is SSPTypeAware, SecurityDepositAware{
    SSPRegistry public sspRegistry;

    event SSPRegistered(address sspAddress);
    event SSPUnregistered(address sspAddress);
    event SSPParametersChanged(address sspAddress);

    //@dev Retrieve information about registered SSP
    //@return Address of registered SSP and time when registered
    function findSsp(address sspAddr) constant returns(address sspAddress, SSPType sspType, uint16 publisherFee, uint256[2] karma, address recordOwner) {
        return sspRegistry.getSSP(sspAddr);
    }

    //@dev Register organisation as SSP
    //@param sspAddress address of wallet to register
    function registerSsp(address sspAddress, SSPType sspType, uint16 publisherFee) {
        receiveSecurityDeposit(sspAddress);
        sspRegistry.register(sspAddress, sspType, publisherFee, msg.sender);
        SSPRegistered(sspAddress);
    }

    //@dev check if SSP registered
    function isSspRegistered(address key) constant returns(bool) {
        return sspRegistry.isRegistered(key);
    }

    //@dev Unregister SSP and return unused deposit
    //@param Address of SSP to be unregistered
    function unregisterSsp(address sspAddress) {
        returnDeposit(sspAddress, securityDepositRegistry);
        sspRegistry.unregister(sspAddress, msg.sender);
        SSPUnregistered(sspAddress);
    }

    //@dev Change publisher fee of SSP
    //@param address of SSP to change
    //@param new publisher fee
    function updatePublisherFee(address key, uint16 newFee) {
        sspRegistry.updatePublisherFee(key, newFee, msg.sender);
        SSPParametersChanged(key);
    }

    //@dev transfer ownership of this SSP record
    //@param address of SSP
    //@param address of new owner
    function transfer(address key, address newOwner) {
        sspRegistry.transfer(key, newOwner, msg.sender);
    }
}
