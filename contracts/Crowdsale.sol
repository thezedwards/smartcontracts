pragma solidity ^0.4.8;

import './MintableToken.sol';

/**
 * @title Crowdsale 
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end blocks, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
contract Crowdsale {

  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // Address where funds are collected
  address public wallet;

  // Start and end blocks where investments are allowed (both inclusive)
  uint256 public startLimit;
  uint256 public endLimit;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Limit of token units to solve
  uint256 public cap;

  // Amount of raised money (as weis)
  uint256 public raised;

  // Amount of minted token units
  uint256 public minted;

  event LogMessage(string message, uint256 value);

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(MintableToken _token, address _wallet, uint256 _startLimit, uint256 _endLimit, uint256 _rate, uint256 _cap) {
    require(_wallet != 0x0);
    require(block.number <= _startLimit);
    require(_startLimit <= _endLimit);
    require(_rate > 0);
    token = _token;
    wallet = _wallet;
    startLimit = _startLimit;
    endLimit = _endLimit;
    rate = _rate;
    cap = _cap;
  }

  // Send ether to the fund collection wallet.
  // Override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // Fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // Low level token purchase function
  function buyTokens(address beneficiary) payable {

    require(beneficiary != 0x0);

    uint256 amount = msg.value;
    uint256 raisedNew = raised.add(amount);

    // calculate token amount to be created
    uint256 tokens = amount.mul(rate);

    require(validPurchase(tokens));

    uint256 mintedNew = minted.add(tokens);

    // update state
    raised = raisedNew;
    minted = mintedNew;

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, amount, tokens);

    forwardFunds();
  }

  // @return true if the transaction can buy tokens
  function validPurchase(uint256 _tokens) internal constant returns (bool) {
    uint256 blockNumber = block.number;
    bool withinCap = minted.add(_tokens) <= cap; // TODO
    bool withinPeriod = blockNumber >= startLimit && blockNumber <= endLimit;
    bool nonZeroPurchase = msg.value != 0;
    return withinCap && withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = minted >= cap;
    bool limitReached = block.number > endLimit;
    return capReached || limitReached;
  }

}
