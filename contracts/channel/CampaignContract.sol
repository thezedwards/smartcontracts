pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import './RtbSettlementContract.sol';


contract CampaignContract is RtbSettlementContract {

  // PUBLIC FUNCTIONS

  function CampaignContract(
    address _token,
    address _channelManager,
    address _advertiser,
    address _dsp,
    uint64 _dbId
  )
    RtbSettlementContract(_token, _channelManager)
    public
  {
    advertiser = _advertiser;
    dsp = _dsp;
    dbId = _dbId;
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
  }

  // FIELDS

  address public advertiser;
  address public dsp;
  address[] public ssps;
  uint64 public dbId;

  mapping (address => mapping (uint64 => uint64)) public channelIndexes;
  mapping (address => uint64) public channelCounts;
}
