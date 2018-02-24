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
    uint256 rate,
    address partner,
    address[] auditors,
    uint256[] auditorsRates,
    address disputeResolver,
    uint32[] timeouts
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
    channel = channelManager.createChannel(module, configuration, participants, disputeResolver, timeouts);
    if (channelCounts[partner] == 0) {
      partners[partnerCount] = partner;
      partnerCount += 1;
    }
    channelIndexes[partner][channelCounts[partner]] = channel;
    channelRates[partner][channelCounts[partner]] = rate;
    channelCounts[partner] += 1;
    ChannelCreated(msg.sender, channelCounts[partner] - 1, channel, module, configuration, partner,
      auditors, auditorsRates, disputeResolver, timeouts);
  }

  function settle(address partner, uint64 channel, uint64 blockId) public {
    require(!channelSettlements[partner][channel]);
    channelSettlements[partner][channel] = true;
    uint64 auditorCount = channelManager.channelParticipantCount(channelIndexes[partner][channel]) - 2;
    uint64[] memory impressions = parseImpressions(partner, channel, blockId);
    uint256[] memory sums = parseSums(partner, channel, blockId);
    require(sums[1] >= sums[2]);
    uint256 partnerPayment = sums[1].sub(sums[2]);
    uint256 selfPayment = partnerPayment.mul(channelRates[partner][channel]).div(10**18);
    partnerPayment = partnerPayment.sub(selfPayment);
    if (selfPayment > 0) {
      require(token.transfer(owner, selfPayment));
    }
    if (partnerPayment > 0) {
      require(token.transfer(channelManager.channelParticipant(channel, 1), partnerPayment));
    }
    uint256[] memory auditorsPayments = new uint256[](auditorCount);
    for (uint8 i = 0; i < auditorCount; ++i) {
      address auditorAddress = channelManager.channelParticipant(channel, 2 + i);
      auditorsPayments[i] = auditorsRates[partner][auditorAddress].mul(impressions[3 + i]);
      if (auditorsPayments[i] > 0) {
        require(token.transfer(auditorAddress, auditorsPayments[i]));
      }
    }
    Settle(msg.sender, channel, blockId, impressions, sums, selfPayment, partnerPayment, auditorsPayments);
  }

  // PRIVATE FUNCTIONS

  function parseImpressions(address partner, uint64 channel, uint64 blockId) private view returns(uint64[] impressions) {
    uint64 channelInternal = channelIndexes[partner][channel];
    var result = channelManager.blockSettlement(channelInternal, blockId);
    uint64 auditorCount = channelManager.channelParticipantCount(channelInternal) - 2;
    uint64 totalImpressions;
    uint64 viewedImpressions;
    uint64 rejectedImpressions;
    uint64 clickImpressions;
    assembly {
      totalImpressions := mload(result)
      viewedImpressions := mload(add(result, 0x28))
      rejectedImpressions := mload(add(result, 0x50))
      clickImpressions := mload(add(result, 0x78))
    }
    // 0 - totalImpressions
    // 1 - viewedImpressions
    // 2 - rejectedImpressions
    // 3 - clickImpressions
    // 4+ - precessedImpressions by each auditor
    impressions = new uint64[](4 + auditorCount);
    impressions[0] = totalImpressions;
    impressions[1] = viewedImpressions;
    impressions[2] = rejectedImpressions;
    impressions[3] = clickImpressions;
    for (uint8 i = 0; i < auditorCount; ++i) {
      uint64 precessedImpressions;
      assembly {
        precessedImpressions := mload(add(add(result, 0xA0), mul(i, 0x08)))
      }
      impressions[4 + i] = precessedImpressions;
    }
  }

  function parseSums(address partner, uint64 channel, uint64 blockId) private view returns(uint256[] sums) {
    uint64 channelInternal = channelIndexes[partner][channel];
    var result = channelManager.blockSettlement(channelInternal, blockId);
    uint256 totalSum;
    uint256 viewedSum;
    uint256 rejectedSum;
    uint256 clickSum;
    assembly {
      totalSum := mload(add(result, 0x08))
      viewedSum := mload(add(result, 0x30))
      rejectedSum := mload(add(result, 0x58))
      clickSum := mload(add(result, 0x80))
    }
    // 0 - totalSum
    // 1 - viewedSum
    // 2 - rejectedSum
    // 3 - clickSum
    sums = new uint256[](4);
    sums[0] = totalSum;
    sums[1] = viewedSum;
    sums[2] = rejectedSum;
    sums[3] = clickSum;
  }

  // FIELDS

  StandardToken public token;
  ChannelManagerContract public channelManager;
  address public payer;

  mapping (uint64 => address) public partners;
  uint64 public partnerCount;

  mapping (address => mapping (address => uint256)) public auditorsRates;

  mapping (address => mapping (uint64 => uint64)) public channelIndexes;
  mapping (address => mapping (uint64 => uint256)) public channelRates;
  mapping (address => mapping (uint64 => bool)) public channelSettlements;
  mapping (address => uint64) public channelCounts;
}
