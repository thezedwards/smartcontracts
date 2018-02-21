pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import './RtbSettlementContract.sol';


contract SspContract is RtbSettlementContract {

  // PUBLIC FUNCTIONS

  function SspContract(
    address _token,
    address _channelManager,
    address _ssp,
    string _dbId
  )
    RtbSettlementContract(_token, _channelManager, address(this))
    public
  {
    dbId = _dbId;
    owner = _ssp;
  }

  function () public {
    revert();
  }

  function deposit(uint256) public returns (bool, uint256) {
    // Turned off for SSP contract for now
    revert();
  }

  function withdraw(uint256) public returns (bool, uint256) {
    // Turned off for SSP contract for now
    revert();
  }

  function approve(uint64 channel, address validator) public onlyOwner {
    channelManager.approve(channel, validator);
  }

  function setBlockPart(uint64 channel, uint64 blockId, uint64 length, bytes32 hash, bytes reference) public onlyOwner {
    channelManager.setBlockPart(channel, blockId, length, hash, reference);
  }

  function setBlockResult(uint64 channel, uint64 blockId, bytes32 resultHash) public onlyOwner {
    channelManager.setBlockResult(channel, blockId, resultHash);
  }

  function blockSettle(uint64 channel, uint64 blockId, bytes result) public onlyOwner {
    channelManager.blockSettle(channel, blockId, result);
  }

  function ssp() public view returns (address) {
    return owner;
  }

  function publishers(uint64 index) public view returns (address) {
    return partners[index];
  }

  function publisherCount() public view returns (uint64) {
    return partnerCount;
  }

  // FIELDS

  string public dbId;
}
