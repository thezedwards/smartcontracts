pragma solidity ^0.4.24;

import './CampaignContract.sol';


contract CampaignManagerContract {

  // EVENTS

  event CampaignCreated(uint64 campaignIndex, address campaignAddress);

  // PUBLIC FUNCTIONS

  constructor(address _token, address _channelManager) public {
    require(_token != address(0) && _channelManager != address(0));
    token = StandardToken(_token);
    channelManager = ChannelManagerContract(_channelManager);
  }

  function () public {
    revert();
  }

  function createCampaign(address dsp, uint256 feeRate) public returns (address campaign) {
    campaign = new CampaignContract(token, channelManager, msg.sender, dsp, feeRate);
    campaigns[campaignCount] = campaign;
    campaignCount += 1;
    emit CampaignCreated(campaignCount - 1, campaign);
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;

  uint64 public campaignCount;
  mapping (uint64 => address) public campaigns;
}
