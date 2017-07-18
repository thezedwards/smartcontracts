pragma solidity ^0.4.8;


/// @title Abstract token contract - Functions to be implemented by token contracts.
contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);

    // This is not an abstract function, because solc won't recognize generated getter functions for public variables as functions.
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/// @title Presale dutch auction contract - distribution of Papyrus tokens using an auction.
/// @author Igor Sokolov - <wardencliffe.sis@gmail.com>
/// Based on dutch auction contract from Stefan George
contract PapyrusPresale {

    /*
     *  Events
     */

    event BidSubmission(address indexed sender, uint256 amount);

    /*
     *  Constants and enums
     */

    uint256 constant public WAITING_PERIOD = 7 days;

    enum Stage {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStartedPrivate,
        AuctionStartedPublic,
        AuctionEnded,
        ClaimingStarted
    }

    /*
     *  Storage
     */

    // Papyrus token should be sold during auction
    Token public papyrusToken;

    // Amount of Papyrus tokens expected to be sold during auction
    uint256 public papyrusTokensToSell;

    // Address of the contract creator
    address public owner;

    // Address of multisig wallet used to hold received ether
    address public wallet;

    // Auction ceiling in weis
    uint256 public ceiling;

    // Auction price factor
    uint256 public priceFactor;

    // Index of block from which auction was started
    uint256 public startBlock;

    // Timestamp when auction was ended
    uint256 public endTime;

    // Amount of received weis at private presale stage
    uint256 public privateReceived;

    // Amount of total received weis
    uint256 public totalReceived;

    // Final token price used when auction is ended
    uint256 public finalPrice;

    // Addresses allowed to participate in private presale
    mapping (address => uint256) public privateParticipants;

    // Received bids
    mapping (address => uint256) public bids;

    // Current stage of the auction
    Stage public stage;

    /*
     *  Modifiers
     */

    modifier atStage(Stage _stage) {
        require(stage == _stage);
        _;
    }

    modifier isAuctionStarted() {
        require(stage == Stage.AuctionStartedPrivate || stage == Stage.AuctionStartedPublic);
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isWallet() {
        require(msg.sender == wallet);
        _;
    }

    modifier isValidPayload() {
        require(msg.data.length == 4 || msg.data.length == 36);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stage.AuctionStartedPrivate && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stage.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stage.ClaimingStarted;
        _;
    }

    /*
     *  Public functions
     */

    /// @dev Contract constructor function sets owner.
    /// @param _wallet Papyrus wallet.
    /// @param _ceiling Auction ceiling.
    /// @param _priceFactor Auction start price factor.
    function PapyrusPresale(address _wallet, uint256 _ceiling, uint256 _priceFactor) public {
        require(_wallet != 0x0 && _ceiling != 0 && _priceFactor != 0);
        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stage.AuctionDeployed;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _papyrusToken Papyrus token address.
    /// @param _papyrusTokensToSell Amount of Papyrus tokens expected to be sold during auction.
    function setup(address _papyrusToken, uint256 _papyrusTokensToSell)
        public
        isOwner
        atStage(Stage.AuctionDeployed)
    {
        require(_papyrusToken != 0x0 && _papyrusTokensToSell != 0);
        papyrusToken = Token(_papyrusToken);
        papyrusTokensToSell = _papyrusTokensToSell;
        require(papyrusToken.balanceOf(this) == papyrusTokensToSell);
        stage = Stage.AuctionSetUp;
    }

    /// @dev Changes auction ceiling and start price factor before auction is started.
    /// @param _ceiling Updated auction ceiling.
    /// @param _priceFactor Updated auction start price factor.
    function changeSettings(uint256 _ceiling, uint256 _priceFactor)
        public
        isWallet
        atStage(Stage.AuctionSetUp)
    {
        ceiling = _ceiling;
        priceFactor = _priceFactor;
    }

    /// @dev Allows specified address to participate in private stage of the auction.
    /// @param _participant Address of the participant of private stage of the auction.
    /// @param _amount Amount of weis allowed to bid for the participant.
    function allowPrivateParticipant(address _participant, uint256 _amount)
        public
        isWallet
        atStage(Stage.AuctionSetUp)
    {
        require(_participant != 0x0);
        privateParticipants[_participant] = _amount;
    }

    /// @dev Starts private stage of auction and sets startBlock.
    function startPrivateAuction()
        public
        isWallet
        atStage(Stage.AuctionSetUp)
    {
        stage = Stage.AuctionStartedPrivate;
        startBlock = block.number;
    }

    /// @dev Starts public stage of auction and sets startBlock.
    function startPublicAuction()
        public
        isWallet
        atStage(Stage.AuctionStartedPrivate)
    {
        stage = Stage.AuctionStartedPublic;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint256)
    {
        if (stage == Stage.AuctionEnded || stage == Stage.ClaimingStarted)
            return finalPrice;
        return calcTokenPrice();
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stage)
    {
        return stage;
    }

    /// @dev Allows to send a bid to the auction.
    /// @param receiver Bid will be assigned to this address if set.
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        isAuctionStarted
        returns (uint256 amount)
    {
        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set.
        if (receiver == 0x0)
            receiver = msg.sender;
        // TODO: Should we limit bids from private participants?
        require(stage == Stage.AuctionStartedPublic || privateParticipants[receiver] != 0);
        amount = msg.value;
        // Prevent that more than specified amount of tokens are sold. Only relevant if cap not reached.
        uint256 maxWei = (papyrusTokensToSell / 10**18) * calcTokenPrice() - totalReceived;
        uint256 maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;
        // Only invest maximum possible amount.
        if (amount > maxWei) {
            amount = maxWei;
            // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly.
            if (!receiver.send(msg.value - amount)) {
                // Sending failed
                throw;
            }
        }
        // Forward funding to ether wallet
        if (amount == 0 || !wallet.send(amount)) {
            // No amount sent or sending failed
            throw;
        }
        bids[receiver] += amount;
        if (stage == Stage.AuctionStartedPrivate) {
            // Hold amount of received weis separately for private presale stage
            privateReceived += amount;
        }
        totalReceived += amount;
        if (maxWei == amount) {
            // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered.
            finalizeAuction();
        }
        BidSubmission(receiver, amount);
    }

    /// @dev Claims tokens for bidder after auction.
    /// @param receiver Tokens will be assigned to this address if set.
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stage.ClaimingStarted)
    {
        if (receiver == 0x0)
            receiver = msg.sender;
        uint256 tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        papyrusToken.transfer(receiver, tokenCount);
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice() constant public returns (uint256) {
        return totalReceived * 10**18 / papyrusTokensToSell + 1;
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice() constant public returns (uint256) {
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }

    /*
     *  Private functions
     */

    function finalizeAuction() private {
        stage = Stage.AuctionEnded;
        finalPrice = totalReceived == ceiling ? calcTokenPrice() : calcStopPrice();
        uint256 papyrusTokensSold = totalReceived * 10**18 / finalPrice;
        if (papyrusTokensSold < papyrusTokensToSell) {
            // Auction contract transfers all unsold tokens to Papyrus inventory multisig
            // TODO: Currently this will not work because PapyrusToken will not allow to make such transfer at presale
            //papyrusToken.transfer(wallet, papyrusTokensToSell - papyrusTokensSold);
        }
        endTime = now;
    }

}
