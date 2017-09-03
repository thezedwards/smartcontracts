pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20.sol";
import "../registry/SSPRegistry.sol";
import "../registry/DSPRegistry.sol";
import "../registry/PublisherRegistry.sol";
import "../registry/DisputeRegistry.sol";
import "../registry/ArbiterRegistry.sol";
import "../registry/DepositRegistry.sol";
import "../registry/SecurityDepositRegistry.sol";
import "../registry/SpendingDepositRegistry.sol";
import "../dao/StateChannelListener.sol";


contract PapyrusDAO is StateChannelListener {

    ERC20 private token;

    function PapyrusDAO(ERC20 papyrusToken) {
        token = papyrusToken;
        sspRegistry = new SSPRegistry();
        dspRegistry = new DSPRegistry();
        publisherRegistry = new PublisherRegistry();
        disputeRegistry = new DisputeRegistry();
        arbiterRegistry = new ArbiterRegistry();
        securityDepositRegistry = new SecurityDepositRegistry();
        spendingDepositRegistry = new SpendingDepositRegistry();
    }

    /*------------- Abstract Deposit -------------*/

    event DepositReceived(address depositOwner);
    event DepositReturned(address depositOwner, uint256 amount);
    event DepositNotApproved(address depositOwner);

    function returnDeposit(address depositSender, DepositRegistry depositRegistry) private {
        if (depositRegistry.isRegistered(depositSender)) {}
        uint256 amount = depositRegistry.getDeposit(depositSender);
        if (amount > 0) {
            token.transfer(depositSender, amount);
            depositRegistry.unregister(depositSender);
            DepositReturned(depositSender, amount);
        }
    }

    /*---------- Security Deposit ----------*/

    uint256 constant SECURITY_DEPOSIT_SIZE = 10;

    SecurityDepositRegistry private securityDepositRegistry;

    function receiveSecurityDeposit(address depositSender) private returns(bool) {
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

    /*--------- Spending Deposit ---------*/

    SpendingDepositRegistry private spendingDepositRegistry;

    event DepositSpent(address from, address to, uint256 amount);
    event NotEnoughTokens(address spender, uint256 amount);

    function receiveSpendingDeposit(address depositSender, uint256 amount) private returns(bool) {
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

    function spendDeposit(address spender, address receiver, uint256 amount) private returns (bool){
        if (spendingDepositRegistry.spend(spender, amount)) {
            token.transfer(receiver, amount);
            DepositSpent(spender, receiver, amount);
        } else {
            NotEnoughTokens(spender, amount);
        }
    }

    /*--------------- SSP ----------------*/

    SSPRegistry private sspRegistry;

    event SSPRegistered(address sspAddress);
    event SSPUnregistered(address sspAddress);

    //@dev Get direct link to SSPRegistry contract
    function getSspRegistry() constant returns(address sspRegistryAddress) {
        return sspRegistry;
    }

    //@dev Retrieve information about registered SSP
    //@return Address of registered SSP and time when registered
    function findSsp(address sspAddress) constant returns(address owner, uint time) {
        return sspRegistry.getSSP(sspAddress);
    }

    //@dev Register organisation as SSP
    //@param sspAddress address of wallet to register
    function registerSsp(address sspAddress) {
        if (!sspRegistry.isRegistered(sspAddress)) {
            if (receiveSecurityDeposit(sspAddress)) {
                sspRegistry.register(sspAddress);
                SSPRegistered(sspAddress);
            }
        }
    }

    //@dev Unregister SSP and return unused deposit
    //@param Address of SSP to be unregistered
    function unregisterSsp(address sspAddress) {
        if (sspRegistry.isRegistered(sspAddress)) {
            returnDeposit(sspAddress, securityDepositRegistry);
            sspRegistry.unregister(sspAddress);
            SSPUnregistered(sspAddress);
        }
    }

    /*--------------- DSP ----------------*/

    DSPRegistry private dspRegistry;

    event DSPRegistered(address dspAddress);
    event DSPUnregistered(address dspAddress);

    //@dev Get direct link to DSPRegistry contract
    function getDspRegistry() constant returns(address dspRegistryAddress) {
        return dspRegistry;
    }

    //@dev Retrieve information about registered DSP
    //@return Address of registered DSP and time when registered
    function findDsp(address addr) constant returns(address dspAddress, bytes32[3] url, uint time) {
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

    //@dev This method confirms that service (ads) was provided and payment must be performed
    //@param fromDspAddress - payer, payment will be performed from its spending deposit
    //@param toSspAddress - service provider, tokens will be sent directly to its account
    //@param amount - payments amount
    function approvePayment(address fromDspAddress, address toSspAddress, uint256 amount) returns (bool) {
        if (dspRegistry.isRegistered(fromDspAddress) && sspRegistry.isRegistered(toSspAddress)) {
            return spendDeposit(fromDspAddress, toSspAddress, amount);
        } else {
            return false;
        }
    }

    /*------------------ Publishers ---------------*/

    PublisherRegistry private publisherRegistry;

    event PublisherRegistered(address dspAddress);
    event PublisherUnregistered(address dspAddress);

    //@dev Get direct link to PublisherRegistry contract
    function getPublisherRegistry() constant returns(address publisherRegistryAddress) {
        return publisherRegistry;
    }

    //@dev Retrieve information about registered Publisher
    //@return Address of registered Publisher and time when registered
    function findPublisher(address addr) constant returns(address publisherAddress, bytes32[3] url, uint time) {
        return publisherRegistry.getPublisher(addr);
    }

    //@dev Register organisation as Publisher
    //@param dspPublisher address of wallet to register
    function registerPublisher(address publisherAddress, bytes32[3] url) {
        if (!publisherRegistry.isRegistered(publisherAddress)) {
            if (receiveSecurityDeposit(publisherAddress)) {
                publisherRegistry.register(publisherAddress, url);
                PublisherRegistered(publisherAddress);
            }
        }
    }

    //@dev Unregister Publisher and return unused deposit
    //@param Address of Publisher to be unregistered
    function unregisterPublisher(address publisherAddress) {
        if (publisherRegistry.isRegistered(publisherAddress)) {
            returnDeposit(publisherAddress, spendingDepositRegistry);
            returnDeposit(publisherAddress, securityDepositRegistry);
            publisherRegistry.unregister(publisherAddress);
            PublisherUnregistered(publisherAddress);
        }
    }

    /*------------------ Disputes -----------------*/
    DisputeRegistry private disputeRegistry;
    ArbiterRegistry private arbiterRegistry;

    uint8 constant NUMBER_OF_ARBITERS_FOR_DISPUTE = 5;

    function startDispute(address subject) {
        Dispute dispute = new Dispute(msg.sender, subject, token);
        Arbiter[] arbiters;
        for (uint i = 0; i < NUMBER_OF_ARBITERS_FOR_DISPUTE; i++) {
            arbiters.push(arbiterRegistry.getRandomArbiter());
            //TODO check for duplicates
        }
        dispute.addArbiters(arbiters);
    }

    function applyRuntimeUpdate(MemberRole memberRole, address memberAddress, uint impressionsCount, uint fraudCount) {
        uint256[2] memory karmaDiff;
        karmaDiff[0] = impressionsCount;
        karmaDiff[1] = fraudCount;
        if (MemberRole.DSP == memberRole) {
            dspRegistry.applyKarmaDiff(memberAddress, karmaDiff);
        } else if (MemberRole.SSP == memberRole) {
            sspRegistry.applyKarmaDiff(memberAddress, karmaDiff);
        } else if (MemberRole.Publisher == memberRole) {
            publisherRegistry.applyKarmaDiff(memberAddress, karmaDiff);
        }
    }

    function applyAuditorsCheckUpdate(MemberRole memberRole, address memberAddress, uint fraudCountDelta) {

    }
}
