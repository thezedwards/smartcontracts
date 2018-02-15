pragma solidity ^0.4.18;

import './CampaignContract.sol';


contract CampaignManagerContract {

  // EVENTS

  event CampaignCreated(uint64 campaignIndex, address campaignAddress);

  // PUBLIC FUNCTIONS

  function CampaignManagerContract(address _token, address _channelManager) public {
    require(_token != address(0) && _channelManager != address(0));
    token = StandardToken(_token);
    channelManager = ChannelManagerContract(_channelManager);
  }

  function () public {
    revert();
  }

  function createCampaign(
    address _dsp,
    string _dbId
  )
    public
    returns (address campaign)
  {
    campaign = new CampaignContract(token, channelManager, msg.sender, _dsp, _dbId);
    campaigns[campaignCount] = campaign;
    campaignCount += 1;
    CampaignCreated(campaignCount - 1, campaign);
  }

  function createCampaignAndChannels(
    address _dsp,
    string _dbId,
    address[] _ssps,
    address[] _auditors,
    string module,
    bytes configuration,
    uint32 minBlockPeriod,
    uint32 partTimeout,
    uint32 resultTimeout,
    uint32 closeTimeout
  )
    public
    returns (CampaignContract campaign)
  {
    require(_ssps.length > 0);
    campaign = new CampaignContract(token, channelManager, msg.sender, _dsp, _dbId);
    for (uint32 i = 0; i < _ssps.length; ++i) {
      campaign.createChannel(module, configuration, _ssps[i], _auditors, minBlockPeriod, partTimeout, resultTimeout, closeTimeout);
    }
    campaigns[campaignCount] = campaign;
    campaignCount += 1;
    CampaignCreated(campaignCount - 1, campaign);
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;

  mapping (uint64 => address) public campaigns;
  uint64 public campaignCount;
}
