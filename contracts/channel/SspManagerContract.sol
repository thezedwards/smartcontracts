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
    string _dbId
  )
    public
    returns (address ssp)
  {
    ssp = new SspContract(token, channelManager, _ssp, _dbId);
    ssps[sspCount] = ssp;
    sspCount += 1;
    SspCreated(sspCount - 1, ssp);
  }

  function createCampaignAndChannels(
    address _ssp,
    string _dbId,
    address[] _publishers,
    address[] _auditors,
    uint256[] _auditorsRates,
    string module,
    bytes configuration,
    uint32 minBlockPeriod,
    uint32 partTimeout,
    uint32 resultTimeout,
    uint32 closeTimeout
  )
    public
    returns (SspContract ssp)
  {
    require(_publishers.length > 0);
    ssp = new SspContract(token, channelManager, _ssp, _dbId);
    for (uint32 i = 0; i < _publishers.length; ++i) {
      ssp.createChannel(module, configuration, _publishers[i], _auditors, _auditorsRates, minBlockPeriod, partTimeout, resultTimeout, closeTimeout);
    }
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
