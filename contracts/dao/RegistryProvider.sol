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

    function getSSPRegistry() internal constant returns (SSPRegistry);

    function getDSPRegistry() internal constant returns (DSPRegistry);

    function getPublisherRegistry() internal constant returns (PublisherRegistry);

    function getAuditorRegistry() internal constant returns (AuditorRegistry);

    function getSecurityDepositRegistry() internal constant returns (DepositRegistry);
}
