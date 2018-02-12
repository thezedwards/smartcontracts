pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import './RtbSettlementContract.sol';


contract CampaignContract is RtbSettlementContract {

  // EVENTS

  event ChannelCreate(address indexed creator, uint64 channel, string module, bytes configuration, address ssp, address auditor, uint32 closeTimeout);

  // PUBLIC FUNCTIONS

  function CampaignContract(
    address _token,
    address _channelManager,
    address _advertiser,
    address _dsp,
    string _dbId
  )
    RtbSettlementContract(_token, _channelManager)
    public
  {
    advertiser = _advertiser;
    dsp = _dsp;
    dbId = _dbId;
    owner = advertiser;
  }

  function () public {
    revert();
  }

  function createChannel(
    string module,
    bytes configuration,
    address ssp,
    address auditor,
    uint32 closeTimeout
  )
    public
    returns (uint64 channel)
  {
    address[] memory participants = new address[](3);
    participants[0] = dsp;
    participants[1] = ssp;
    participants[2] = auditor;
    channel = channelManager.createChannel(module, configuration, participants, closeTimeout);
    channelIndexes[ssp][channelCounts[ssp]] = channel;
    channelCounts[ssp] += 1;
    ChannelCreate(msg.sender, channelCounts[ssp] - 1, module, configuration, ssp, auditor, closeTimeout);
  }

  // FIELDS

  address public advertiser;
  address public dsp;
  string public dbId;

  address[] public ssps;

  mapping (address => mapping (uint64 => uint64)) public channelIndexes;
  mapping (address => uint64) public channelCounts;
}
