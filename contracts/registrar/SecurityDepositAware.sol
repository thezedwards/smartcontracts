pragma solidity ^0.4.11;

import "../registry/DepositRegistry.sol";
import "./DepositAware.sol";

contract SecurityDepositAware is DepositAware{
    uint256 constant SECURITY_DEPOSIT_SIZE = 10;

    DepositRegistry public securityDepositRegistry;

    function receiveSecurityDeposit(address depositSender) internal {
        require(token.balanceOf(depositSender) >= SECURITY_DEPOSIT_SIZE && token.allowance(depositSender, this) >= SECURITY_DEPOSIT_SIZE);
//        token.transferFrom(depositSender, this, SECURITY_DEPOSIT_SIZE);
        securityDepositRegistry.register(depositSender, SECURITY_DEPOSIT_SIZE);
    }
}
