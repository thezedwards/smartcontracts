pragma solidity ^0.4.11;

import "../registry/DepositRegistry.sol";
import "./DepositAware.sol";

contract SecurityDepositAware is DepositAware{
    uint256 constant SECURITY_DEPOSIT_SIZE = 10;

    DepositRegistry internal securityDepositRegistry;

    function receiveSecurityDeposit(address depositSender) internal returns(bool) {
        if (token.balanceOf(depositSender) > SECURITY_DEPOSIT_SIZE && token.allowance(depositSender, this) >= SECURITY_DEPOSIT_SIZE) {
            token.transferFrom(depositSender, this, SECURITY_DEPOSIT_SIZE);
            securityDepositRegistry.register(depositSender, SECURITY_DEPOSIT_SIZE);
            DepositReceived(depositSender);
            return true;
        } else {
            DepositNotApproved(depositSender);
            return false;
        }
    }
}
