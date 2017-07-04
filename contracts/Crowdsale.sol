pragma solidity ^0.4.8;

import './zeppelin/token/MintableToken.sol';
import './zeppelin/math/SafeMath.sol';

/**
 * @title Crowdsale 
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end limits, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
contract Crowdsale {

  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // Start and end limits where investments are allowed (both inclusive)
  // These can be something like block numbers or timestamps
  uint256 public startLimit;
  uint256 public endLimit;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of raised money in wei
  uint256 public weiRaised;

  // Amount of minted token units
  uint256 public minted;

  // Limit of token units to solve
  uint256 public cap;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(uint256 _startLimit, uint256 _endLimit, uint256 _rate, address _wallet) {
    //require(_endLimit >= getLimitationValue());
    //require(_endLimit >= _startLimit);
    //require(_rate > 0);
    //require(_wallet != 0x0);

    startLimit = _startLimit;
    endLimit = _endLimit;
    rate = _rate;
    wallet = _wallet;
  }

  // Returns value should be used to compare with start/end limits. 
  // Override this method to have relevant value like block index or timestamp.
  function getLimitationValue() internal constant returns (uint256) { throw; }

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

    uint256 weiAmount = msg.value;
    uint256 updatedWeiRaised = weiRaised.add(weiAmount);

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    require(validPurchase(tokens));

    uint256 updatedMinted = minted.add(tokens);

    // update state
    weiRaised = updatedWeiRaised;
    minted = updatedMinted;

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // @return true if the transaction can buy tokens
  function validPurchase(uint256 _tokens) internal constant returns (bool) {
    uint256 current = getLimitationValue();
    bool withinCap = minted.add(_tokens) <= cap; // TODO
    bool withinPeriod = current >= startLimit && current <= endLimit;
    bool nonZeroPurchase = msg.value != 0;
    return withinCap && withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = minted >= cap;
    bool limitReached = getLimitationValue() > endLimit;
    return capReached || limitReached;
  }

}

contract CrowdsaleBlockNumberLimit is Crowdsale {
  
  function CrowdsaleBlockNumberLimit(address _tokenAddress, uint256 _startLimit, uint256 _endLimit, uint256 _rate, address _wallet)
    Crowdsale(_startLimit, _endLimit, _rate, _wallet) {
      require(_tokenAddress != 0x0);
      //token = MintableToken(_tokenAddress);
    }
  
  function getLimitationValue() internal constant returns (uint256) { return block.number; }

}

contract CrowdsaleBlockTimeLimit is Crowdsale {
  
  function CrowdsaleBlockTimeLimit(address _tokenAddress, uint256 _startLimit, uint256 _endLimit, uint256 _rate, address _wallet)
    Crowdsale(_startLimit, _endLimit, _rate, _wallet) {
      require(_tokenAddress != 0x0);
      token = MintableToken(_tokenAddress);
    }
  
  function getLimitationValue() internal constant returns (uint256) { return block.timestamp; }

}