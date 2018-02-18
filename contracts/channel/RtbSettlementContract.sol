pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import '../common/SafeOwnable.sol';
import './ChannelManagerContract.sol';
import './SettlementApi.sol';


contract RtbSettlementContract is SafeOwnable, SettlementApi {
  using SafeMath for uint256;

  // PUBLIC FUNCTIONS

  function RtbSettlementContract(address _token, address _channelManager, address _payer) public {
    require(_token != address(0) && _channelManager != address(0) && _payer != address(0));
    token = StandardToken(_token);
    channelManager = ChannelManagerContract(_channelManager);
    payer = _payer;
  }

  /// @notice Sender deposits amount of tokens.
  /// @param amount The amount to be deposited to the contract
  /// @return success Success if the transfer was successful
  /// @return contractBalance The new contractBalance of the contract
  function deposit(uint256 amount) public returns (bool success, uint256 contractBalance) {
    require(token.balanceOf(msg.sender) >= amount);
    success = token.transferFrom(msg.sender, this, amount);
    if (success) {
      Deposit(msg.sender, token.balanceOf(this));
    }
    return (success, token.balanceOf(this));
  }

  /// @notice Sender withdraws amount of tokens.
  /// @param amount The amount to be withdrawn from the contract
  /// @return success Success if the transfer was successful
  /// @return contractBalance The new contractBalance of the contract
  function withdraw(uint256 amount) public onlyOwner returns (bool success, uint256 contractBalance) {
    require(token.balanceOf(this) >= amount);
    success = token.transfer(owner, amount);
    if (success) {
      Withdraw(owner, token.balanceOf(this));
    }
    return (success, token.balanceOf(this));
  }

  function createChannel(
    string module,
    bytes configuration,
    address partner,
    address[] auditors,
    uint256[] auditorsRates,
    uint32 minBlockPeriod,
    uint32 partTimeout,
    uint32 resultTimeout,
    uint32 closeTimeout
  )
    public
    returns (uint64 channel)
  {
    require(auditors.length == auditorsRates.length);
    address[] memory participants = new address[](2 + auditors.length);
    participants[0] = payer;
    participants[1] = partner;
    for (uint8 i = 0; i < auditors.length; ++i) {
      participants[2 + i] = auditors[i];
    }
    channel = channelManager.createChannel(module, configuration, participants, minBlockPeriod, partTimeout, resultTimeout, closeTimeout);
    if (channelCounts[partner] == 0) {
      partners[partnerCount] = partner;
      partnerCount += 1;
    }
    channelIndexes[partner][channelCounts[partner]] = channel;
    channelCounts[partner] += 1;
    ChannelCreated(msg.sender, channelCounts[partner] - 1, channel, module, configuration, partner, auditors, auditorsRates, minBlockPeriod, partTimeout, resultTimeout, closeTimeout);
  }

  function settle(address partner, uint64 channel, uint64 blockId) public {
    require(!channelSettlements[partner][channel]);
    channelSettlements[partner][channel] = true;
    uint64 channelInternal = channelIndexes[partner][channel];
    var result = channelManager.blockSettlement(channelInternal, blockId);
    uint64 totalImpressions;
    uint64 rejectedImpressions;
    uint256 partnerPayment;
    assembly {
      totalImpressions := mload(result)
      rejectedImpressions := mload(add(result, 0x08))
      partnerPayment := mload(add(result, 0x10))
    }
    if (partnerPayment > 0) {
      address partnerAddress = channelManager.channelParticipant(channel, 1);
      require(token.transfer(partnerAddress, partnerPayment));
    }
    var participantCount = channelManager.channelParticipantCount(channelInternal);
    uint256[] memory auditorsPayments = new uint256[](participantCount - 2);
    for (uint8 i = 0; i < participantCount - 2; ++i) {
      address auditorAddress = channelManager.channelParticipant(channel, 2);
      auditorsPayments[i] = totalImpressions * auditorsRates[partner][auditorAddress];
      if (auditorsPayments[i] > 0) {
        require(token.transfer(auditorAddress, auditorsPayments[i]));
      }
    }
    Settle(msg.sender, channel, blockId, totalImpressions, rejectedImpressions, partnerPayment, auditorsPayments);
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;
  address public payer;

  mapping (uint64 => address) public partners;
  uint64 public partnerCount;

  mapping (address => mapping (address => uint256)) public auditorsRates;

  mapping (address => mapping (uint64 => uint64)) public channelIndexes;
  mapping (address => mapping (uint64 => bool)) public channelSettlements;
  mapping (address => uint64) public channelCounts;
}
