pragma solidity ^0.4.11;

import "../registry/DepositRegistry.sol";
import "./DepositAware.sol";

contract SecurityDepositAware is DepositAware{
    uint256 constant SECURITY_DEPOSIT_SIZE = 10;

    DepositRegistry public securityDepositRegistry;

    function receiveSecurityDeposit(address depositAccount) internal {
        token.transferFrom(msg.sender, this, SECURITY_DEPOSIT_SIZE);
        securityDepositRegistry.register(depositAccount, SECURITY_DEPOSIT_SIZE, msg.sender);
    }
}
