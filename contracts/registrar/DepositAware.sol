pragma solidity ^0.4.11;

import "../registry/DepositRegistry.sol";
import "../dao/WithToken.sol";

contract DepositAware is WithToken{
    function returnDeposit(address depositSender, DepositRegistry depositRegistry) internal {
        if (depositRegistry.isRegistered(depositSender)) {}
        uint256 amount = depositRegistry.getDeposit(depositSender);
        if (amount > 0) {
            token.transfer(depositSender, amount);
            depositRegistry.unregister(depositSender);
        }
    }
}
