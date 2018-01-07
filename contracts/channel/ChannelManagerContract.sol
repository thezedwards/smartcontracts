pragma solidity ^0.4.18;

import '../common/ECRecovery.sol';
import '../common/StandardToken.sol';
import './ChannelApi.sol';
import './ChannelManagerApi.sol';
import './CampaignContract.sol';
import './SettlementApi.sol';


contract ChannelManagerContract is ChannelManagerApi {
  using SafeMath for uint256;

  // STRUCTURES

  struct Channel {
    address campaign;
    string module;
    bytes configuration;
    Participant[] participants;
    uint32 closeTimeout;

    uint256 opened;
    uint256 closeRequested;
    uint256 closed;

    mapping (uint64 => Block) blocks;
    uint64 blockCount;
  }

  struct Participant {
    address participant;
    address validator;
  }

  struct Block {
    BlockPart[] parts;
    BlockResult[] results;
    BlockSettlement settlement;
  }

  struct BlockPart {
    bytes reference;
  }

  struct BlockResult {
    bytes32 resultHash;
    uint256 stake;
  }

  struct BlockSettlement {
    bytes result;
    bool settled;
  }

  // PUBLIC FUNCTIONS

  function ChannelManagerContract(address _channelApi) public {
    require(_channelApi != address(0));
    channelApi = ChannelApi(_channelApi);
  }

  function () public {
    revert();
  }

  // PUBLIC FUNCTIONS (CHANNELS MANAGEMENT)

  function createChannel(
    string module,
    bytes configuration,
    address[] participants,
    uint32 closeTimeout
  )
    public
    returns (uint64 channel)
  {
    require(participants.length >= MIN_PARTICIPANTS && participants.length <= MAX_PARTICIPANTS);
    require(closeTimeout >= 0);
    channel = channelCount;
    channels[channel].campaign = msg.sender;
    channels[channel].module = module;
    channels[channel].configuration = configuration;
    channels[channel].participants.length = participants.length;
    for (uint16 i = 0; i < participants.length; ++i) {
      channels[channel].participants[i].participant = participants[i];
      ChannelCreated(channel, participants[i]);
    }
    channels[channel].closeTimeout = closeTimeout;
    channels[channel].opened = block.number;
    channelCount += 1;
  }

  function requestCloseChannel(uint64 channel) public onlyParticipant(channel) {
    require(channels[channel].closeRequested == 0);
    channels[channel].closeRequested = block.number;
    ChannelCloseRequested(channel, channels[channel].closeRequested);
  }

  function closeChannel(uint64 channel) public {
    if (channels[channel].closeTimeout > 0) {
      require(channels[channel].closeRequested > 0);
      require(block.number - channels[channel].closeRequested >= channels[channel].closeTimeout);
    }
    if (channels[channel].closed == 0) {
      channels[channel].closed = block.number;
    }
    ChannelClosed(channel, channels[channel].closed);
  }

  // PUBLIC FUNCTIONS (CHANNELS INTERACTION)

  function approve(uint64 channel, address validator) public {
    require(validator != address(0));
    int8 participantIndex = getParticipantIndex(channel, msg.sender);
    require(participantIndex >= 0);
    uint8 i = uint8(participantIndex);
    channels[channel].participants[i].validator = validator;
  }

  function setBlockPart(uint64 channel, uint64 blockId, bytes reference) public {
    int8 participantIndex = getParticipantIndex(channel, msg.sender);
    require(participantIndex >= 0);
    uint8 i = uint8(participantIndex);
    if (channels[channel].blocks[blockId].parts.length == 0) {
      channels[channel].blocks[blockId].parts.length = channels[channel].participants.length;
    }
    channels[channel].blocks[blockId].parts[i].reference = reference;
    if (channels[channel].blockCount < blockId + 1) {
      channels[channel].blockCount = blockId + 1;
    }
    ChannelNewBlockPart(channel, msg.sender, blockId, reference);
  }

  function setBlockResult(uint64 channel, uint64 blockId, bytes32 resultHash, uint256 stake) public {
    int8 validatorIndex = getValidatorIndex(channel, msg.sender);
    require(validatorIndex >= 0);
    uint8 i = uint8(validatorIndex);
    if (channels[channel].blocks[blockId].results.length == 0) {
      channels[channel].blocks[blockId].results.length = channels[channel].participants.length;
    }
    channels[channel].blocks[blockId].results[i].resultHash = resultHash;
    channels[channel].blocks[blockId].results[i].stake = stake;
    ChannelNewBlockResult(channel, msg.sender, blockId, resultHash, stake);
  }

  function blockSettle(uint64 channel, uint64 blockId, bytes result) public onlyParticipant(channel) {
    require(!channels[channel].blocks[blockId].settlement.settled);
    channels[channel].blocks[blockId].settlement.result = result;
    channels[channel].blocks[blockId].settlement.settled = true;
    ChannelBlockSettled(channel, msg.sender, blockId, result);
  }
  
  //FUNCTIONS

  function participantCount(uint64 channel)
    public
    view
    returns (uint64)
  {
    return uint64(channels[channel].participants.length);
  }

  function participant(uint64 channel, uint64 participantId)
    public
    view
    returns (address participantAddress, address validatorAddress)
  {
    participantAddress = channels[channel].participants[participantId].participant;
    validatorAddress = channels[channel].participants[participantId].validator;
  }

  function blockCount(uint64 channel)
    public
    view
    returns (uint64)
  {
    return channels[channel].blockCount;
  }

  function channelClosed(uint64 channel)
    public
    view
    returns (uint256)
  {
    return channels[channel].closed;
  }

  function channelModule(uint64 channel)
    public
    view
    returns (string)
  {
    return channels[channel].module;
  }

  function channelConfiguration(uint64 channel)
    public
    view
    returns (bytes)
  {
    return channels[channel].configuration;
  }

  function blockPart(uint64 channel, uint64 participantId, uint64 blockId)
    public
    view
    returns (bytes reference)
  {
    reference = channels[channel].blocks[blockId].parts[participantId].reference;
  }

  function blockResult(uint64 channel, uint64 participantId, uint64 blockId)
    public
    view
    returns (bytes32 resultHash, uint256 stake)
  {
    resultHash = channels[channel].blocks[blockId].results[participantId].resultHash;
    stake = channels[channel].blocks[blockId].results[participantId].stake;
  }

  function blockSettlement(uint64 channel, uint64 blockId)
    public
    view
    returns (bytes result)
  {
    result = channels[channel].blocks[blockId].settlement.result;
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

  function getParticipantIndex(uint64 channel, address participantAddress) private view returns (int8) {
    for (uint8 i = 0; i < channels[channel].participants.length; ++i) {
      if (channels[channel].participants[i].participant == participantAddress) {
        return int8(i);
      }
    }
    return -1;
  }

  function isParticipant(uint64 channel, address participantAddress) private view returns (bool) {
    return getParticipantIndex(channel, participantAddress) >= 0;
  }

  function getValidatorIndex(uint64 channel, address validator) private view returns (int8) {
    for (uint8 i = 0; i < channels[channel].participants.length; ++i) {
      if (channels[channel].participants[i].validator == validator) {
        return int8(i);
      }
    }
    return -1;
  }

  function isValidator(uint64 channel, address validator) private view returns (bool) {
    return getValidatorIndex(channel, validator) >= 0;
  }

  // MODIFIERS

  modifier onlyParticipant(uint64 channel) {
    require(isParticipant(channel, msg.sender));
    _;
  }

  modifier onlyValidator(uint64 channel) {
    require(isValidator(channel, msg.sender));
    _;
  }

  // FIELDS

  ChannelApi public channelApi;

  mapping (uint64 => Channel) public channels;
  uint64 public channelCount;

  uint8 constant MIN_PARTICIPANTS = 2;
  uint8 constant MAX_PARTICIPANTS = 16;
}
