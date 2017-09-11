pragma solidity ^0.4.11;

import "../registry/DepositRegistry.sol";
import "./DepositAware.sol";

contract SpendingDepositAware is DepositAware {
    DepositRegistry internal spendingDepositRegistry;

    event DepositSpent(address from, address to, uint256 amount);
    event NotEnoughTokens(address spender, uint256 amount);

    function receiveSpendingDeposit(address depositSender, uint256 amount) internal returns(bool) {
        if (token.balanceOf(depositSender) > amount && token.allowance(depositSender, this) >= amount) {
            token.transferFrom(depositSender, this, amount);
            if (spendingDepositRegistry.isRegistered(depositSender)) {
                spendingDepositRegistry.refill(depositSender, amount);
            } else {
                spendingDepositRegistry.register(depositSender, amount);
            }
            DepositReceived(depositSender);
            return true;
        } else {
            DepositNotApproved(depositSender);
            return false;
        }
    }

    function spendDeposit(address spender, address receiver, uint256 amount) internal returns (bool){
        if (spendingDepositRegistry.spend(spender, amount)) {
            token.transfer(receiver, amount);
            DepositSpent(spender, receiver, amount);
        } else {
            NotEnoughTokens(spender, amount);
        }
    }
}
