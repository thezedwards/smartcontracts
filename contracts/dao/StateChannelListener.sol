pragma solidity ^0.4.11;

contract StateChannelListener {
    function applyRuntimeUpdate(address from, address to, uint impressionsCount, uint fraudCount);

    function applyAuditorsCheckUpdate(address from, address to, uint fraudCountDelta);
}
