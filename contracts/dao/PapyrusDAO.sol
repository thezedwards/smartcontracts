pragma solidity ^0.4.11;

import "../zeppelin/ownership/Ownable.sol";
import "../registry/SSPRegistry.sol";

contract PapyrusDAO {

    function PapyrusDAO() {
        sspRegistry = new SSPRegistry();
    }

    /*--------------- SSP ----------------*/

    SSPRegistry sspRegistry;

    event SSPRegistered(address sspAddress);
    event SSPUnregistered(address sspAddress);

    function findSsp(address sspAddress) constant returns(address owner, uint time) {
        return sspRegistry.getSSP(sspAddress);
    }

    function registerSsp(address sspAddress) {
        if (!sspRegistry.isRegistered(sspAddress)) {
            sspRegistry.register(sspAddress);
            SSPRegistered(sspAddress);
        }
    }

    function unregisterSsp(address sspAddress) {
        if (sspRegistry.isRegistered(sspAddress)) {
            sspRegistry.unregister(sspAddress);
            SSPUnregistered(sspAddress);
        }
    }
}
