pragma solidity ^0.4.18;

import "../registry/PublisherRegistry.sol";
import "./SecurityDepositAware.sol";


contract PublisherRegistrar is SecurityDepositAware {

  // EVENTS

  event PublisherRegistered(address indexed publisherAddress);
  event PublisherUnregistered(address indexed publisherAddress);
  event PublisherParametersChanged(address indexed publisherAddress);

  // PUBLIC FUNCTIONS

  //@dev Register organisation as Publisher
  //@param publisherAddress address of wallet to register
  function registerPublisher(address publisherAddress, bytes32[5] url, bytes masterKeyPublic) public {
    receiveSecurityDeposit(publisherAddress);
    publisherRegistry.register(publisherAddress, url, msg.sender, masterKeyPublic);
    PublisherRegistered(publisherAddress);
  }

  //@dev Unregister Publisher and return unused deposit
  //@param Address of Publisher to be unregistered
  function unregisterPublisher(address publisherAddress) public {
    returnDeposit(publisherAddress, securityDepositRegistry);
    publisherRegistry.unregister(publisherAddress, msg.sender);
    PublisherUnregistered(publisherAddress);
  }

  //@dev transfer ownership of this Publisher record
  //@param address of Publisher
  //@param address of new owner
  function transferPublisherRecord(address key, address newOwner) public {
    publisherRegistry.transfer(key, newOwner, msg.sender);
  }

  function isPublisherRegistered(address publisherAddress) public view returns (bool) {
    return publisherRegistry.isRegistered(publisherAddress);
  }

  // FIELDS
  
  PublisherRegistry public publisherRegistry;
}
