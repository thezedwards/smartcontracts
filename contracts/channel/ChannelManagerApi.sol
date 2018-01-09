pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import './ChannelApi.sol';
import './CampaignContract.sol';
import './SettlementApi.sol';


contract ChannelManagerApi {

  // EVENTS

  event ChannelCreated(uint64 indexed channel, address indexed participant);
  event ChannelCloseRequested(uint64 indexed channel, uint256 blockNumber);
  event ChannelClosed(uint64 indexed channel, uint256 blockNumber);
  event ChannelAudited(uint64 indexed channel, uint256 blockNumber);
  event ChannelNewBlockPart(uint64 indexed channel, address indexed participant, uint64 blockId, bytes reference);
  event ChannelNewBlockResult(uint64 indexed channel, address indexed participant, uint64 blockId, bytes32 resultHash, uint256 stake);
  event ChannelBlockSettled(uint64 indexed channel, address indexed participant, uint64 blockId, bytes result);

  // PUBLIC FUNCTIONS (CHANNELS MANAGEMENT)

  function createChannel(string module, bytes configuration, address[] participants, uint32 closeTimeout) public returns (uint64 channelId);

  // Closing channel
  function requestCloseChannel(uint64 channel) public;
  function closeChannel(uint64 channel) public;

  // Writting data to channel
  function approve(uint64 channel, address validator) public;
  function setBlockPart(uint64 channel, uint64 blockId, bytes reference) public;
  function setBlockResult(uint64 channel, uint64 blockId, bytes32 resultHash, uint256 stake) public;
  function blockSettle(uint64 channel, uint64 blockId, bytes result) public;

  // Read channel information
  function channelCreator(uint64 channel) public view returns (address);
  function channelModule(uint64 channel) public view returns (string);
  function channelConfiguration(uint64 channel) public view returns (bytes);
  function channelParticipantCount(uint64 channel) public view returns (uint64);
  function channelParticipant(uint64 channel, uint64 participantId) public view returns (address);
  function channelValidator(uint64 channel, uint64 participantId) public view returns (address);

  // Read channel blocks information
  function blockCount(uint64 channel) public view returns (uint64);
  function blockPart(uint64 channel, uint64 participantId, uint64 blockId) public view returns (bytes reference);
  function blockResult(uint64 channel, uint64 participantId, uint64 blockId) public view returns (bytes32 resultHash, uint256 stake);
  function blockSettlement(uint64 channel, uint64 blockId) public view returns (bytes result);
}
