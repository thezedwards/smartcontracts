pragma solidity ^0.4.8;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/token/StandardToken.sol";

/**
 * @title Base Papyrus token contract supports ability to mint tokens.
 */
contract MintableToken is StandardToken, Ownable {

  ///////////////////////////////////////////////
  // State variables and constructor
  ///////////////////////////////////////////////

  uint256 public mintingCap;

  // Mint tokens will be finished when all minter stages are finished
  bool public mintingFinished = false;

  address public minter = 0x0;

  ///////////////////////////////////////////////
  // Function modifiers
  ///////////////////////////////////////////////

  modifier onlyMiner() {
    require(msg.sender == minter);
    _;
  }

  modifier onlyOwnerOrMiner() {
    require(msg.sender == owner || msg.sender == minter);
    _;
  }

  modifier canMint(uint256 _value) {
    require(!mintingFinished);
    require(totalSupply.add(_value) <= mintingCap);
    _;
  }

  ///////////////////////////////////////////////
  // Events
  ///////////////////////////////////////////////

  event MinterRegistered(address indexed minter);
  event MinterUnregistered(address indexed minter);

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  ///////////////////////////////////////////////
  // Functions
  ///////////////////////////////////////////////

  /**
   * @dev Function to allow specified minter address to mint tokens.
   * @return True if the operation was successful.
   */
  function registerMinter(address _minter) onlyOwner canMint(0) external returns (bool) {
    require(minter == 0x0 && _minter != 0x0);
    minter = _minter;
    MinterRegistered(_minter);
    return true;
  }

  /**
   * @dev Function to disallow specified minter address to mint tokens.
   * @return True if the operation was successful.
   */
  function unregisterMinter(address _minter) onlyOwnerOrMiner external returns (bool) {
    require(minter != 0x0 && minter == _minter);
    minter = 0x0;
    MinterUnregistered(_minter);
    return true;
  }

  /**
   * @dev Function to mint tokens.
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwnerOrMiner canMint(_amount) returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner external returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}
