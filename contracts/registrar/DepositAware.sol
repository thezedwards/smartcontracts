pragma solidity ^0.4.11;

import "../registry/DepositRegistry.sol";
import "../dao/WithToken.sol";

contract DepositAware is WithToken{
    event DepositReceived(address depositOwner);
    event DepositReturned(address depositOwner, uint256 amount);
    event DepositNotApproved(address depositOwner);

    function returnDeposit(address depositSender, DepositRegistry depositRegistry) internal {
        if (depositRegistry.isRegistered(depositSender)) {}
        uint256 amount = depositRegistry.getDeposit(depositSender);
        if (amount > 0) {
            token.transfer(depositSender, amount);
            depositRegistry.unregister(depositSender);
            DepositReturned(depositSender, amount);
        }
    }
}
