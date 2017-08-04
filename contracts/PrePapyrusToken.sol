pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/token/StandardToken.sol";

/// @title Pre-Papyrus token contract (PRP).
contract PrePapyrusToken is StandardToken, Ownable {

    // EVENTS

    event AccessGranted(address indexed to, bool access);
    event TokensBurned(address indexed from, uint256 amount);

    // PUBLIC FUNCTIONS

    function PrePapyrusToken(address[] _wallets, uint256[] _amounts) {
        require(_wallets.length == _amounts.length && _wallets.length > 0);
        uint i;
        uint256 sum = 0;
        for (i = 0; i < _wallets.length; ++i) {
            sum = sum.add(_amounts[i]);
        }
        require(sum == PRP_LIMIT);
        totalSupply = PRP_LIMIT;
        for (i = 0; i < _wallets.length; ++i) {
            balances[_wallets[i]] = _amounts[i];
        }
    }

    // If ether is sent to this address, send it back
    function() { revert(); }

    // Check sender address before transfer
    function transfer(address _to, uint _value) accessGranted returns (bool) {
        return super.transfer(_to, _value);
    }

    // Check sender address before approve
    function approve(address _spender, uint256 _value) accessGranted returns (bool) {
        return super.approve(_spender, _value);
    }

    // Check sender address before transfer
    function transferFrom(address _from, address _to, uint _value) accessGranted returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// @dev Grants access to specified address.
    /// @param _to Address for which access should be changed.
    /// @param _access Address receives access then true and loses when false.
    function grandAccess(address _to, bool _access) accessGranted {
        require(accessGrants[_to] != _access);
        accessGrants[_to] = _access;
        AccessGranted(_to, _access);
    }

    /// @dev Burns (destroys) tokens from specified address with specified amount.
    /// @param _from Address from which tokens should be burned.
    /// @param _amount Amount of tokens should be burned.
    function burn(address _from, uint256 _amount) accessGranted {
        require(balances[_from] >= _amount);
        balances[_from] = balances[_from].sub(_amount);
        burned = burned.add(_amount);
        TokensBurned(_from, _amount);
    }

    // MODIFIERS

    modifier accessGranted() {
        require(msg.sender == owner || accessGrants[msg.sender]);
        _;
    }

    // FIELDS

    // Standard fields used to describe the token
    string public name = "Pre-Papyrus Token";
    string public symbol = "PRP";
    string public version = "H0.1";
    uint8 public decimals = 18;

    // Set of addresses that can have access to transfering and burning tokens
    mapping (address => bool) public accessGrants;

    // Amount of burned (destroyed) tokens
    uint256 public burned;

    // Amount of supplied tokens is constant and equals to 50 000 000 PRP
    uint256 private constant PRP_LIMIT = 5 * 10**25;
}
