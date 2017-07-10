pragma solidity ^0.4.8;

import "./MintableToken.sol";

/**
 * @title Papyrus token contract (PPR).
 */
contract PapyrusToken is MintableToken {

  ///////////////////////////////////////////////
  // Pre-defined constants
  ///////////////////////////////////////////////

  string  private constant PPR_NAME                   = "Papyrus Token";
  string  private constant PPR_SYMBOL                 = "PPR";
  uint8   private constant PPR_DECIMALS               = 18;
  string  private constant PPR_VERSION                = "H0.1";
  uint256 private constant PPR_LIMIT                  = uint256(10) ** (PPR_DECIMALS + 9);

  ///////////////////////////////////////////////
  // State variables and constructor
  ///////////////////////////////////////////////

  // Human Token related state variables
  string public name = PPR_NAME;
  uint8 public decimals = PPR_DECIMALS;
  string public symbol = PPR_SYMBOL;
  string public version = "H0.1";

  // At the start of the token existance it is not transferable
  bool public transferable = false;

  function PapyrusToken() {
    mintingCap = PPR_LIMIT;
  }

  ///////////////////////////////////////////////
  // Function modifiers
  ///////////////////////////////////////////////

  modifier canTransfer() {
    require(transferable);
    _;
  }

  ///////////////////////////////////////////////
  // Events
  ///////////////////////////////////////////////

  event BecameTransferable();

  ///////////////////////////////////////////////
  // Functions
  ///////////////////////////////////////////////

  // If ether is sent to this address, send it back.
  function () { throw; }

  // Check transferable state before transfer
  function transfer(address _to, uint _value) canTransfer {
    super.transfer(_to, _value);
  }

  // Check transferable state before transfer
  function transferFrom(address _from, address _to, uint _value) canTransfer {
    super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Called by the owner to make the token transferable.
   * @return True if the operation was successful.
   */
  function makeTransferable() onlyOwner returns (bool) {
    transferable = true;
    BecameTransferable();
    return true;
  }
}
