pragma solidity ^0.4.18;

import '../common/StandardToken.sol';
import './ChannelManagerContract.sol';
import './SettlementApi.sol';


contract RtbSettlementContract is SettlementApi {
  using SafeMath for uint256;

  // EVENTS

  event Deposit(address indexed sender, uint256 balance);

  // PUBLIC FUNCTIONS

  function RtbSettlementContract(address _token, address _channelManager) public {
    require(_token != address(0) && _channelManager != address(0));
    token = StandardToken(_token);
    channelManager = ChannelManagerContract(_channelManager);
  }

  /// @notice Sender deposits amount to participant.
  /// @param amount The amount to be deposited to the contract
  /// @return success Success if the transfer was successful
  /// @return balance The new balance of the contract
  function deposit(uint256 amount) public returns (bool success, uint256 balance) {
    require(token.balanceOf(msg.sender) >= amount);
    success = token.transferFrom(msg.sender, this, amount);
    if (success) {
      contractBalance = contractBalance.add(amount);
      Deposit(msg.sender, contractBalance);
    }
    return (success, contractBalance);
  }

  function settle(uint64 channel, uint64 blockId) public {
    var result = channelManager.blockSettlement(channel, blockId);
    uint256 sspPayment;
    uint256 auditorPayment;
    uint64 totalImpressions;
    uint64 fraudImpressions;
    assembly {
      sspPayment := mload(result)
      auditorPayment := mload(add(result, 0x20))
      totalImpressions := mload(add(result, 0x40))
      fraudImpressions := mload(add(result, 0x48))
    }
    if (sspPayment > 0) {
      var (sspAddress, /*sspValidator*/) = channelManager.participant(channel, 1);
      require(token.transfer(sspAddress, sspPayment));
    }
    if (auditorPayment > 0) {
      var (auditorAddress, /*auditorValidator*/) = channelManager.participant(channel, 2);
      require(token.transfer(auditorAddress, auditorPayment));
    }
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;

  uint256 contractBalance;
}