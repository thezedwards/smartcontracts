pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20.sol";
import "../registry/SSPRegistry.sol";
import "../registry/impl/SSPRegistryImpl.sol";
import "../registrar/SSPRegistrar.sol";
import "../registry/DSPRegistry.sol";
import "../registry/impl/DSPRegistryImpl.sol";
import "../registrar/DSPRegistrar.sol";
import "../registry/PublisherRegistry.sol";
import "../registry/impl/PublisherRegistryImpl.sol";
import "../registrar/PublisherRegistrar.sol";
import "../registry/AuditorRegistry.sol";
import "../registry/impl/AuditorRegistryImpl.sol";
import "../registrar/AuditorRegistrar.sol";
import "../registry/DepositRegistry.sol";
import "../registry/SecurityDepositRegistry.sol";
import "../registry/SpendingDepositRegistry.sol";
import "../registry/DepositRegistry.sol";
import "../channel/StateChannelListener.sol";
import "./WithToken.sol";

contract PapyrusDAO is WithToken,
                       StateChannelListener,
                       SSPRegistrar,
                       DSPRegistrar,
                       PublisherRegistrar,
                       AuditorRegistrar,
                       Ownable {

    function PapyrusDAO(ERC20 papyrusToken) {
        token = papyrusToken;
        sspRegistry = new SSPRegistryImpl();
        dspRegistry = new DSPRegistryImpl();
        publisherRegistry = new PublisherRegistryImpl();
        auditorRegistry = new AuditorRegistryImpl();
        securityDepositRegistry = new SecurityDepositRegistry();
        spendingDepositRegistry = new SpendingDepositRegistry();
    }

    event SSPRegistryReplaced(address from, address to);
    event DSPRegistryReplaced(address from, address to);
    event PublisherRegistryReplaced(address from, address to);

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
}
