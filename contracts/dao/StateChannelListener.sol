pragma solidity ^0.4.11;

contract StateChannelListener {
    enum MemberRole {SSP, DSP, Publisher}

    function applyRuntimeUpdate(MemberRole memberRole, address memberAddress, uint impressionsCount, uint fraudCount);

    function applyAuditorsCheckUpdate(MemberRole memberRole, address memberAddress, uint fraudCountDelta);
}
