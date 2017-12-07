pragma solidity ^0.4.19;

import '../common/ECRecovery.sol';
import '../common/StandardToken.sol';
import './ChannelManagerContract.sol';


// Papyrus State Channel Library
// moved to separate library to save gas
library ChannelLibrary {

  // STRUCTURES

  struct Data {
    uint32 closeTimeout;
    uint32 settleTimeout;
    uint32 auditTimeout;
    uint256 opened;
    uint256 closeRequested;
    uint256 closed;
    uint256 settled;
    uint256 audited;
    ChannelManagerContract manager;

    address sender;
    address receiver;
    address client;
    uint256 balance;
    address auditor;

    // state update for close
    uint256 nonce;
    uint256 completedTransfers;
  }

  struct StateUpdate {
    uint256 nonce;
    uint256 completedTransfers;
  }

  // PUBLIC FUNCTIONS

  /// @notice Sender deposits amount to channel.
  /// must deposit before the channel is opened.
  /// @param amount The amount to be deposited to the address
  /// @return Success if the transfer was successful
  /// @return The new balance of the invoker
  function deposit(Data storage self, uint256 amount)
    public
    senderOnly(self)
    returns (bool success, uint256 balance)
  {
    require(self.opened > 0);
    require(self.closed == 0);
    StandardToken token = self.manager.token();
    require(token.balanceOf(msg.sender) >= amount);
    success = token.transferFrom(msg.sender, this, amount);
    if (success) {
      self.balance += amount;
      return (true, self.balance);
    }
    return (false, 0);
  }

  function requestClose(Data storage self) public {
    require(msg.sender == self.sender || msg.sender == self.receiver);
    require(self.closeRequested == 0);
    self.closeRequested = block.number;
  }

  function close(
    Data storage self,
    address channel,
    uint256 nonce,
    uint256 completedTransfers,
    bytes signature
  )
    public
  {
    if (self.closeTimeout > 0) {
      require(self.closeRequested > 0);
      require(block.number - self.closeRequested >= self.closeTimeout);
    }
    require(nonce > self.nonce);
    require(completedTransfers >= self.completedTransfers);
    require(completedTransfers <= self.balance);

    if (msg.sender != self.sender) {
      //checking signature
      bytes32 signedHash = hashState(channel, nonce, completedTransfers);
      address signAddress = ECRecovery.recover(signedHash, signature);
      require(signAddress == self.sender);
    }

    if (self.closed == 0) {
        self.closed = block.number;
    }

    self.nonce = nonce;
    self.completedTransfers = completedTransfers;
  }

  /// @notice Settles the balance between the two parties
  /// @dev Settles the balances of the two parties fo the channel
  /// @return The participants with netted balances
  function settle(Data storage self)
    public
    notSettledButClosed(self)
    timeoutOver(self)
  {
    StandardToken token = self.manager.token();
    
    if (self.completedTransfers > 0) {
      require(token.transfer(self.receiver, self.completedTransfers));
    }

    if (self.completedTransfers < self.balance) {
      require(token.transfer(self.sender, self.balance - self.completedTransfers));
    }

    self.settled = block.number;
  }

  function audit(Data storage self, address auditor)
    public
    notAuditedButClosed(self)
  {
    require(self.auditor == auditor);
    require(block.number <= self.closed + self.auditTimeout);
    self.audited = block.number;
  }

  function validateTransfer(
    Data storage self,
    address transferId,
    address channel,
    uint256 sum,
    bytes lockData,
    bytes signature
  )
    public
    view
    returns (uint256)
  {

    bytes32 signedHash = hashTransfer(transferId, channel, lockData, sum);
    address signAddress = ECRecovery.recover(signedHash, signature);
    require(signAddress == self.client);
  }

  function hashState(address channel, uint256 nonce, uint256 completedTransfers) public pure returns (bytes32) {
    return keccak256(channel, nonce, completedTransfers);
  }

  function hashTransfer(address transferId, address channel, bytes lockData, uint256 sum) public pure returns (bytes32) {
    if (lockData.length > 0) {
      return keccak256(transferId, channel, sum, lockData);
    } else {
      return keccak256(transferId, channel, sum);
    }
  }

  // MODIFIERS

  modifier notSettledButClosed(Data storage self) {
    require(self.settled <= 0 && self.closed > 0);
    _;
  }

  modifier notAuditedButClosed(Data storage self) {
    require(self.audited <= 0 && self.closed > 0);
    _;
  }

  modifier stillTimeout(Data storage self) {
    require(self.closed + self.settleTimeout >= block.number);
    _;
  }

  modifier timeoutOver(Data storage self) {
    require(self.closed + self.settleTimeout <= block.number);
    _;
  }

  modifier channelSettled(Data storage self) {
    require(self.settled != 0);
    _;
  }

  modifier senderOnly(Data storage self) {
    require(self.sender == msg.sender);
    _;
  }

  modifier receiverOnly(Data storage self) {
    require(self.receiver == msg.sender);
    _;
  }
}