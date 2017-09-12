pragma solidity ^0.4.11;

import "./ChannelApi.sol";
import "../dao/RegistryProvider.sol";

contract StateChannelListener is RegistryProvider, ChannelApi{
    function applyRuntimeUpdate(address from, address to, uint impressionsCount, uint fraudCount) {
        uint256[2] karmaDiff;
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

    function applyAuditorsCheckUpdate(address from, address to, uint fraudCountDelta) {
        //To be implemented
    }
}
