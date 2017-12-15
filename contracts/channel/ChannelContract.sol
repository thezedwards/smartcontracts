pragma solidity ^0.4.19;

import "./ChannelLibrary.sol";


contract ChannelContract {
  using ChannelLibrary for ChannelLibrary.Role;
  using ChannelLibrary for ChannelLibrary.ChannelData;

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
    string module,
    bytes configuration,
    address[] participants,
    uint32 closeTimeout,
    uint32 settleTimeout,
    uint32 auditTimeout
  )
    public
  {
    // allow creation only from manager contract
    require(msg.sender == manager);
    require(participants.length >= 3);
    require(closeTimeout >= 0);
    require(settleTimeout > 0);
    require(auditTimeout >= 0);
    data.manager = ChannelManagerContract(manager);
    data.module = module;
    data.configuration = configuration;
    data.participants.length = participants.length;
    for (uint16 i = 0; i < participants.length; ++i) {
      data.participants[i].participant = participants[i];
    }
    data.closeTimeout = closeTimeout;
    data.settleTimeout = settleTimeout;
    data.auditTimeout = auditTimeout;
    data.opened = block.number;
  }

  function () public {
    revert();
  }

  /// @notice Sender deposits amount to channel. Should be called before the channel is closed.
  /// @param participant The amount to be deposited to the address
  /// @param amount The amount to be deposited to the address
  /// @return Success if the transfer was successful
  /// @return The new balance of the invoker
  function deposit(address participant, uint256 amount) public returns (bool) {
    bool success;
    uint256 balance;
    (success, balance) = data.deposit(participant, amount);
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
  function close(uint256 nonce, bytes signature) public {
    data.close(address(this), nonce, signature);
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
  function participant(uint256 index)
    public
    view
    returns (address participantAddress, address validatorAddress, uint256 balance)
  {
    participantAddress = data.participants[index].participant;
    validatorAddress = data.participants[index].validator;
    balance = data.participants[index].balance;
  }

  function blockPart(uint256 participantIndex, uint64 blockNumber)
    public
    view
    returns (bytes reference)
  {
    reference = data.participants[participantIndex].blockParts[blockNumber].reference;
  }

  function blockResult(uint256 participantIndex, uint64 blockNumber)
    public
    view
    returns (uint256 resultHash, uint256 stake)
  {
    resultHash = data.participants[participantIndex].blockResults[blockNumber].resultHash;
    stake = data.participants[participantIndex].blockResults[blockNumber].stake;
  }
  
  function dsp() public view returns (address) {
    return data.participants[uint(ChannelLibrary.Role.DSP)].participant;
  }

  function ssp() public view returns (address) {
    return data.participants[uint(ChannelLibrary.Role.SSP)].participant;
  }
  
  function auditor() public view returns (address) {
    return data.participants[uint(ChannelLibrary.Role.Auditor)].participant;
  }

  function sspPayment() public view returns (uint256) {
    return data.participants[uint(ChannelLibrary.Role.SSP)].balance;
  }

  function auditorPayment() public view returns (uint256) {
    return data.participants[uint(ChannelLibrary.Role.Auditor)].balance;
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

  function nonce() public view returns (uint256) {
    return data.nonce;
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

  ChannelLibrary.ChannelData data;
}
