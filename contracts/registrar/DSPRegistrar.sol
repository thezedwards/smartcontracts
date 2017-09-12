pragma solidity ^0.4.11;

import "../registry/DSPRegistry.sol";
import "./SecurityDepositAware.sol";
import "./SpendingDepositAware.sol";

contract DSPRegistrar is SecurityDepositAware, SpendingDepositAware{
    DSPRegistry internal dspRegistry;

    event DSPRegistered(address dspAddress);
    event DSPUnregistered(address dspAddress);

    //@dev Retrieve information about registered DSP
    //@return Address of registered DSP and time when registered
    function findDsp(address addr) constant returns(address dspAddress, bytes32[3] url, uint256[2] karma) {
        return dspRegistry.getDSP(addr);
    }

    //@dev Register organisation as DSP
    //@param dspAddress address of wallet to register
    function registerDsp(address dspAddress, bytes32[3] url) {
        if (!dspRegistry.isRegistered(dspAddress)) {
            if (receiveSecurityDeposit(dspAddress)) {
                dspRegistry.register(dspAddress, url);
                DSPRegistered(dspAddress);
            }
        }
    }

    //@dev Unregister DSP and return unused deposit
    //@param Address of DSP to be unregistered
    function unregisterDsp(address dspAddress) {
        if (dspRegistry.isRegistered(dspAddress)) {
            returnDeposit(dspAddress, spendingDepositRegistry);
            returnDeposit(dspAddress, securityDepositRegistry);
            dspRegistry.unregister(dspAddress);
            DSPUnregistered(dspAddress);
        }
    }

    //@dev Refill deposit to spend for ads
    //@param dspAddress - address of dsp to refill
    //@param amount - deposit amount
    function refillSpendingDeposit(address dspAddress, uint256 amount) {
        if (dspRegistry.isRegistered(dspAddress)) {
            receiveSpendingDeposit(dspAddress, amount);
        }
    }
}
