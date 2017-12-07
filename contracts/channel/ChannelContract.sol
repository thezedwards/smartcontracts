pragma solidity ^0.4.19;

import "./ChannelLibrary.sol";


contract ChannelContract {
  using ChannelLibrary for ChannelLibrary.Data;

  // EVENTS

  event ChannelNewBalance(address token, address participant, uint256 balance, uint256 blockNumber);
  event ChannelCloseRequested(address channelAddress, uint256 blockNumber);
  event ChannelClosed(address channelAddress, uint256 blockNumber);
  event TransferUpdated(address nodeAddress, uint256 blockNumber);
  event ChannelSettled(uint256 blockNumber);
  event ChannelAudited(uint256 blockNumber);
  event ChannelSecretRevealed(bytes32 secret, address receiver);

  // PUBLIC FUNCTIONS

  function ChannelContract(
    address manager,
    address sender,
    address client,
    address receiver,
    uint32 closeTimeout,
    uint32 settleTimeout,
    uint32 auditTimeout,
    address auditor
  )
    public
  {
    // allow creation only from manager contract
    require(msg.sender == manager);
    require(sender != receiver);
    require(client != receiver);
    require(closeTimeout >= 0);
    require(settleTimeout > 0);
    require(auditTimeout >= 0);
    data.sender = sender;
    data.client = client;
    data.receiver = receiver;
    data.auditor = auditor;
    data.manager = ChannelManagerContract(manager);
    data.closeTimeout = closeTimeout;
    data.settleTimeout = settleTimeout;
    data.auditTimeout = auditTimeout;
    data.opened = block.number;
  }

  function () public {
    revert();
  }

  /// @notice Caller makes a deposit into their channel balance.
  /// @param amount The amount caller wants to deposit.
  /// @return True if deposit is successful.
  function deposit(uint256 amount) public returns (bool) {
    bool success;
    uint256 balance;
    (success, balance) = data.deposit(amount);
    if (success) {
      ChannelNewBalance(data.manager.token(), msg.sender, balance, 0);
    }
    return success;
  }

  /// @notice Request to close the channel.
  function requestClose() public {
    data.requestClose();
    ChannelCloseRequested(msg.sender, data.closed);
  }

  /// @notice Close the channel.
  function close(uint256 nonce, uint256 completedTransfers, bytes signature) public {
    data.close(address(this), nonce, completedTransfers, signature);
    ChannelClosed(msg.sender, data.closed);
  }

  /// @notice Settle the transfers and balances of the channel and pay out to
  /// each participant. Can only be called after the channel is closed
  /// and only after the number of blocks in the settlement timeout
  /// have passed.
  function settle() public {
    data.settle();
    ChannelSettled(data.settled);
  }

  /// @notice Settle the transfers and balances of the channel and pay out to
  /// each participant. Can only be called after the channel is closed
  /// and only after the number of blocks in the settlement timeout
  /// have passed.
  function audit(address auditor) public onlyManager {
    data.audit(auditor);
    ChannelAudited(data.audited);
  }

  function destroy() public onlyManager {
    require(data.settled > 0);
    require(data.audited > 0 || block.number > data.closed + data.auditTimeout);
    selfdestruct(0);
  }

  /// @notice Get the address and balance of both partners in a channel.
  /// @return The address and balance pairs.
  function addressAndBalance()
    public
    view
    returns (address sender, address receiver, uint256 balance)
  {
    sender = data.sender;
    receiver = data.receiver;
    balance = data.balance;
  }

  function sender() public view returns (address) {
    return data.sender;
  }

  function receiver() public view returns (address) {
    return data.receiver;
  }

  function client() public view returns (address) {
    return data.client;
  }

  function auditor() public view returns (address) {
    return data.auditor;
  }

  function closeTimeout() public view returns (uint32) {
    return data.closeTimeout;
  }

  function settleTimeout() public view returns (uint32) {
    return data.settleTimeout;
  }

  function auditTimeout() public view returns (uint32) {
    return data.auditTimeout;
  }

  /// @return Returns the address of the manager.
  function manager() public view returns (address) {
    return data.manager;
  }

  function balance() public view returns (uint256) {
    return data.balance;
  }

  function nonce() public view returns (uint256) {
    return data.nonce;
  }

  function completedTransfers() public view returns (uint256) {
    return data.completedTransfers;
  }

  /// @notice Returns the block number for when the channel was opened.
  /// @return The block number for when the channel was opened.
  function opened() public view returns (uint256) {
    return data.opened;
  }

  function closeRequested() public view returns (uint256) {
    return data.closeRequested;
  }

  function closed() public view returns (uint256) {
    return data.closed;
  }

  function settled() public view returns (uint256) {
    return data.settled;
  }

  function audited() public view returns (uint256) {
    return data.audited;
  }

  // MODIFIERS

  modifier onlyManager() {
    require(msg.sender == address(data.manager));
    _;
  }

  // FIELDS

  ChannelLibrary.Data data;
}
