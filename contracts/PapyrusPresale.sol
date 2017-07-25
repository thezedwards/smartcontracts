pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/token/BasicToken.sol";

/// @title Presale dutch auction contract - distribution of Papyrus tokens using an auction.
/// Based on dutch auction contract from Stefan George (Gnosis).
contract PapyrusPresale is Ownable {
    using SafeMath for uint256;

    // TYPES

    enum Stage {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStartedPrivate,
        AuctionStartedPublic,
        AuctionFinishing,
        AuctionFinished,
        ClaimingStarted
    }

    struct PrivateBid {
        address bidder;
        uint256 price;
        uint256 allowed;  // amount of weis allowed to bid
        uint256 accepted; // amount of weis accepted as bid
    }

    // EVENTS

    event BidSubmission(address indexed sender, uint256 amount);

    // PUBLIC FUNCTIONS

    /// @dev Contract constructor function sets owner.
    /// @param _wallet Papyrus wallet.
    /// @param _ceiling Auction ceiling.
    /// @param _priceFactor Auction start price factor.
    /// @param _auctionPeriod Period of time when auction will be available after stop price is achieved.
    /// @param _delayPeriod Period of time which claiming tokens will be delayed after auction is finished.
    function PapyrusPresale(address _wallet, uint256 _ceiling, uint256 _priceFactor, uint256 _auctionPeriod, uint256 _delayPeriod) public {
        require(_wallet != address(0) && _ceiling != 0 && _priceFactor != 0 && _auctionPeriod != 0);
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        auctionPeriod = _auctionPeriod;
        delayPeriod = _delayPeriod;
        stage = Stage.AuctionDeployed;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _papyrusToken Papyrus token address.
    /// @param _tokensToSell Amount of tokens expected to be sold during auction.
    /// @param _bonusPercent Percent of bonus tokens we share with private participants of the auction.
    /// @param _minPrivateBid Minimal amount of weis for private participants of the auction.
    /// @param _minPublicBid Minimal amount of weis for public participants of the auction.
    function setup(address _papyrusToken, uint256 _tokensToSell, uint8 _bonusPercent, uint256 _minPrivateBid, uint256 _minPublicBid)
        public
        onlyOwner
        atStage(Stage.AuctionDeployed)
    {
        require(_papyrusToken != address(0) && _tokensToSell != 0 && _minPrivateBid != 0 && _minPublicBid != 0);
        papyrusToken = BasicToken(_papyrusToken);
        tokensToSell = _tokensToSell;
        bonusPercent = _bonusPercent;
        minPrivateBid = _minPrivateBid;
        minPublicBid = _minPublicBid;
        uint256 expectedBalance = tokensToSell.mul(100 + bonusPercent).div(100);
        require(papyrusToken.balanceOf(this) == expectedBalance);
        stage = Stage.AuctionSetUp;
    }

    /// @dev Changes auction ceiling and start price factor before auction is started.
    /// @param _ceiling Updated auction ceiling.
    /// @param _priceFactor Updated auction start price factor.
    /// @param _auctionPeriod Period of time when auction will be available after stop price is achieved.
    /// @param _delayPeriod Period of time which claiming tokens will be delayed after auction is finished.
    function changeSettings(uint256 _ceiling, uint256 _priceFactor, uint256 _auctionPeriod, uint256 _delayPeriod)
        public
        onlyOwner
        atStage(Stage.AuctionSetUp)
    {
        require(_ceiling != 0 && _priceFactor != 0 && _auctionPeriod != 0);
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        auctionPeriod = _auctionPeriod;
        delayPeriod = _delayPeriod;
    }

    /// @dev Allows specified address to participate in private stage of the auction.
    /// @param _participant Address of the participant of private stage of the auction.
    /// @param _amount Amount of weis allowed to bid for the participant.
    function allowPrivateParticipant(address _participant, uint256 _amount)
        public
        onlyOwner
        atStage(Stage.AuctionSetUp)
    {
        require(_participant != address(0));
        // _amount can be zero for cases when we want to disallow private participant
        privateParticipants[_participant] = _amount;
    }

    /// @dev Starts private stage of auction.
    function startPrivateAuction()
        public
        onlyOwner
        atStage(Stage.AuctionSetUp)
    {
        stage = Stage.AuctionStartedPrivate;
    }

    /// @dev Starts public stage of auction and sets startBlock.
    function startPublicAuction()
        public
        onlyOwner
        atStage(Stage.AuctionStartedPrivate)
    {
        stage = Stage.AuctionStartedPublic;
        startBlock = block.number;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint256)
    {
        return stage == Stage.AuctionFinishing || stage == Stage.AuctionFinished || stage == Stage.ClaimingStarted ? finalPrice : calcTokenPrice();
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
    /// @param price Maximum price for selling token used only for private participants on private stage of the auction.
    function bid(address receiver, uint256 price)
        public
        payable
        isValidPayload
        timedTransitions
        isAuctionStarted
        returns (uint256 amount)
    {
        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set
        if (receiver == address(0))
            receiver = msg.sender;
        uint i;
        amount = msg.value;
        // Check some conditions depending on stage of the auction
        if (stage == Stage.AuctionStartedPrivate) {
            uint256 amountAllowed = privateParticipants[receiver];
            require(amountAllowed != 0 && amount >= minPrivateBid && amount <= amountAllowed && price != 0);
            addPrivateBid(receiver, price, amount);
            if (price >= calcTokenPrice()) {
                // We can just perform the bid since requested price is big enough
                amount = performBid(receiver, amount);
                for (i = 0; i < privateBids.length; ++i) {
                    if (privateBids[i].bidder == receiver) {
                        privateBids[i].accepted = amount;
                        break;
                    }
                }
            }
        } else if (stage == Stage.AuctionStartedPublic) {
            require(amount >= minPublicBid);
            // Before we perform just received bid check on private bids and perform some of them if necessary
            for (i = 0; i < privateBids.length; ++i) {
                uint256 tokenPrice = calcTokenPrice();
                var privateBid = privateBids[i];
                if (privateBid.accepted == 0 && privateBid.price >= tokenPrice) {
                    privateBids[i].accepted = performBid(privateBid.bidder, privateBid.allowed);
                } else if (privateBid.price < tokenPrice) {
                    break;
                }
            }
            // Then perform just received bid
            amount = performBid(receiver, amount);
        } else {
            revert();
        }
    }

    /// @dev Declines bid for specified bidder.
    /// @param bidder Address of bidder whose bid should be declined.
    function declineBid(address bidder)
        public
        onlyOwner
        timedTransitions
        atStage(Stage.AuctionFinished)
    {
        // TODO: Check this carefully for cases when the same address used in both private and public states of the auction
        if (privateParticipants[bidder] != 0) {
            for (uint i = 0; i < privateBids.length; ++i) {
                if (privateBids[i].bidder == bidder) {
                    declinedBids[bidder] = privateBids[i].allowed;
                    privateBids[i].accepted = 0;
                    break;
                }
            }
        } else {
            declinedBids[bidder] = bids[bidder];
        }
        bids[bidder] = 0;
    }

    /// @dev Claims ether for private bidder after auction.
    /// @param receiver Ether will be sent to this address if set.
    function claimEther(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stage.ClaimingStarted)
    {
        // TODO: Check this carefully for cases when the same address used in both private and public states of the auction
        uint256 amount = 0;
        if (declinedBids[receiver] > 0) {
            amount = declinedBids[receiver];
        } else if (privateParticipants[receiver] > 0) {
            for (uint i = 0; i < privateBids.length; ++i) {
                if (privateBids[i].bidder == receiver) {
                    amount = privateBids[i].allowed.sub(privateBids[i].accepted);
                    break;
                }
            }
        }
        if (amount > 0) {
            // Send change back to receiver address
            if (!receiver.send(amount)) {
                // Sending failed
                revert();
            }
        }
    }

    /// @dev Claims tokens for bidder after auction.
    /// @param receiver Tokens will be assigned to this address if set.
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stage.ClaimingStarted)
    {
        // TODO: Check this carefully for cases when the same address used in both private and public states of the auction
        if (receiver == address(0))
            receiver = msg.sender;
        // Forward funding to ether wallet
        if (!wallet.send(bids[receiver])) {
            // Sending failed
            revert();
        }
        uint256 tokenCount = bids[receiver].mul(E18).div(finalPrice);
        // Add bonus to private participant if necessary
        if (privateParticipants[receiver] != 0) {
            for (uint i = 0; i < privateBids.length; ++i) {
                var privateBid = privateBids[i];
                if (privateBid.bidder == receiver) {
                    tokenCount = tokenCount.add(privateBid.accepted.mul(bonusPercent).div(100));
                    break;
                }
            }
        }
        bids[receiver] = 0;
        papyrusToken.transfer(receiver, tokenCount);
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice() constant public returns (uint256) {
        return totalReceived.sub(privateReceived).mul(E18).div(tokensToSell).add(1);
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice() constant public returns (uint256) {
        uint256 denominator = (startBlock != 0 ? block.number - startBlock : 0) + 7500;
        return priceFactor.mul(E18).div(denominator).add(1);
    }

    // PRIVATE FUNCTIONS

    function addPrivateBid(address bidder, uint256 price, uint256 amount) private {
        // Create private bid
        var privateBid = PrivateBid(bidder, price, amount, 0);
        // Add it to the end of private bids array for start
        privateBids.push(privateBid);
        // Then sort private bids array so it is suitable for further usage
        uint i;
        uint indexToInsert = privateBids.length;
        for (i = 0; i < privateBids.length; ++i) {
            if (privateBids[i].price < privateBid.price) {
                indexToInsert = i;
                break;
            } else if (privateBids[i].price == privateBid.price && privateBids[i].allowed < privateBid.allowed) {
                indexToInsert = i;
                break;
            }
        }
        if (indexToInsert < privateBids.length) {
            for (i = privateBids.length - 1; i > indexToInsert; --i) {
                privateBids[i] = privateBids[i - 1];
            }
            privateBids[indexToInsert] = privateBid;
        }
    }

    function performBid(address receiver, uint256 value) private returns (uint256 amount) {
        if (stage != Stage.AuctionStartedPrivate && stage != Stage.AuctionStartedPublic) {
            amount = 0;
            return;
        }
        amount = value;
        // Prevent that more than specified amount of tokens are sold. Only relevant if cap not reached.
        uint256 maxWei = tokensToSell.div(E18).mul(calcTokenPrice()).sub(totalReceived);
        uint256 maxWeiBasedOnTotalReceived = ceiling.sub(totalReceived);
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;
        // Only invest maximum possible amount.
        if (amount > maxWei) {
            amount = maxWei;
            // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly.
            if (!receiver.send(value.sub(amount))) {
                // Sending failed
                revert();
            }
        }
        if (amount == 0) {
            return;
        }
        bids[receiver] = bids[receiver].add(amount);
        if (stage == Stage.AuctionStartedPrivate) {
            // Hold amount of received weis separately for private presale stage
            privateReceived = privateReceived.add(amount);
        }
        totalReceived = totalReceived.add(amount);
        if (maxWei == amount) {
            // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered.
            finalizeAuction();
        }
        BidSubmission(receiver, amount);
    }

    function finalizeAuction() private {
        stage = Stage.AuctionFinishing;
        finalPrice = totalReceived == ceiling ? calcTokenPrice() : calcStopPrice();
        uint256 papyrusTokensSold = totalReceived.mul(E18).div(finalPrice);
        if (papyrusTokensSold < tokensToSell) {
            // Auction contract transfers all unsold tokens to Papyrus inventory multisig
            // TODO: Also need to add remaining bonus tokens to this transfer
            papyrusToken.transfer(wallet, tokensToSell - papyrusTokensSold);
        }
        finishingTime = now;
    }

    // MODIFIERS

    modifier atStage(Stage _stage) {
        require(stage == _stage);
        _;
    }

    modifier isAuctionStarted() {
        require(stage == Stage.AuctionStartedPrivate || stage == Stage.AuctionStartedPublic);
        _;
    }

    modifier isValidPayload() {
        // TODO: Why is this necessary?
        //require(msg.data.length == 4 || msg.data.length == 36);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stage.AuctionStartedPrivate && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stage.AuctionFinishing && now > finishingTime + auctionPeriod)
            stage = Stage.AuctionFinished;
        if (stage == Stage.AuctionFinished && now > finishedTime + delayPeriod)
            stage = Stage.ClaimingStarted;
        _;
    }

    // FIELDS

    // Papyrus token should be sold during auction
    BasicToken public papyrusToken;

    // Amount of tokens expected to be sold during auction
    uint256 public tokensToSell;

    // Percent of bonus tokens we share with private participants of the auction
    uint256 public bonusPercent;

    // Minimal amount of weis for private participants of the auction
    uint256 public minPrivateBid;

    // Minimal amount of weis for public participants of the auction
    uint256 public minPublicBid;

    // Address of multisig wallet used to hold received ether
    address public wallet;

    // Auction ceiling in weis
    uint256 public ceiling;

    // Auction price factor
    uint256 public priceFactor;

    // Period of time which auction will be available after stop price is achieved
    uint256 public auctionPeriod;

    // Period of time which claiming tokens will be delayed after auction is finished
    uint256 public delayPeriod;

    // Index of block from which auction was started
    uint256 public startBlock;

    // Timestamp when auction starting finishing (stop price achieved)
    uint256 public finishingTime;

    // Timestamp when auction finished (starting waiting before claiming tokens allowed)
    uint256 public finishedTime;

    // Amount of received weis at private presale stage
    uint256 public privateReceived;

    // Amount of total received weis
    uint256 public totalReceived;

    // Final token price used when auction is ended
    uint256 public finalPrice;

    // Addresses allowed to participate in private presale
    mapping (address => uint256) public privateParticipants;

    // Array of bids received from private participants
    PrivateBid[] public privateBids;

    // Received bids
    mapping (address => uint256) public bids;

    // Declined bids
    mapping (address => uint256) public declinedBids;

    // Current stage of the auction
    Stage public stage;

    // Some pre-calculated constant values
    uint256 constant private E18 = 10**18;
}
