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
    string _dbId
  )
    RtbSettlementContract(_token, _channelManager, _dsp)
    public
  {
    advertiser = _advertiser;
    dbId = _dbId;
    owner = advertiser;
  }

  function () public {
    revert();
  }

  function dsp() public view returns (address) {
    return payer;
  }

  function ssps(uint64 index) public view returns (address) {
    return partners[index];
  }

  function sspCount() public view returns (uint64) {
    return partnerCount;
  }

  // FIELDS

  address public advertiser;
  string public dbId;
}
