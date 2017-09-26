pragma solidity ^0.4.11;

import "../registry/AuditorRegistry.sol";
import "./SecurityDepositAware.sol";

contract AuditorRegistrar is SecurityDepositAware{
    AuditorRegistry internal auditorRegistry;

    event AuditorRegistered(address auditorAddress);
    event AuditorUnregistered(address auditorAddress);

    //@dev Retrieve information about registered Auditor
    //@return Address of registered Auditor and time when registered
    function findAuditor(address addr) constant returns(address auditorAddress, uint256[2] karma) {
        return auditorRegistry.getAuditor(addr);
    }

    //@dev Register organisation as Auditor
    //@param auditorAddress address of wallet to register
    function registerAuditor(address auditorAddress) {
        if (!auditorRegistry.isRegistered(auditorAddress)) {
            if (receiveSecurityDeposit(auditorAddress)) {
                auditorRegistry.register(auditorAddress);
                AuditorRegistered(auditorAddress);
            }
        }
    }

    //@dev Unregister Auditor and return unused deposit
    //@param Address of Auditor to be unregistered
    function unregisterAuditor(address auditorAddress) {
        if (auditorRegistry.isRegistered(auditorAddress)) {
            returnDeposit(auditorAddress, securityDepositRegistry);
            auditorRegistry.unregister(auditorAddress);
            AuditorUnregistered(auditorAddress);
        }
    }

}
