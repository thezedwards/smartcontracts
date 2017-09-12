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

    function getSSPRegistry() returns (SSPRegistry);

    function getDSPRegistry() returns (DSPRegistry);

    function getPublisherRegistry() returns (PublisherRegistry);

    function getAuditorRegistry() returns (AuditorRegistry);

    function getSecurityDepositRegistry() returns (DepositRegistry);

    function getSpendingDepositRegistry() returns (DepositRegistry);
}
