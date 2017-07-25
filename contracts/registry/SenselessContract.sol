pragma solidity ^0.4.11;

import './EventLogger.sol';

contract SenselessContract is EventLogger{
    function SenselessContract(){
        register("first", "CONTRACT_CREATING", msg.sender, "First info");
    }

    function doSmth(string what) {
        register("second", "DID_SOMETHING", msg.sender, what);
    }
}
