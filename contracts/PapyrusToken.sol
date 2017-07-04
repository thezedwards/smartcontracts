pragma solidity ^0.4.8;

import "./zeppelin/lifecycle/Pausable.sol";
import "./zeppelin/token/MintableToken.sol";

/**
 * @title Papyrus token contract (PPR).
 */
contract PapyrusToken is MintableToken, Pausable {

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

  function PapyrusToken() {}

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

  event BecomeTransferable();

  ///////////////////////////////////////////////
  // Functions
  ///////////////////////////////////////////////

  // If ether is sent to this address, send it back.
  function () { throw; }

  // Do not allow transfer ownership.
  function transferOwnership(address newOwner) { throw; }

  // Check limits before mint
  function mint(address _to, uint256 _amount) onlyOwner returns (bool) {
    require(totalSupply.add(_amount) <= PPR_LIMIT);
    return super.mint(_to, _amount);
  }

  // Check transferable state before transfer
  function transfer(address _to, uint _value) canTransfer {
    super.transfer(_to, _value);
  }

  // Check transferable state before transfer
  function transferFrom(address _from, address _to, uint _value) canTransfer {
    super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Called by the owner to make the token transferable
   */
  function makeTransferable() onlyOwner returns (bool) {
    transferable = true;
    BecomeTransferable();
    return true;
  }
}
