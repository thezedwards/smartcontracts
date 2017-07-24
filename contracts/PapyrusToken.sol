pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/token/StandardToken.sol";

/// @title Papyrus token contract (PPR).
contract PapyrusToken is StandardToken, Ownable {

    // EVENTS

    event TransferableChanged(bool transferable);
    event AuctionStarted(address indexed auction);
    event AuctionFinished(address indexed auction);

    // PUBLIC FUNCTIONS

    function PapyrusToken() {
        totalSupply = PPR_LIMIT;
        balances[msg.sender] = PPR_LIMIT;
    }

    // If ether is sent to this address, send it back
    function() { revert(); }

    // Check transferable state before transfer
    function transfer(address _to, uint _value) canTransfer returns (bool) {
        return super.transfer(_to, _value);
    }

    // Check transferable state before approve
    function approve(address _spender, uint256 _value) canTransfer returns (bool) {
        return super.approve(_spender, _value);
    }

    // Check transferable state before transfer
    function transferFrom(address _from, address _to, uint _value) canTransfer returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// @dev Called by the owner to change ability to transfer tokens by users.
    function setTransferable(bool _transferable) onlyOwner {
        require(transferable != _transferable);
        transferable = _transferable;
        TransferableChanged(transferable);
    }

    /// @dev Called by the owner to specify auction address so it is possible to transfer PPR while it is not transferable.
    function setAuctionAddress(address _auction) onlyOwner {
        require(auction != _auction);
        if (auction != address(0))
            AuctionFinished(auction);
        auction = _auction;
        if (auction != address(0))
            AuctionStarted(auction);
    }

    // MODIFIERS

    modifier canTransfer() {
        require(transferable || msg.sender == owner || msg.sender == auction);
        _;
    }

    // FIELDS

    // Standard fields used to describe the token
    string public name = "Papyrus Token";
    string public symbol = "PPR";
    string public version = "H0.1";
    uint8 public decimals = 18;

    // At the start of the token existence it is not transferable
    bool public transferable = false;

    // To allow perform PPR transactions during auctions we use this address
    address public auction;

    // Amount of supplied tokens is constant and equals to 1 000 000 000 PPR
    uint256 private constant PPR_LIMIT = 10**27;
}
