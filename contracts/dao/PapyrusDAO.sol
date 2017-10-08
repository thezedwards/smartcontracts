pragma solidity ^0.4.11;

import "../common/Ownable.sol";
import "../common/ERC20.sol";
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
                        DepositRegistry _securityDepositRegistry
    ) {
        token = papyrusToken;
        sspRegistry = _sspRegistry;
        dspRegistry = _dspRegistry;
        publisherRegistry = _publisherRegistry;
        auditorRegistry = _auditorRegistry;
        securityDepositRegistry = _securityDepositRegistry;
    }

    event DepositsTransferred(address newDao, uint256 sum);
    event SSPRegistryReplaced(address from, address to);
    event DSPRegistryReplaced(address from, address to);
    event PublisherRegistryReplaced(address from, address to);
    event AuditorRegistryReplaced(address from, address to);
    event SecurityDepositRegistryReplaced(address from, address to);

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

    function replaceChannelContractAddress(address newChannelContract) onlyOwner public {
        require(newChannelContract != address(0));
        ChannelContractAddressChanged(channelContractAddress, newChannelContract);
        channelContractAddress = newChannelContract;
    }

    function getSSPRegistry() internal constant returns (SSPRegistry) {
        return sspRegistry;
    }

    function getDSPRegistry() internal constant returns (DSPRegistry) {
        return dspRegistry;
    }

    function getPublisherRegistry() internal constant returns (PublisherRegistry) {
        return publisherRegistry;
    }

    function getAuditorRegistry() internal constant returns (AuditorRegistry) {
        return auditorRegistry;
    }

    function getSecurityDepositRegistry() internal constant returns (DepositRegistry) {
        return securityDepositRegistry;
    }

    function transferDepositsToNewDao(address newDao) onlyOwner {
        uint256 depositSum = token.balanceOf(this);
        token.transfer(newDao, depositSum);
        DepositsTransferred(newDao, depositSum);
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}
