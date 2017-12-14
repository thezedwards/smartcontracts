pragma solidity ^0.4.19;

import '../common/StandardToken.sol';
import './ChannelApi.sol';
import "./ChannelContract.sol";


contract ChannelManagerContract {

  // EVENTS

  event ChannelNew(
    address indexed channel,
    string indexed module,
    bytes configuration,
    address[] indexed participants,
    uint32 closeTimeout,
    uint32 settleTimeout,
    uint32 auditTimeout
  );

  event ChannelDeleted(
    address indexed channel
  );

  // PUBLIC FUNCTIONS

  function ChannelManagerContract(address _token, address _channelApi) public {
    require(_token != address(0) && _channelApi != address(0));
    token = StandardToken(_token);
    channelApi = ChannelApi(_channelApi);
  }

  /// @notice Create a new channel for specified participants
  /// @param settleTimeout The settle timeout in blocks
  /// @return The address of the newly created ChannelContract.
  function newChannel(
    string module,
    bytes configuration,
    address[] participants,
    uint32 closeTimeout,
    uint32 settleTimeout,
    uint32 auditTimeout
  )
    public
    returns (address)
  {
    address channelAddress = new ChannelContract(this, module, configuration, participants, closeTimeout, settleTimeout, auditTimeout);
    ChannelNew(channelAddress, module, configuration, participants, closeTimeout, settleTimeout, auditTimeout);
    return channelAddress;
  }

  function auditReport(
    address channelAddress,
    address from,
    address to,
    uint256 receiverPayment,
    uint256 auditorPayment,
    uint64 totalImpressions,
    uint64 fraudImpressions
  )
    public
  {
    require(channelAddress != address(0));
    ChannelContract channel = ChannelContract(channelAddress);
    require(channel.manager() == address(this));
    channel.audit(msg.sender);
    channelApi.applyRuntimeUpdate(from, to, receiverPayment, auditorPayment, totalImpressions, fraudImpressions);
  }

  function destroyChannel(address channelAddress) public {
    require(channelAddress != address(0));
    ChannelContract channel = ChannelContract(channelAddress);
    require(channel.manager() == address(this));
    ChannelDeleted(channelAddress);
    channel.destroy();
  }

  // FIELDS

  StandardToken public token;
  ChannelApi public channelApi;
}
