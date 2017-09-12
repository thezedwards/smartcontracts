pragma solidity ^0.4.11;

import "../registry/PublisherRegistry.sol";
import "./SecurityDepositAware.sol";

contract PublisherRegistrar is SecurityDepositAware{
    PublisherRegistry internal publisherRegistry;

    event PublisherRegistered(address publisherAddress);
    event PublisherUnregistered(address publisherAddress);

//    //@dev Get direct link to PublisherRegistry contract
//    function getPublisherRegistry() constant returns(address publisherRegistryAddress) {
//        return publisherRegistry;
//    }

    //@dev Retrieve information about registered Publisher
    //@return Address of registered Publisher and time when registered
    function findPublisher(address addr) constant returns(address publisherAddress, bytes32[3] url, uint256[2] karma) {
        return publisherRegistry.getPublisher(addr);
    }

    //@dev Register organisation as Publisher
    //@param publisherAddress address of wallet to register
    function registerPublisher(address publisherAddress, bytes32[3] url) {
        if (!publisherRegistry.isRegistered(publisherAddress)) {
            if (receiveSecurityDeposit(publisherAddress)) {
                publisherRegistry.register(publisherAddress, url);
                PublisherRegistered(publisherAddress);
            }
        }
    }

    //@dev Unregister Publisher and return unused deposit
    //@param Address of Publisher to be unregistered
    function unregisterPublisher(address publisherAddress) {
        if (publisherRegistry.isRegistered(publisherAddress)) {
            returnDeposit(publisherAddress, securityDepositRegistry);
            publisherRegistry.unregister(publisherAddress);
            PublisherUnregistered(publisherAddress);
        }
    }
}
