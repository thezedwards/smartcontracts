pragma solidity ^0.4.11;

import "../common/Ownable.sol";
import "./ChannelApi.sol";
import "../dao/RegistryProvider.sol";

contract StateChannelListener is RegistryProvider, ChannelApi, Ownable{
    address channelContractAddress;

    event ChannelContractAddressChanged(address indexed previousAddress, address indexed newAddress);

    function applyRuntimeUpdate(address from, address to, uint impressionsCount, uint fraudCount) onlyChannelContract {
        uint256[2] storage karmaDiff;
        karmaDiff[0] = impressionsCount;
        karmaDiff[1] = 0;
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

    function applyAuditorsCheckUpdate(address from, address to, uint fraudCountDelta) onlyChannelContract {
        //To be implemented
    }

    function updateChannelContractAddress(address newChannelContract) onlyOwner public {
        require(newChannelContract != address(0));
        ChannelContractAddressChanged(channelContractAddress, newChannelContract);
        channelContractAddress = newChannelContract;
    }

    modifier onlyChannelContract() {
        require(msg.sender == channelContractAddress);
        _;
    }
}
