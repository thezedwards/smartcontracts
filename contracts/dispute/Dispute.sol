pragma solidity ^0.4.11;

import "../common/Ownable.sol";
import "../common/ERC20.sol";
import "./Arbiter.sol";

contract Dispute is Ownable{
    ERC20 token;
    address private creator;
    address private subject;
    mapping (address => Voter) voters;
    Voter[] voterList;
    uint votedCount;
    uint forCount;
    uint againstCount;
    bool solved;
    bool decision;

    struct Voter {
        Arbiter arbiter;
        bool isVoted;
        bool vote;
        bool exists;
    }

    function Dispute(address creatorAddress, address subjectAddress, ERC20 papyrusToken){
        creator = creatorAddress;
        subject = subjectAddress;
        token = papyrusToken;
    }

    function addArbiters(Arbiter[] arbiters) onlyOwner {
        for (uint i = 0; i < arbiters.length; i++) {
            Arbiter arbiter = arbiters[i];
            address arbiterAddress = arbiter.arbiterAddress();
            if (voters[arbiterAddress].exists) {
                voters[arbiterAddress].arbiter = arbiter;
                voters[arbiterAddress].isVoted = false;
                voters[arbiterAddress].exists = true;
            voterList.push(voters[arbiterAddress]);
            } else {
                throw;
            }
        }
    }

    function isSolved() public constant returns(bool) {
        return solved;
    }

    function vote(bool vote) onlyArbiter {
        if (!solved && !voters[msg.sender].isVoted) {
            voters[msg.sender].vote = vote;
            voters[msg.sender].isVoted = true;
            votedCount++;
            if (vote) {
                forCount++;
            } else {
                againstCount++;
            }
            checkSolved();
        } else {
            throw;
        }
    }

    modifier onlyArbiter() {
        require(voters[msg.sender].exists);
        _;
    }

    function checkSolved() private {
        if (forCount > voterList.length / 2) {
            decision = true;
            solve();
        } else if (againstCount > voterList.length / 2) {
            decision = false;
            solve();
        }
    }

    function solve() private {
        solved = true;
        //TODO: Money + Karma thing
    }
}
