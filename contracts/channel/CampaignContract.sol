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
    string _name,
    string _description,
    string _html,
    string _link,
    string _title
  )
    RtbSettlementContract(_token, _channelManager)
    public
  {
    advertiser = _advertiser;
    dsp = _dsp;
    name = _name;
    description = _description;
    html = _html;
    link = _link;
    title = _title;
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
  string public name;
  string public description;
  string public html;
  string public link;
  string public title;

  mapping (address => mapping (uint64 => uint64)) channelIndexes;
  mapping (address => uint64) channelCounts;
}
