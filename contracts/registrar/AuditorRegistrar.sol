pragma solidity ^0.4.11;

import "../registry/AuditorRegistry.sol";
import "./SecurityDepositAware.sol";

contract AuditorRegistrar is SecurityDepositAware{
    AuditorRegistry public auditorRegistry;

    event AuditorRegistered(address auditorAddress);
    event AuditorUnregistered(address auditorAddress);

    //@dev Retrieve information about registered Auditor
    //@return Address of registered Auditor and time when registered
    function findAuditor(address addr) constant returns(address auditorAddress, uint256[2] karma, address recordOwner) {
        return auditorRegistry.getAuditor(addr);
    }

    //@dev check if Auditor registered
    function isAuditorRegistered(address key) constant returns(bool) {
        return auditorRegistry.isRegistered(key);
    }

    //@dev Register organisation as Auditor
    //@param auditorAddress address of wallet to register
    function registerAuditor(address auditorAddress) {
        receiveSecurityDeposit(auditorAddress);
        auditorRegistry.register(auditorAddress, msg.sender);
        AuditorRegistered(auditorAddress);
    }

    //@dev Unregister Auditor and return unused deposit
    //@param Address of Auditor to be unregistered
    function unregisterAuditor(address auditorAddress) {
        returnDeposit(auditorAddress, securityDepositRegistry);
        auditorRegistry.unregister(auditorAddress, msg.sender);
        AuditorUnregistered(auditorAddress);
    }

    //@dev transfer ownership of this Auditor record
    //@param address of Auditor
    //@param address of new owner
    function transferAuditorRecord(address key, address newOwner) {
        auditorRegistry.transfer(key, newOwner, msg.sender);
    }
}
