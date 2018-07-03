pragma solidity ^0.4.24;

import './SspContract.sol';


contract SspManagerContract {

  // EVENTS

  event SspCreated(uint64 sspIndex, address sspAddress);

  // PUBLIC FUNCTIONS

  constructor(address _token, address _channelManager) public {
    require(_token != address(0) && _channelManager != address(0));
    token = StandardToken(_token);
    channelManager = ChannelManagerContract(_channelManager);
  }

  function () public {
    revert();
  }

  function createSsp(address ssp, uint256 feeRate) public returns (address sspContract) {
    sspContract = new SspContract(token, channelManager, ssp, feeRate);
    ssps[sspCount] = sspContract;
    sspCount += 1;
    SspCreated(sspCount - 1, sspContract);
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;

  mapping (uint64 => address) public ssps;
  uint64 public sspCount;
}
