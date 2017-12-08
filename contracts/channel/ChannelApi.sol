pragma solidity ^0.4.19;


contract ChannelApi {
  function applyRuntimeUpdate(address from, address to, uint256 receiverPayment, uint256 auditorPayment, uint64 totalImpressions, uint64 fraudImpressions) public;
  function applyAuditorsCheckUpdate(address from, address to, uint64 fraudImpressionsDelta) public;
}
