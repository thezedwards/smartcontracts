pragma solidity ^0.4.11;

import "../registry/DepositRegistry.sol";
import "../dao/WithToken.sol";

contract DepositAware is WithToken{
    function returnDeposit(address depositAccount, DepositRegistry depositRegistry) internal {
        if (depositRegistry.isRegistered(depositAccount)) {
            uint256 amount = depositRegistry.getDeposit(depositAccount);
            address depositOwner = depositRegistry.getDepositOwner(depositAccount);
            if (amount > 0) {
                token.transfer(depositOwner, amount);
                depositRegistry.unregister(depositAccount);
            }
        }
    }
}
