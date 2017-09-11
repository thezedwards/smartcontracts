pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20.sol";
import "./Dispute.sol";

contract Arbiter is Ownable {
    address public arbiterAddress;
    int public karma;

    struct DisputeBean{
        Dispute dispute;
        uint index;
        bool exists;
    }

    mapping(address => DisputeBean) toSolveMapping;
    Dispute[] disputesToSolve;

    Dispute[] solvedDisputes;

    function Arbiter(address addr){
        arbiterAddress = addr;
    }

    function assignDispute(Dispute dispute) onlyOwner {
        if (!toSolveMapping[dispute].exists) {
            disputesToSolve.push(dispute);
            DisputeBean memory bean = DisputeBean(dispute, disputesToSolve.length - 1, true);
            toSolveMapping[address(dispute)] = bean;
        }
    }

    function solve(Dispute dispute, bool vote) onlyArbiter {
        if (toSolveMapping[dispute].exists) {
            if (!dispute.isSolved()) {
                dispute.vote(vote);
            }
            moveToSolved(dispute);
        }
    }

    function skip(Dispute dispute) onlyArbiter {
        moveToSolved(dispute);
    }

    function moveToSolved(Dispute dispute) private {
        DisputeBean bean = toSolveMapping[dispute];
        disputesToSolve[bean.index] = disputesToSolve[disputesToSolve.length - 1];
        disputesToSolve.length--;
        solvedDisputes.push(dispute);
    }

    function getKarma() constant returns(int) {
        return karma;
    }

    function gainKarma(int gained) onlyOwner returns (int) {
        karma = karma + gained;
        return karma;
    }

    function getDisputesToSolve() constant returns (address[] disputeAddresses) {
        disputeAddresses = new address[](disputesToSolve.length);
        for (uint i = 0; i < disputesToSolve.length; i++) {
            disputeAddresses[i] = address(disputesToSolve[i]);
        }
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiterAddress);
        _;
    }
}
