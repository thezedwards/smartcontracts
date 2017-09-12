pragma solidity ^0.4.11;

import "../dao/DaoOwnable.sol";
import "../dispute/Dispute.sol";

contract DisputeRegistry is DaoOwnable {

    mapping(address => Dispute) disputeMapping;

    function registerDispute(Dispute dispute) onlyDaoOrOwner {
        disputeMapping[address(dispute)] = dispute;
    }

    function findDispute(address disputeAddress) constant returns (address) {
        return address(disputeMapping[disputeAddress]);
    }
}
