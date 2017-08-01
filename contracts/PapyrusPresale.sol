pragma solidity ^0.4.11;

import "./PapyrusAuction.sol";

/// @title Papyrus presale auction contract - distribution of Papyrus tokens using an auction.
contract PapyrusPresale is PapyrusAuction {
    /// @dev Contract constructor function.
    /// @param _wallet Papyrus multisig wallet address for storing ETH after claiming.
    /// @param _ceiling Auction ceiling.
    /// @param _priceEther Current price ETH/USD.
    /// @param _priceFactor Auction start price factor.
    /// @param _auctionPeriod Period of time when auction will be available after stop price is achieved in seconds.
    /// @param _auctionPrivateStart Index of block from which private auction should be started.
    /// @param _auctionPublicStart Index of block from which public auction should be started.
    /// @param _auctionClaimingStart Index of block from which claiming should be started.
    function PapyrusPresale(
        address _wallet,
        uint256 _ceiling,
        uint256 _priceEther,
        uint256 _priceFactor,
        uint256 _auctionPeriod,
        uint256 _auctionPrivateStart,
        uint256 _auctionPublicStart,
        uint256 _auctionClaimingStart
    )
        PapyrusAuction(_wallet, _ceiling, _priceEther, _priceFactor, _auctionPeriod, _auctionPrivateStart, _auctionPublicStart, _auctionClaimingStart)
    {
    }
}
