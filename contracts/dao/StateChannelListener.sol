pragma solidity ^0.4.11;

contract StateChannelListener {
    enum MemberRole {SSP, DSP, Publisher}

    function applyRuntimeUpdate(MemberRole memberRole, int impressionsCount, int fraudCount);

    function applyAuditorsCheckUpdate(MemberRole memberRole, int fraudCountDelta);
}
