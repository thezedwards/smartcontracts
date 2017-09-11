pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";
import "../dispute/Dispute.sol";

contract DisputeRegistry is Ownable {

    mapping(address => Dispute) disputeMapping;

    function registerDispute(Dispute dispute) onlyOwner {
        disputeMapping[address(dispute)] = dispute;
    }

    function findDispute(address disputeAddress) constant returns (address) {
        return address(disputeMapping[disputeAddress]);
    }
}
