pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20.sol";
import "../registry/SSPRegistry.sol";
import "../registrar/SSPRegistrar.sol";
import "../registry/DSPRegistry.sol";
import "../registrar/DSPRegistrar.sol";
import "../registry/PublisherRegistry.sol";
import "../registrar/PublisherRegistrar.sol";
import "../registry/AuditorRegistry.sol";
import "../registrar/AuditorRegistrar.sol";
import "../registry/DepositRegistry.sol";
import "../registry/DepositRegistry.sol";
import "../channel/StateChannelListener.sol";
import "./WithToken.sol";

contract PapyrusDAO is WithToken,
                       RegistryProvider,
                       StateChannelListener,
                       SSPRegistrar,
                       DSPRegistrar,
                       PublisherRegistrar,
                       AuditorRegistrar,
                       Ownable {

    function PapyrusDAO(ERC20 papyrusToken,
                        SSPRegistry _sspRegistry,
                        DSPRegistry _dspRegistry,
                        PublisherRegistry _publisherRegistry,
                        AuditorRegistry _auditorRegistry,
                        DepositRegistry _securityDepositRegistry,
                        DepositRegistry _spendingDepositRegistry
    ) {
        token = papyrusToken;
        sspRegistry = _sspRegistry;
        dspRegistry = _dspRegistry;
        publisherRegistry = _publisherRegistry;
        auditorRegistry = _auditorRegistry;
        securityDepositRegistry = _securityDepositRegistry;
        spendingDepositRegistry = _spendingDepositRegistry;
    }

    event SSPRegistryReplaced(address from, address to);
    event DSPRegistryReplaced(address from, address to);
    event PublisherRegistryReplaced(address from, address to);
    event AuditorRegistryReplaced(address from, address to);
    event SecurityDepositRegistryReplaced(address from, address to);
    event SpendingDepositRegistryReplaced(address from, address to);

    function replaceSSPRegistry(SSPRegistry newRegistry) onlyOwner {
        address old = sspRegistry;
        sspRegistry = newRegistry;
        SSPRegistryReplaced(old, newRegistry);
    }

    function replaceDSPRegistry(DSPRegistry newRegistry) onlyOwner {
        address old = dspRegistry;
        dspRegistry = newRegistry;
        DSPRegistryReplaced(old, newRegistry);
    }

    function replacePublisherRegistry(PublisherRegistry newRegistry) onlyOwner {
        address old = publisherRegistry;
        publisherRegistry = newRegistry;
        PublisherRegistryReplaced(old, publisherRegistry);
    }

    function replaceAuditorRegistry(AuditorRegistry newRegistry) onlyOwner {
        address old = auditorRegistry;
        auditorRegistry = newRegistry;
        AuditorRegistryReplaced(old, auditorRegistry);
    }

    function replaceSecurityDepositRegistry(DepositRegistry newRegistry) onlyOwner {
        address old = securityDepositRegistry;
        securityDepositRegistry = newRegistry;
        SecurityDepositRegistryReplaced(old, securityDepositRegistry);
    }

    function replaceSpendingDepositRegistry(DepositRegistry newRegistry) onlyOwner {
        address old = spendingDepositRegistry;
        spendingDepositRegistry = newRegistry;
        SpendingDepositRegistryReplaced(old, spendingDepositRegistry);
    }

    function getSSPRegistry() constant returns (SSPRegistry) {
        return sspRegistry;
    }

    function getDSPRegistry() constant returns (DSPRegistry) {
        return dspRegistry;
    }

    function getPublisherRegistry() constant returns (PublisherRegistry) {
        return publisherRegistry;
    }

    function getAuditorRegistry() constant returns (AuditorRegistry) {
        return auditorRegistry;
    }

    function getSecurityDepositRegistry() constant returns (DepositRegistry) {
        return securityDepositRegistry;
    }

    function getSpendingDepositRegistry() constant returns (DepositRegistry) {
        return spendingDepositRegistry;
    }
}
