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
    uint256 _feeRate
  )
    public
    returns (address campaign)
  {
    campaign = new CampaignContract(token, channelManager, msg.sender, _dsp, _feeRate);
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
