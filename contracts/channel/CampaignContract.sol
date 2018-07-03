pragma solidity ^0.4.24;

import '../common/StandardToken.sol';
import './RtbSettlementContract.sol';


contract CampaignContract is RtbSettlementContract {

  // PUBLIC FUNCTIONS

  constructor(
    address _token,
    address _channelManager,
    address _advertiser,
    address _dsp,
    uint256 _feeRate
  )
    RtbSettlementContract(_token, _channelManager, _dsp, _feeRate)
    public
  {
    advertiser = _advertiser;
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

  // INTERNAL FUNCTIONS

  function feeReceiver() internal view returns (address) {
    return payer;
  }

  // FIELDS

  address public advertiser;
}
