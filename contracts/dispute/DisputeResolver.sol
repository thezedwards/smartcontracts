pragma solidity ^0.4.11;

import "../registry/DisputeRegistry.sol";
import "../registry/ArbiterRegistry.sol";
import "../dao/WithToken.sol";

contract DisputeResolver is WithToken {
    DisputeRegistry internal disputeRegistry;
    ArbiterRegistry internal arbiterRegistry;

    uint8 constant NUMBER_OF_ARBITERS_FOR_DISPUTE = 5;

    function startDispute(address subject) {
        Dispute dispute = new Dispute(msg.sender, subject, token);
        Arbiter[] arbiters;
        for (uint i = 0; i < NUMBER_OF_ARBITERS_FOR_DISPUTE; i++) {
            arbiters.push(arbiterRegistry.getRandomArbiter());
            //TODO check for duplicates
        }
        dispute.addArbiters(arbiters);
    }
}
