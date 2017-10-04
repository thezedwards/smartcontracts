pragma solidity ^0.4.11;

import "../registry/PublisherRegistry.sol";
import "./SecurityDepositAware.sol";

contract PublisherRegistrar is SecurityDepositAware{
    PublisherRegistry public publisherRegistry;

    event PublisherRegistered(address publisherAddress);
    event PublisherUnregistered(address publisherAddress);

    //@dev Retrieve information about registered Publisher
    //@return Address of registered Publisher and time when registered
    function findPublisher(address addr) constant returns(address publisherAddress, bytes32[3] url, uint256[2] karma) {
        return publisherRegistry.getPublisher(addr);
    }

    function isPublisherRegistered(address key) constant returns(bool) {
        return publisherRegistry.isRegistered(key);
    }

    //@dev Register organisation as Publisher
    //@param publisherAddress address of wallet to register
    function registerPublisher(address publisherAddress, bytes32[3] url) {
        if (!publisherRegistry.isRegistered(publisherAddress)) {
            receiveSecurityDeposit(publisherAddress);
            publisherRegistry.register(publisherAddress, url);
            PublisherRegistered(publisherAddress);
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
