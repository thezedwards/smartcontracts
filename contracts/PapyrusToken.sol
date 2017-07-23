pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/token/StandardToken.sol";

/**
 * @title Papyrus token contract (PPR).
 */
contract PapyrusToken is StandardToken, Ownable {

    string  private constant PPR_NAME       = "Papyrus Token";
    string  private constant PPR_SYMBOL     = "PPR";
    uint8   private constant PPR_DECIMALS   = 18;
    string  private constant PPR_VERSION    = "H0.1";
    uint256 private constant PPR_LIMIT      = uint256(10) ** (PPR_DECIMALS + 9);

    string public name = PPR_NAME;
    uint8 public decimals = PPR_DECIMALS;
    string public symbol = PPR_SYMBOL;
    string public version = PPR_VERSION;

    // At the start of the token existence it is not transferable
    bool public transferable = false;

    event BecameTransferable();

    modifier canTransfer() {
        require(transferable || msg.sender == owner);
        _;
    }

    function PapyrusToken() {
        totalSupply = PPR_LIMIT;
        balances[msg.sender] = PPR_LIMIT;
    }

    // If ether is sent to this address, send it back.
    function() { revert(); }

    // Check transferable state before transfer
    function transfer(address _to, uint _value) canTransfer returns (bool) {
        return super.transfer(_to, _value);
    }

    // Check transferable state before transfer
    function approve(address _spender, uint256 _value) canTransfer returns (bool) {
        return super.approve(_spender, _value);
    }

    // Check transferable state before transfer
    function transferFrom(address _from, address _to, uint _value) canTransfer returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Called by the owner to make the token transferable.
    */
    function makeTransferable() onlyOwner {
        require(!transferable);
        transferable = true;
        BecameTransferable();
    }
}
