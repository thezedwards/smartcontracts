pragma solidity ^0.4.18;


contract SettlementApi {

  // EVENTS

  event Deposit(address indexed sender, uint256 balance);
  event Withdraw(address indexed receiver, uint256 balance);

  event ChannelCreated(address indexed creator, uint64 channel, uint64 channelInternal, string module, bytes configuration,
    address partner, address[] auditors, uint256[] auditorsRates, uint32 minBlockPeriod, uint32 partTimeout, uint32 resultTimeout, uint32 closeTimeout);
  event Settle(address indexed sender, uint64 channel, uint64 blockId, uint64 totalImpressions, uint64 rejectedImpressions, uint256 partnerPayment, uint256[] auditorsPayments);

  // PUBLIC FUNCTIONS
  
  function deposit(uint256 amount) public returns (bool success, uint256 balance);
  function withdraw(uint256 amount) public returns (bool success, uint256 balance);

  function createChannel(string module, bytes configuration, address partner, address[] auditors, uint256[] auditorsRates,
    uint32 minBlockPeriod, uint32 partTimeout, uint32 resultTimeout, uint32 closeTimeout) public returns (uint64 channel);
  function settle(address partner, uint64 channel, uint64 blockId) public;
}
