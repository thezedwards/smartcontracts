pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import './RtbSettlementContract.sol';


contract CampaignContract is RtbSettlementContract {

  // EVENTS

  event ChannelCreated(address indexed creator, uint64 channel, uint64 channelInternal, string module, bytes configuration,
    address ssp, address[] auditors, uint32 minBlockPeriod, uint32 partTimeout, uint32 resultTimeout, uint32 closeTimeout);

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
    address[] auditors,
    uint32 minBlockPeriod,
    uint32 partTimeout,
    uint32 resultTimeout,
    uint32 closeTimeout
  )
    public
    returns (uint64 channel)
  {
    address[] memory participants = new address[](2 + auditors.length);
    participants[0] = dsp;
    participants[1] = ssp;
    for (uint8 i = 0; i < auditors.length; ++i) {
      participants[2 + i] = auditors[i];
    }
    channel = channelManager.createChannel(module, configuration, participants, minBlockPeriod, partTimeout, resultTimeout, closeTimeout);
    if (channelCounts[ssp] == 0) {
      partners[partnerCount] = ssp;
      partnerCount += 1;
    }
    channelIndexes[ssp][channelCounts[ssp]] = channel;
    channelCounts[ssp] += 1;
    ChannelCreated(msg.sender, channelCounts[ssp] - 1, channel, module, configuration, ssp, auditors, minBlockPeriod, partTimeout, resultTimeout, closeTimeout);
  }

  function ssps(uint64 index) public view returns (address) {
    return partners[index];
  }

  function sspCount() public view returns (uint64) {
    return partnerCount;
  }

  // FIELDS

  address public advertiser;
  address public dsp;
  string public dbId;
}
