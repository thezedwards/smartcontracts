pragma solidity ^0.4.18;


contract SettlementApi {

  // EVENTS

  event Deposit(address indexed sender, uint256 balance);
  event Withdraw(address indexed receiver, uint256 balance);
  event Settle(address indexed sender, uint64 channel, uint64 blockId);

  // PUBLIC FUNCTIONS
  
  function deposit(uint256 amount) public returns (bool success, uint256 balance);
  function withdraw(uint256 amount) public returns (bool success, uint256 balance);
  function settle(address partner, uint64 channel, uint64 blockId) public;
}
