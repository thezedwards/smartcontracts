pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import './RtbSettlementContract.sol';


contract SspContract is RtbSettlementContract {

  // PUBLIC FUNCTIONS

  function SspContract(
    address _token,
    address _channelManager,
    address _ssp,
    string _dbId
  )
    RtbSettlementContract(_token, _channelManager, _ssp)
    public
  {
    dbId = _dbId;
    owner = _ssp;
  }

  function () public {
    revert();
  }

  function ssp() public view returns (address) {
    return payer;
  }

  function publishers(uint64 index) public view returns (address) {
    return partners[index];
  }

  function publisherCount() public view returns (uint64) {
    return partnerCount;
  }

  // FIELDS

  string public dbId;
}
