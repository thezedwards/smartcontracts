pragma solidity ^0.4.18;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/token/StandardToken.sol";

contract StorageToken {

    function add(uint64 amount) public {
        for (int i = 0; i < amount; ++i) {
            data.push(bytes32(sha256(i)));
        }
    }
    
    function free(uint64 amount) public {
        data.length = data.length - amount;
    }

    function add_free(uint64 a, uint64 f) public {
        add(a);
        free(f);
    }

    bytes32[] private data;
}
