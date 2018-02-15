pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import '../common/SafeOwnable.sol';
import './ChannelManagerContract.sol';
import './SettlementApi.sol';


contract RtbSettlementContract is SafeOwnable, SettlementApi {
  using SafeMath for uint256;

  // PUBLIC FUNCTIONS

  function RtbSettlementContract(address _token, address _channelManager) public {
    require(_token != address(0) && _channelManager != address(0));
    token = StandardToken(_token);
    channelManager = ChannelManagerContract(_channelManager);
  }

  /// @notice Sender deposits amount of tokens.
  /// @param amount The amount to be deposited to the contract
  /// @return success Success if the transfer was successful
  /// @return contractBalance The new contractBalance of the contract
  function deposit(uint256 amount) public returns (bool success, uint256 contractBalance) {
    require(token.balanceOf(msg.sender) >= amount);
    success = token.transferFrom(msg.sender, this, amount);
    if (success) {
      contractBalance = contractBalance.add(amount);
      Deposit(msg.sender, contractBalance);
    }
    return (success, contractBalance);
  }

  /// @notice Sender withdraws amount of tokens.
  /// @param amount The amount to be withdrawn from the contract
  /// @return success Success if the transfer was successful
  /// @return contractBalance The new contractBalance of the contract
  function withdraw(uint256 amount) public onlyOwner returns (bool success, uint256 contractBalance) {
    require(token.balanceOf(this) >= amount);
    success = token.transfer(owner, amount);
    if (success) {
      contractBalance = contractBalance.sub(amount);
      Withdraw(owner, contractBalance);
    }
    return (success, contractBalance);
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
    for (uint8 i = 0; i < participantCount - 2; ++i) {
      uint256 auditorPayment;
      assembly {
        auditorPayment := mload(add(add(result, 0x30), mul(i, 0x20)))
      }
      if (auditorPayment > 0) {
        address auditorAddress = channelManager.channelParticipant(channel, 2);
        require(token.transfer(auditorAddress, auditorPayment));
      }
    }
    Settle(msg.sender, channel, blockId);
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;

  mapping (uint64 => address) public partners;
  uint64 public partnerCount;

  mapping (address => mapping (uint64 => uint64)) public channelIndexes;
  mapping (address => mapping (uint64 => bool)) public channelSettlements;
  mapping (address => uint64) public channelCounts;

  uint256 public contractBalance;
}
