pragma solidity ^0.4.11;

import "../registry/DepositRegistry.sol";
import "./DepositAware.sol";

contract SpendingDepositAware is DepositAware {
    DepositRegistry public spendingDepositRegistry;

    function receiveSpendingDeposit(address depositSender, uint256 amount) internal {
        token.transferFrom(depositSender, this, amount);
        if (spendingDepositRegistry.isRegistered(depositSender)) {
            spendingDepositRegistry.refill(depositSender, amount);
        } else {
            spendingDepositRegistry.register(depositSender, amount);
        }
    }

    function spendDeposit(address spender, address receiver, uint256 amount) internal returns (bool){
        if (spendingDepositRegistry.spend(spender, amount)) {
            token.transfer(receiver, amount);
        }
    }
}
