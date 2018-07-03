pragma solidity ^0.4.24;


contract SettlementApi {

  // EVENTS

  event Deposit(address indexed sender, uint256 balance);
  event Withdraw(address indexed receiver, uint256 balance);

  /// @param partner Address of partner with which registered channel was opened
  /// @param channelIndex Index of registered channel for the partner
  ///   (starts from 0 and increases by 1 for each registration of channel opened with the same partner)
  /// @param channelId Identifier of registered channel in ChannelManager
  /// @param payee Address of partner that should be used to transfer payment
  /// @param auditors Addresses of auditors participating in registered channel
  /// @param auditorsRates Rates of auditors where 1^16 value means 1% rate
  event ChannelRegistered(address partner, uint64 channelIndex, uint64 channelId,
    address payee, address[] auditors, uint256[] auditorsRates);
  //event ChannelCreated(uint64 channel, uint64 channelInternal, bytes configuration,
  //  address partner, address partnerPaymentAddress, address[] auditors, uint256[] auditorsRates, address disputeResolver, uint32[] timeouts);

  /// @param partner Address of partner with which settled channel was opened
  /// @param channelIndex Index of registered channel for the partner
  ///   (starts from 0 and increases by 1 for each registration of channel opened with the same partner)
  /// @param channelId Identifier of channel in ChannelManager
  /// @param blockId Identifier of settled block of the channel in ChannelManager
  /// @param impressions Impressions per type of action
  /// @param sums Amounts per type of action
  /// @param paymentReceivers Addresses received payments
  /// @param paymentAmounts Amounts received by each receiver
  event ChannelBlockSettled(address partner, uint64 channelIndex, uint64 channelId, uint64 blockId,
    uint64[] impressions, uint256[] sums, address[] paymentReceivers, uint256[] paymentAmounts);

  // PUBLIC FUNCTIONS
  
  function deposit(uint256 amount) public returns (bool success, uint256 balance);
  function withdraw(uint256 amount) public returns (bool success, uint256 balance);

  function registerChannel(uint64 channelId, address payee, uint256[] auditorsRates) public;
  function settle(address partner, uint64 channelIndex, uint64 blockId, bytes result) public;

  // INTERNAL FUNCTIONS

  function feeReceiver() internal view returns (address);
}
