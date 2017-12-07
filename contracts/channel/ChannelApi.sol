pragma solidity ^0.4.19;


contract ChannelApi {
  function applyRuntimeUpdate(address from, address to, uint64 impressionsCount, uint64 fraudCount) public;
  function applyAuditorsCheckUpdate(address from, address to, uint64 fraudCountDelta) public;
}
