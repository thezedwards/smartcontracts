pragma solidity ^0.4.8;

import "./ConsenSys/HumanStandardToken.sol";
import "./Papyrus.sol";
import "./Ownable.sol";

/**
 * @title Papyrus token contract (PPR).
 */
contract PapyrusToken is HumanStandardToken, Ownable {

  ///////////////////////////////////////////////
  // Pre-defined constants
  ///////////////////////////////////////////////

  string  private constant PPR_NAME                   = "Papyrus Token";
  string  private constant PPR_SYMBOL                 = "PPR";
  uint8   private constant PPR_DECIMALS               = 9;
  uint256 private constant QUANTUMS_PER_PPR           = uint256(10) ** PPR_DECIMALS;
  uint256 private constant LIMIT_TOTAL                = 1000000000 * QUANTUMS_PER_PPR;
  uint256 private constant LIMIT_PRE_SALE_PRIVATE     =   20000000 * QUANTUMS_PER_PPR;
  uint256 private constant LIMIT_PRE_SALE_PUBLIC      =   30000000 * QUANTUMS_PER_PPR;
  uint256 private constant LIMIT_CROWD_SALE_PHASE_1   =  300000000 * QUANTUMS_PER_PPR;
  uint256 private constant LIMIT_CROWD_SALE_PHASE_2   =  300000000 * QUANTUMS_PER_PPR;

  ///////////////////////////////////////////////
  // Custom enumerations and structures
  ///////////////////////////////////////////////

  ///////////////////////////////////////////////
  // State variables and constructor
  ///////////////////////////////////////////////

  Papyrus.Event public currentEvent = Papyrus.Event.NoEvent;
  Papyrus.Event public lastFinishedEvent = Papyrus.Event.NoEvent;

  function PapyrusToken() HumanStandardToken(0, PPR_NAME, PPR_DECIMALS, PPR_SYMBOL) {}

  ///////////////////////////////////////////////
  // Function modifiers
  ///////////////////////////////////////////////

  modifier canSupply(uint256 _value) {
    // Double-checking make sense here to protect uint256 limits
    //require(_value > 0 && _value <= LIMIT_TOTAL && totalSupply + _value <= LIMIT_TOTAL);
    _;
  }

  modifier canTransfer() {
    //require(currentEvent == Papyrus.Event.NoEvent);
    _;
  }

  ///////////////////////////////////////////////
  // Events
  ///////////////////////////////////////////////

  event Bought(address buyer, uint256 amount);

  ///////////////////////////////////////////////
  // Functions
  ///////////////////////////////////////////////

  function buy() payable canSupply(msg.value) {
    balances[msg.sender] += msg.value;
    totalSupply += msg.value;
    Bought(msg.sender, msg.value);
  }
}
