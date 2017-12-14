pragma solidity ^0.4.19;

import '../common/ECRecovery.sol';
import '../common/StandardToken.sol';
import './ChannelManagerContract.sol';


// Papyrus State Channel Library
// moved to separate library to save gas
library ChannelLibrary {

  // STRUCTURES

  struct Participant {
    address participant;
    address validator;
    uint256 balance;
    mapping (uint64 => BlockPart) blockParts;
    mapping (uint64 => BlockResult) blockResults;
  }

  struct BlockPart {
    bytes reference;
  }

  struct BlockResult {
    uint256 resultHash;
    uint256 stake;
  }

  struct ChannelData {
    string module;
    bytes configuration;
    Participant[] participants;
    ChannelManagerContract manager;

    uint32 closeTimeout;
    uint32 settleTimeout;
    uint32 auditTimeout;
    uint256 opened;
    uint256 closeRequested;
    uint256 closed;
    uint256 settled;
    uint256 audited;

    // state update for close
    uint256 nonce;
    uint256 receiverPayment;
    uint256 auditorPayment;
  }

  // PUBLIC FUNCTIONS

  /// @notice Approving participant and provide validator node addess. Should be called before the channel is openned.
  /// @param validator Address of validator
  function approve(ChannelData storage self, address validator) public onlyParticipant(self) {
    require(validator != address(0));
    for (uint16 i = 0; i < self.participants.length; ++i) {
      if (self.participants[i].participant == msg.sender) {
        self.participants[i].validator = validator;
        return;
      }
    }
    revert();
  }

  /// @notice Sender deposits amount to channel. Should be called before the channel is closed.
  /// @param participant The amount to be deposited to the address
  /// @param amount The amount to be deposited to the address
  /// @return Success if the transfer was successful
  /// @return The new balance of the invoker
  function deposit(ChannelData storage self, address participant, uint256 amount) public returns (bool success, uint256 balance) {
    require(isParticipant(self, participant));
    require(self.opened > 0);
    require(self.closed == 0);
    StandardToken token = self.manager.token();
    require(token.balanceOf(msg.sender) >= amount);
    success = token.transferFrom(msg.sender, this, amount);
    if (success) {
      for (uint16 i = 0; i < self.participants.length; ++i) {
        if (self.participants[i].participant == participant) {
          self.participants[i].balance += amount;
          return (true, self.participants[i].balance);
        }
      }
    }
    return (false, 0);
  }

  function blockPart(ChannelData storage self, uint64 blockNumber, bytes reference) public onlyParticipant(self) {
    uint256 participantIndex = (uint256)(getParticipantIndex(self, msg.sender));
    //require(self.participants[participantIndex].blockParts[blockNumber].reference.length == 0);
    self.participants[participantIndex].blockParts[blockNumber].reference = reference;
  }

  function blockResult(ChannelData storage self, uint64 blockNumber, uint256 resultHash, uint256 stake) public onlyValidator(self) {
    uint256 validatorIndex = (uint256)(getValidatorIndex(self, msg.sender));
    //require(self.participants[validatorIndex].blockResult[blockNumber].resultHash == 0);
    self.participants[validatorIndex].blockResults[blockNumber].resultHash = resultHash;
    self.participants[validatorIndex].blockResults[blockNumber].stake = stake;
  }

  function blockSettle(ChannelData storage self, uint64 blockNumber, bytes result) public onlyParticipant(self) {
    uint256 resultHash = (uint256)(keccak256(result));
    for (uint16 i = 0; i < self.participants.length; ++i) {
      if (self.participants[i].blockResults[blockNumber].resultHash != resultHash) {
        revert();
      }
    }
    // TODO
  }

  function requestClose(ChannelData storage self) public onlyParticipant(self) {
    require(self.closeRequested == 0);
    self.closeRequested = block.number;
  }

  function close(
    ChannelData storage self,
    address channel,
    uint256 nonce,
    uint256 receiverPayment,
    uint256 auditorPayment,
    bytes signature
  )
    public
  {
    /*if (self.closeTimeout > 0) {
      require(self.closeRequested > 0);
      require(block.number - self.closeRequested >= self.closeTimeout);
    }
    require(nonce > self.nonce);
    require(receiverPayment >= self.receiverPayment);
    require(auditorPayment >= self.auditorPayment);
    require(receiverPayment + auditorPayment <= self.balance);

    if (msg.sender != self.sender) {
      // checking signature
      bytes32 signedHash = hashState(channel, nonce, receiverPayment, auditorPayment);
      address signAddress = ECRecovery.recover(signedHash, signature);
      require(signAddress == self.sender);
    }

    if (self.closed == 0) {
        self.closed = block.number;
    }

    self.nonce = nonce;
    self.receiverPayment = receiverPayment;
    self.auditorPayment = auditorPayment;*/
  }

  /// @notice Settles the balance between the two parties
  /// @dev Settles the balances of the two parties for the channel
  /// @return The participants with netted balances
  function settle(ChannelData storage self)
    public
    notSettledButClosed(self)
    timeoutOver(self)
  {
    /*StandardToken token = self.manager.token();
    
    if (self.receiverPayment > 0) {
      require(token.transfer(self.receiver, self.receiverPayment));
    }
    
    if (self.auditorPayment > 0) {
      require(token.transfer(self.auditor, self.auditorPayment));
    }

    if (self.receiverPayment + self.auditorPayment < self.balance) {
      require(token.transfer(self.sender, self.balance - self.receiverPayment - self.auditorPayment));
    }

    self.settled = block.number;*/
  }

  function audit(ChannelData storage self, address auditor)
    public
    notAuditedButClosed(self)
  {
    /*require(self.auditor == auditor);
    require(block.number <= self.closed + self.auditTimeout);
    self.audited = block.number;*/
  }

  function validateTransfer(
    ChannelData storage self,
    address transferId,
    address channel,
    uint256 sum,
    bytes lockData,
    bytes signature
  )
    public
    view
    returns (uint256)
  {
    /*bytes32 signedHash = hashTransfer(transferId, channel, lockData, sum);
    address signAddress = ECRecovery.recover(signedHash, signature);
    require(signAddress == self.client);*/
  }

  function hashState(address channel, uint256 nonce, uint256 receiverPayment, uint256 auditorPayment) public pure returns (bytes32) {
    return keccak256(channel, nonce, receiverPayment, auditorPayment);
  }

  function hashTransfer(address transferId, address channel, bytes lockData, uint256 sum) public pure returns (bytes32) {
    if (lockData.length > 0) {
      return keccak256(transferId, channel, sum, lockData);
    } else {
      return keccak256(transferId, channel, sum);
    }
  }

  // PRIVATE FUNCTIONS

  function getParticipantIndex(ChannelData storage self, address participant) private returns (int32) {
    for (uint16 i = 0; i < self.participants.length; ++i) {
      if (self.participants[i].participant == participant) {
        return i;
      }
    }
    return -1;
  }

  function isParticipant(ChannelData storage self, address participant) private returns (bool) {
    return getParticipantIndex(self, participant) >= 0;
  }

  function getValidatorIndex(ChannelData storage self, address validator) private returns (int32) {
    for (uint16 i = 0; i < self.participants.length; ++i) {
      if (self.participants[i].validator == validator) {
        return i;
      }
    }
    return -1;
  }

  function isValidator(ChannelData storage self, address validator) private returns (bool) {
    return getValidatorIndex(self, validator) >= 0;
  }

  // MODIFIERS

  modifier notSettledButClosed(ChannelData storage self) {
    require(self.settled <= 0 && self.closed > 0);
    _;
  }

  modifier notAuditedButClosed(ChannelData storage self) {
    require(self.audited <= 0 && self.closed > 0);
    _;
  }

  modifier stillTimeout(ChannelData storage self) {
    require(self.closed + self.settleTimeout >= block.number);
    _;
  }

  modifier timeoutOver(ChannelData storage self) {
    require(self.closed + self.settleTimeout <= block.number);
    _;
  }

  modifier channelSettled(ChannelData storage self) {
    require(self.settled != 0);
    _;
  }

  modifier onlyParticipant(ChannelData storage self) {
    require(isParticipant(self, msg.sender));
    _;
  }

  modifier onlyValidator(ChannelData storage self) {
    require(isValidator(self, msg.sender));
    _;
  }
}