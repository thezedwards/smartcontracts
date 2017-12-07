pragma solidity ^0.4.19;

import "../common/Ownable.sol";
import "../dao/RegistryProvider.sol";
import "./ChannelApi.sol";


contract StateChannelListener is RegistryProvider, ChannelApi {

  // EVENTS

  event ChannelContractAddressChanged(address previousAddress, address newAddress);

  // PUBLIC FUNCTIONS

  function applyRuntimeUpdate(address from, address to, uint64 impressionsCount, uint64 fraudCount) public onlyChannelContract {
      uint256[2] memory karmaDiff = [impressionsCount, uint256(0)];
      if (getDSPRegistry().isRegistered(from)) {
          getDSPRegistry().applyKarmaDiff(from, karmaDiff);
      } else if (getSSPRegistry().isRegistered(from)) {
          getSSPRegistry().applyKarmaDiff(from, karmaDiff);
      }

      karmaDiff[1] = fraudCount;
      if (getSSPRegistry().isRegistered(to)) {
          karmaDiff[0] = 0;
          getSSPRegistry().applyKarmaDiff(to, karmaDiff);
      } else if (getPublisherRegistry().isRegistered(to)) {
          karmaDiff[0] = impressionsCount;
          getPublisherRegistry().applyKarmaDiff(to, karmaDiff);
      }
  }

  function applyAuditorsCheckUpdate(address /*from*/, address /*to*/, uint64 /*fraudCountDelta*/) public onlyChannelContract {
    // To be implemented
  }

  // MODIFIERS

  modifier onlyChannelContract() {
    require(msg.sender == channelContractAddress);
    _;
  }

  // FIELDS

  address channelContractAddress;
}
