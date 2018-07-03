pragma solidity ^0.4.24;

import '../common/StandardToken.sol';
import './RtbSettlementContract.sol';


contract SspContract is RtbSettlementContract {

  // PUBLIC FUNCTIONS

  constructor(
    address _token,
    address _channelManager,
    address _ssp,
    uint256 _feeRate
  )
    RtbSettlementContract(_token, _channelManager, _ssp, _feeRate)
    public
  {
    owner = _ssp;
  }

  function () public {
    revert();
  }

  function deposit(uint256) public returns (bool, uint256) {
    // Turned off for SSP contract for now
    revert();
  }

  function withdraw(uint256) public returns (bool, uint256) {
    // Turned off for SSP contract for now
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

  // INTERNAL FUNCTIONS

  function feeReceiver() internal view returns (address) {
    return payer;
  }
}
