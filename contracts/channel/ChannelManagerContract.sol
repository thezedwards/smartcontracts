pragma solidity ^0.4.19;

import '../common/StandardToken.sol';
import './ChannelApi.sol';
import "./ChannelContract.sol";


contract ChannelManagerContract {

  // EVENTS

  event ChannelNew(
    address channel,
    address indexed sender,
    address client,
    address indexed receiver,
    uint32 closeTimeout,
    uint32 settleTimeout,
    uint32 auditTimeout
  );

  event ChannelDeleted(
    address channel,
    address indexed sender,
    address indexed receiver
  );

  // PUBLIC FUNCTIONS

  function ChannelManagerContract(address _token, address _channelApi) public {
    require(_token != address(0) && _channelApi != address(0));
    token = StandardToken(_token);
    channelApi = ChannelApi(_channelApi);
  }

  /// @notice Create a new channel from msg.sender to receiver
  /// @param receiver The address of the receiver
  /// @param settleTimeout The settle timeout in blocks
  /// @return The address of the newly created ChannelContract.
  function newChannel(
    address client,
    address receiver,
    uint32 closeTimeout,
    uint32 settleTimeout,
    uint32 auditTimeout,
    address auditor
  )
    public
    returns (address)
  {
    address channelAddress = new ChannelContract(this, msg.sender, client, receiver, closeTimeout, settleTimeout, auditTimeout, auditor);
    ChannelNew(channelAddress, msg.sender, client, receiver, closeTimeout, settleTimeout, auditTimeout);
    return channelAddress;
  }

  function auditReport(
    address channelAddress,
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
    channelApi.applyRuntimeUpdate(channel.sender(), channel.receiver(), receiverPayment, auditorPayment, totalImpressions, fraudImpressions);
  }

  function destroyChannel(address channelAddress) public {
    require(channelAddress != address(0));
    ChannelContract channel = ChannelContract(channelAddress);
    require(channel.manager() == address(this));
    ChannelDeleted(channelAddress, channel.sender(), channel.receiver());
    channel.destroy();
  }

  // FIELDS

  StandardToken public token;
  ChannelApi public channelApi;
}
