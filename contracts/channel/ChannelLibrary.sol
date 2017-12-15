pragma solidity ^0.4.19;

import '../common/ECRecovery.sol';
import '../common/SafeMath.sol';
import '../common/StandardToken.sol';
import './ChannelManagerContract.sol';


// Papyrus State Channel Library
// moved to separate library to save gas
library ChannelLibrary {
  using SafeMath for uint256;

  // STRUCTURES

  enum Role {
    DSP,
    SSP,
    Auditor
  }

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
    bool settled;
  }

  struct ChannelData {
    string module;
    bytes configuration;
    Participant[] participants;
    ChannelManagerContract manager;

    uint256 balance;

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
  function deposit(ChannelData storage self, address participant, uint256 amount) public onlyParticipant(self) returns (bool success, uint256 balance) {
    require(self.opened > 0);
    require(self.closed == 0);
    StandardToken token = self.manager.token();
    require(token.balanceOf(msg.sender) >= amount);
    success = token.transferFrom(msg.sender, this, amount);
    for (uint16 i = 0; i < self.participants.length; ++i) {
      if (self.participants[i].participant == participant) {
        if (success) {
          self.participants[i].balance = self.participants[i].balance.add(amount);
        }
        return (success, self.participants[i].balance);
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
    uint16 i;
    // Check result and settled state
    uint256 resultHash = (uint256)(keccak256(result));
    for (i = 0; i < self.participants.length; ++i) {
      if (self.participants[i].blockResults[blockNumber].resultHash != resultHash || self.participants[i].blockResults[blockNumber].settled) {
        revert();
      }
    }
    // Apply result
    uint256 sspPayment;
    uint256 auditorPayment;
    uint64 totalImpressions;
    uint64 fraudImpressions;
    assembly {
      sspPayment := mload(result)
      auditorPayment := mload(add(result, 0x20))
      totalImpressions := mload(add(result, 0x40))
      fraudImpressions := mload(add(result, 0x48))
    }
    self.participants[uint(Role.SSP)].balance = self.participants[uint(Role.SSP)].balance.add(sspPayment);
    self.participants[uint(Role.Auditor)].balance = self.participants[uint(Role.Auditor)].balance.add(auditorPayment);
    self.participants[uint(Role.DSP)].balance = self.participants[uint(Role.DSP)].balance.sub(sspPayment.add(auditorPayment));
    for (i = 0; i < self.participants.length; ++i) {
      self.participants[i].blockResults[blockNumber].settled = true;
    }
  }

  function requestClose(ChannelData storage self) public onlyParticipant(self) {
    require(self.closeRequested == 0);
    self.closeRequested = block.number;
  }

  function close(
    ChannelData storage self,
    address channel,
    uint256 nonce,
    bytes signature
  )
    public
  {
    if (self.closeTimeout > 0) {
      require(self.closeRequested > 0);
      require(block.number - self.closeRequested >= self.closeTimeout);
    }
    require(nonce > self.nonce);

    if (msg.sender != self.participants[uint(Role.DSP)].participant) {
      // checking signature
      bytes32 signedHash = hashState(channel, nonce, self.participants[uint(Role.SSP)].balance, self.participants[uint(Role.Auditor)].balance);
      address signAddress = ECRecovery.recover(signedHash, signature);
      require(signAddress == self.participants[uint(Role.DSP)].participant);
    }

    if (self.closed == 0) {
      self.closed = block.number;
    }

    self.nonce = nonce;
  }

  /// @notice Settles the balance between the two parties
  /// @dev Settles the balances of the two parties for the channel
  /// @return The participants with netted balances
  function settle(ChannelData storage self)
    public
    notSettledButClosed(self)
    timeoutOver(self)
  {
    StandardToken token = self.manager.token();
    
    Participant memory ssp = self.participants[uint(Role.SSP)];
    if (ssp.balance > 0) {
      require(token.transfer(ssp.participant, ssp.balance));
    }
    
    Participant memory auditor = self.participants[uint(Role.Auditor)];
    if (auditor.balance > 0) {
      require(token.transfer(auditor.participant, auditor.balance));
    }
    
    Participant memory dsp = self.participants[uint(Role.DSP)];
    if (dsp.balance > 0) {
      require(token.transfer(dsp.participant, dsp.balance));
    }

    self.settled = block.number;
  }

  function audit(ChannelData storage self, address auditor)
    public
    notAuditedButClosed(self)
  {
    require(self.participants[uint(Role.Auditor)].participant == auditor);
    require(block.number <= self.closed + self.auditTimeout);
    self.audited = block.number;
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

  function getParticipantIndex(ChannelData storage self, address participant) private view returns (int32) {
    for (uint16 i = 0; i < self.participants.length; ++i) {
      if (self.participants[i].participant == participant) {
        return i;
      }
    }
    return -1;
  }

  function isParticipant(ChannelData storage self, address participant) private view returns (bool) {
    return getParticipantIndex(self, participant) >= 0;
  }

  function getValidatorIndex(ChannelData storage self, address validator) private view returns (int32) {
    for (uint16 i = 0; i < self.participants.length; ++i) {
      if (self.participants[i].validator == validator) {
        return i;
      }
    }
    return -1;
  }

  function isValidator(ChannelData storage self, address validator) private view returns (bool) {
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