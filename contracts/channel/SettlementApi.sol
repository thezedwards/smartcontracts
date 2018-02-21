pragma solidity ^0.4.18;


contract SettlementApi {

  // EVENTS

  event Deposit(address indexed sender, uint256 balance);
  event Withdraw(address indexed receiver, uint256 balance);

  event ChannelCreated(address indexed creator, uint64 channel, uint64 channelInternal, string module, bytes configuration,
    address partner, address[] auditors, uint256[] auditorsRates, address disputeResolver, uint32[] timeouts);
  event Settle(address indexed sender, uint64 channel, uint64 blockId, uint64[] impressions, uint256[] sums,
    uint256 selfPayment, uint256 partnerPayment, uint256[] auditorsPayments);

  // PUBLIC FUNCTIONS
  
  function deposit(uint256 amount) public returns (bool success, uint256 balance);
  function withdraw(uint256 amount) public returns (bool success, uint256 balance);

  function createChannel(string module, bytes configuration, uint256 rate, address partner, address[] auditors,
    uint256[] auditorsRates, address disputeResolver, uint32[] timeouts) public returns (uint64 channel);
  function settle(address partner, uint64 channel, uint64 blockId) public;
}
