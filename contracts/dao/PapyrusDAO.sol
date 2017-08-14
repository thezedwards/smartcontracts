pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20.sol";
import "../registry/SSPRegistry.sol";
import "../registry/DSPRegistry.sol";
import "../registry/DepositRegistry.sol";


contract PapyrusDAO {

    ERC20 private token;

    function PapyrusDAO(ERC20 papyrusToken) {
        token = papyrusToken;
        sspRegistry = new SSPRegistry();
        dspRegistry = new DSPRegistry();
        depositRegistry = new DepositRegistry();
    }

    /*------------- Deposit --------------*/

    uint256 constant DEPOSIT_SIZE = 10;

    DepositRegistry private depositRegistry;

    event DepositReceived(address depositOwner);
    event DepositReturned(address depositOwner, uint256 amount);
    event DepositNotApproved(address depositOwner);

    function receiveDeposit(address depositSender) private returns(bool) {
        if (token.balanceOf(depositSender) > DEPOSIT_SIZE && token.allowance(depositSender, this) >= DEPOSIT_SIZE) {
            token.transferFrom(depositSender, this, DEPOSIT_SIZE);
            depositRegistry.register(depositSender, DEPOSIT_SIZE);
            DepositReceived(depositSender);
            return true;
        } else {
            DepositNotApproved(depositSender);
            return false;
        }
    }

    function returnDeposit(address depositSender) private {
        uint256 amount = depositRegistry.getDeposit(depositSender);
        if (amount > 0) {
            token.transfer(depositSender, amount);
            depositRegistry.unregister(depositSender);
            DepositReturned(depositSender, amount);
        }
    }

    /*--------------- SSP ----------------*/

    SSPRegistry private sspRegistry;

    event SSPRegistered(address sspAddress);
    event SSPUnregistered(address sspAddress);

    function getSspRegistry() constant returns(address sspRegistryAddress) {
        return sspRegistry;
    }

    function findSsp(address sspAddress) constant returns(address owner, uint time) {
        return sspRegistry.getSSP(sspAddress);
    }

    function registerSsp(address sspAddress) {
        if (!sspRegistry.isRegistered(sspAddress)) {
            if (receiveDeposit(sspAddress)) {
                sspRegistry.register(sspAddress);
                SSPRegistered(sspAddress);
            }
        }
    }

    function unregisterSsp(address sspAddress) {
        if (sspRegistry.isRegistered(sspAddress)) {
            returnDeposit(sspAddress);
            sspRegistry.unregister(sspAddress);
            SSPUnregistered(sspAddress);
        }
    }

    /*--------------- DSP ----------------*/

    DSPRegistry private dspRegistry;

    event DSPRegistered(address dspAddress);
    event DSPUnregistered(address dspAddress);

    function getDspRegistry() constant returns(address dspRegistryAddress) {
        return dspRegistry;
    }

    function findDsp(address addr) constant returns(address dspAddress, uint time) {
        return dspRegistry.getDSP(addr);
    }

    function registerDsp(address dspAddress) {
        if (!dspRegistry.isRegistered(dspAddress)) {
            if (receiveDeposit(dspAddress)) {
                dspRegistry.register(dspAddress);
                DSPRegistered(dspAddress);
            }
        }
    }

    function unregisterDsp(address dspAddress) {
        if (dspRegistry.isRegistered(dspAddress)) {
            returnDeposit(dspAddress);
            dspRegistry.unregister(dspAddress);
            DSPUnregistered(dspAddress);
        }
    }
}
