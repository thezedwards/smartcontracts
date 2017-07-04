var Papyrus = artifacts.require("./Papyrus.sol");
var PapyrusToken = artifacts.require("./PapyrusToken.sol");

var account_names = ["Alice", "Bobby", "Carl", "Daniel", "Eric"];
var account_ids = [0, 0, 0, 0, 0];

var printAccounts = function() {
    console.log("There are " + account_ids.length + " nodes in the network:");
    for (var i = 0; i < account_ids.length && i < account_names.length; ++i) {
        var balance = web3.eth.getBalance(account_ids[i]).valueOf();
        var balanceEther = balance / 1000000000000000000;
        console.log(" " + i + ". " + account_names[i] + "\t: " + account_ids[i] + " has " + balanceEther.toFixed(3) + " ether");
    }
    console.log();
};

var canBuyPPR = function(fromIndex, amount) {
    return PapyrusToken.deployed().then(function(instance) {
        var papyrusPrice = web3.toWei(amount, 'ether');
        var initialBalance = web3.eth.getBalance(account_ids[fromIndex]).valueOf();
        return instance.totalSupply.call().then(function(initialTotalSupply) {
            return instance.buy({ from: account_ids[fromIndex], value: papyrusPrice }).then(function() {
                var newBalance = web3.eth.getBalance(account_ids[fromIndex]).valueOf();
                var difference = initialBalance - newBalance;
                assert(difference > papyrusPrice);
                return instance.totalSupply.call().then(function(totalSupply) {
                    assert.equal(totalSupply.valueOf(), initialTotalSupply.plus(papyrusPrice), "Total supply should be changed on difference");
                });
            });
        });
    });
};

var cannotBuyPPR = function(fromIndex, amount) {
    return PapyrusToken.deployed().then(function(instance) {
        var papyrusPrice = web3.toWei(amount, 'ether');
        var initialBalance = web3.eth.getBalance(account_ids[fromIndex]).valueOf();
        return instance.totalSupply.call().then(function(initialTotalSupply) {
            return instance.buy({ from: account_ids[fromIndex], value: papyrusPrice }).then(function() {
                var newBalance = web3.eth.getBalance(account_ids[fromIndex]).valueOf();
                assert.equal(newBalance, initialBalance, "Difference should be zero");
                return instance.totalSupply.call().then(function(totalSupply) {
                    assert.equal(totalSupply.valueOf(), initialTotalSupply.valueOf(), "Total supply should not be changed");
                });
            });
        });
    });
};

contract('PapyrusToken', function(accounts) {

    account_ids = accounts;

    printAccounts();

    it("Should have owner", function() {
        return PapyrusToken.deployed().then(function(instance) {
            return instance.owner.call().then(function(owner) {
                assert(owner.length > 0);
                console.log("    Owner of the contract: " + owner);
            });
        });
    });

    it("Should have initial event states", function() {
        return PapyrusToken.deployed().then(function(instance) {
            return instance.currentEvent.call().then(function(event) {
                assert(event == 0); // 0 == Papyrus.Event.NoEvent
                console.log("    Current Papyrus event: " + event);
                return instance.lastFinishedEvent.call();
            }).then(function(event) {
                assert(event == 0); // 0 == Papyrus.Event.NoEvent
                console.log("    Last finished Papyrus event: " + event);
            });
        });
    });

    it("Should not be to able to buy ", function() { return cannotBuyPPR(0, 1.1); });
});