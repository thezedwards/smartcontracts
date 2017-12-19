pragma solidity ^0.4.18;

import '../common/ECRecovery.sol';
import '../common/SafeMath.sol';
import '../common/StandardToken.sol';
import './ChannelManagerContract.sol';


contract ChannelContract {
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
    bytes32 resultHash;
    uint256 stake;
    bool settled;
  }

  // EVENTS

  event ChannelNewBalance(address token, address participant, uint256 balance, uint256 blockNumber);
  event ChannelNewBlockPart(address token, address participant, uint64 blockNumber, bytes reference);
  event ChannelNewBlockResult(address token, address participant, uint64 blockNumber, bytes32 resultHash, uint256 stake);
  event ChannelCloseRequested(address channelAddress, uint256 blockNumber);
  event ChannelClosed(address channelAddress, uint256 blockNumber);
  event TransferUpdated(address nodeAddress, uint256 blockNumber);
  event ChannelSettled(uint256 blockNumber);
  event ChannelAudited(uint256 blockNumber);
  event ChannelSecretRevealed(bytes32 secret, address receiver);

  // PUBLIC FUNCTIONS

  function ChannelContract(
    address _manager,
    string _module,
    bytes configuration,
    address[] _participants,
    uint32 _closeTimeout,
    uint32 _settleTimeout,
    uint32 _auditTimeout
  )
    public
  {
    // allow creation only from manager contract
    require(msg.sender == _manager);
    require(participants.length >= 3 && participants.length <= MAX_PARTICIPATS);
    require(closeTimeout >= 0);
    require(settleTimeout > 0);
    require(auditTimeout >= 0);
    manager = ChannelManagerContract(_manager);
    module = _module;
    configuration = configuration;
    participants.length = _participants.length;
    for (uint16 i = 0; i < participants.length; ++i) {
      participants[i].participant = _participants[i];
    }
    closeTimeout = _closeTimeout;
    settleTimeout = _settleTimeout;
    auditTimeout = _auditTimeout;
    opened = block.number;
  }

  function () public {
    revert();
  }

  /// @notice Approving participant and provide validator node addess. Should be called before the channel is openned.
  /// @param validator Address of validator
  function approve(address validator) public {
    require(validator != address(0));
    int8 participantIndex = getParticipantIndex(msg.sender);
    require(participantIndex >= 0);
    uint8 i = uint8(participantIndex);
    participants[i].validator = validator;
  }

  /// @notice Sender deposits amount to channel. Should be called before the channel is closed.
  /// @param participant The amount to be deposited to the address
  /// @param amount The amount to be deposited to the address
  /// @return success Success if the transfer was successful
  /// @return balance The new balance of the invoker
  function deposit(address participant, uint256 amount) public returns (bool success, uint256 balance) {
    require(opened > 0);
    require(closed == 0);
    StandardToken token = manager.token();
    require(token.balanceOf(msg.sender) >= amount);
    int8 participantIndex = getParticipantIndex(participant);
    require(participantIndex >= 0);
    uint8 i = uint8(participantIndex);
    success = token.transferFrom(msg.sender, this, amount);
    if (success) {
      participants[i].balance = participants[i].balance.add(amount);
      ChannelNewBalance(manager.token(), msg.sender, participants[i].balance, block.number);
    }
    return (success, participants[i].balance);
  }

  function setBlockPart(uint64 blockNumber, bytes reference) public {
    int8 participantIndex = getParticipantIndex(msg.sender);
    require(participantIndex >= 0);
    uint8 i = uint8(participantIndex);
    participants[i].blockParts[blockNumber].reference = reference;
    ChannelNewBlockPart(manager.token(), msg.sender, blockNumber, reference);
  }

  function setBlockResult(uint64 blockNumber, bytes32 resultHash, uint256 stake) public {
    int8 validatorIndex = getValidatorIndex(msg.sender);
    require(validatorIndex >= 0);
    uint8 i = uint8(validatorIndex);
    participants[i].blockResults[blockNumber].resultHash = resultHash;
    participants[i].blockResults[blockNumber].stake = stake;
    ChannelNewBlockResult(manager.token(), msg.sender, blockNumber, resultHash, stake);
  }

  function blockSettle(uint64 blockNumber, bytes result) public onlyParticipant {
    uint8 i;
    // Check result and settled state
    bytes32 resultHash = bytes32(keccak256(result));
    for (i = 0; i < participants.length; ++i) {
      if (participants[i].blockResults[blockNumber].resultHash != resultHash || participants[i].blockResults[blockNumber].settled) {
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
    participants[uint8(Role.SSP)].balance = participants[uint8(Role.SSP)].balance.add(sspPayment);
    participants[uint8(Role.Auditor)].balance = participants[uint8(Role.Auditor)].balance.add(auditorPayment);
    participants[uint8(Role.DSP)].balance = participants[uint8(Role.DSP)].balance.sub(sspPayment).sub(auditorPayment);
    for (i = 0; i < participants.length; ++i) {
      participants[i].blockResults[blockNumber].settled = true;
    }
    // TODO: Event
  }

  /// @notice Request to close the channel.
  function requestClose() public onlyParticipant {
    require(closeRequested == 0);
    closeRequested = block.number;
    ChannelCloseRequested(msg.sender, closed);
  }

  /// @notice Close the channel.
  function close(address channel, uint256 nonce, bytes signature) public {
    if (closeTimeout > 0) {
      require(closeRequested > 0);
      require(block.number - closeRequested >= closeTimeout);
    }
    require(nonce > nonce);
    if (msg.sender != participants[uint8(Role.DSP)].participant) {
      // checking signature
      bytes32 signedHash = hashState(channel, nonce, participants[uint8(Role.SSP)].balance, participants[uint8(Role.Auditor)].balance);
      address signAddress = ECRecovery.recover(signedHash, signature);
      require(signAddress == participants[uint8(Role.DSP)].participant);
    }
    if (closed == 0) {
      closed = block.number;
    }
    nonce = nonce;
    ChannelClosed(msg.sender, closed);
  }

  /// @notice Settle the transfers and balances of the channel and pay out to
  /// each participant. Can only be called after the channel is closed
  /// and only after the number of blocks in the settlement timeout
  /// have passed.
  function settle() public onlyClosed onlyNotSettled {
    require(closed + settleTimeout <= block.number);
    StandardToken token = manager.token();
    Participant memory ssp = participants[uint8(Role.SSP)];
    Participant memory auditor = participants[uint8(Role.Auditor)];
    Participant memory dsp = participants[uint8(Role.DSP)];
    if (ssp.balance > 0) {
      require(token.transfer(ssp.participant, ssp.balance));
    }
    if (auditor.balance > 0) {
      require(token.transfer(auditor.participant, auditor.balance));
    }
    if (dsp.balance > 0) {
      require(token.transfer(dsp.participant, dsp.balance));
    }
    settled = block.number;
    ChannelSettled(settled);
  }

  function audit(address auditor) public onlyClosed onlyNotAudited {
    require(participants[uint8(Role.Auditor)].participant == auditor);
    require(block.number <= closed + auditTimeout);
    audited = block.number;
    ChannelAudited(audited);
  }

  function destroy() public onlyManager {
    require(settled > 0);
    require(audited > 0 || block.number > closed + auditTimeout);
    selfdestruct(0);
  }

  function participant(uint256 index)
    public
    view
    returns (address participantAddress, address validatorAddress, uint256 balance)
  {
    participantAddress = participants[index].participant;
    validatorAddress = participants[index].validator;
    balance = participants[index].balance;
  }

  function blockPart(uint256 participantIndex, uint64 blockNumber)
    public
    view
    returns (bytes reference)
  {
    reference = participants[participantIndex].blockParts[blockNumber].reference;
  }

  function blockResult(uint256 participantIndex, uint64 blockNumber)
    public
    view
    returns (bytes32 resultHash, uint256 stake)
  {
    resultHash = participants[participantIndex].blockResults[blockNumber].resultHash;
    stake = participants[participantIndex].blockResults[blockNumber].stake;
  }
  
  function dsp() public view returns (address) {
    return participants[uint8(Role.DSP)].participant;
  }

  function ssp() public view returns (address) {
    return participants[uint8(Role.SSP)].participant;
  }
  
  function auditor() public view returns (address) {
    return participants[uint8(Role.Auditor)].participant;
  }

  function sspPayment() public view returns (uint256) {
    return participants[uint8(Role.SSP)].balance;
  }

  function auditorPayment() public view returns (uint256) {
    return participants[uint8(Role.Auditor)].balance;
  }

  function hashState(address _channel, uint256 _nonce, uint256 _receiverPayment, uint256 _auditorPayment) public pure returns (bytes32) {
    return keccak256(_channel, _nonce, _receiverPayment, _auditorPayment);
  }

  function hashTransfer(address _transferId, address _channel, bytes _lockData, uint256 _sum) public pure returns (bytes32) {
    if (_lockData.length > 0) {
      return keccak256(_transferId, _channel, _sum, _lockData);
    } else {
      return keccak256(_transferId, _channel, _sum);
    }
  }

  // PRIVATE FUNCTIONS

  function getParticipantIndex(address _participant) private view returns (int8) {
    for (uint8 i = 0; i < participants.length; ++i) {
      if (participants[i].participant == _participant) {
        return int8(i);
      }
    }
    return -1;
  }

  function isParticipant(address _participant) private view returns (bool) {
    return getParticipantIndex(_participant) >= 0;
  }

  function getValidatorIndex(address _validator) private view returns (int8) {
    for (uint8 i = 0; i < participants.length; ++i) {
      if (participants[i].validator == _validator) {
        return int8(i);
      }
    }
    return -1;
  }

  function isValidator(address _validator) private view returns (bool) {
    return getValidatorIndex(_validator) >= 0;
  }

  // MODIFIERS

  modifier onlyManager() {
    require(msg.sender == address(manager));
    _;
  }

  modifier onlyParticipant() {
    require(isParticipant(msg.sender));
    _;
  }

  modifier onlyValidator() {
    require(isValidator(msg.sender));
    _;
  }

  modifier onlyClosed() {
    require(closed > 0);
    _;
  }

  modifier onlyNotSettled() {
    require(settled == 0);
    _;
  }

  modifier onlyNotAudited() {
    require(audited == 0);
    _;
  }

  // FIELDS

  ChannelManagerContract public manager;
  string public module;
  bytes public configuration;
  Participant[] public participants;
  uint32 public closeTimeout;
  uint32 public settleTimeout;
  uint32 public auditTimeout;

  uint256 public opened;
  uint256 public closeRequested;
  uint256 public closed;
  uint256 public settled;
  uint256 public audited;

  uint256 public nonce;

  uint8 constant MAX_PARTICIPATS = 16;
}
