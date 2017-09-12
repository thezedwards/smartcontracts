pragma solidity ^0.4.11;

import "../registry/SSPRegistry.sol";
import "../registry/DSPRegistry.sol";
import "../registry/PublisherRegistry.sol";
import "../registry/AuditorRegistry.sol";
import "../registry/DepositRegistry.sol";
import "../registry/DepositRegistry.sol";

contract RegistryProvider {
    function replaceSSPRegistry(SSPRegistry newRegistry);

    function replaceDSPRegistry(DSPRegistry newRegistry);

    function replacePublisherRegistry(PublisherRegistry newRegistry) ;

    function replaceAuditorRegistry(AuditorRegistry newRegistry);

    function replaceSecurityDepositRegistry(DepositRegistry newRegistry);

    function replaceSpendingDepositRegistry(DepositRegistry newRegistry);

    function getSSPRegistry() constant returns (SSPRegistry);

    function getDSPRegistry() constant returns (DSPRegistry);

    function getPublisherRegistry() constant returns (PublisherRegistry);

    function getAuditorRegistry() constant returns (AuditorRegistry);

    function getSecurityDepositRegistry() constant returns (DepositRegistry);

    function getSpendingDepositRegistry() constant returns (DepositRegistry);
}
