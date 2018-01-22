pragma solidity ^0.4.18;

import './CampaignContract.sol';


contract CampaignManagerContract {

  // EVENTS

  event CampaignCreated(
    address indexed campaign
  );

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
    string _dbId,
    address _advertiser,
    address _dsp
  )
    public
    returns (address campaign)
  {
    campaign = new CampaignContract(token, channelManager, _dbId, _advertiser, _dsp);
    campaigns[campaignCount] = campaign;
    campaignCount += 1;
    CampaignCreated(campaign);
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;

  mapping (uint64 => address) public campaigns;
  uint64 public campaignCount;
}
