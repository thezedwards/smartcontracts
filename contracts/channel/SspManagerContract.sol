pragma solidity ^0.4.18;

import './SspContract.sol';


contract SspManagerContract {

  // EVENTS

  event SspCreated(uint64 sspIndex, address sspAddress);

  // PUBLIC FUNCTIONS

  function SspManagerContract(address _token, address _channelManager) public {
    require(_token != address(0) && _channelManager != address(0));
    token = StandardToken(_token);
    channelManager = ChannelManagerContract(_channelManager);
  }

  function () public {
    revert();
  }

  function createSsp(
    address _ssp,
    uint256 _feeRate
  )
    public
    returns (address ssp)
  {
    ssp = new SspContract(token, channelManager, _ssp, _feeRate);
    ssps[sspCount] = ssp;
    sspCount += 1;
    SspCreated(sspCount - 1, ssp);
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;

  mapping (uint64 => address) public ssps;
  uint64 public sspCount;
}
