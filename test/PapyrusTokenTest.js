var PapyrusToken = artifacts.require("./PapyrusToken.sol");
//var CrowdsaleBlockNumberLimitAbi = artifacts.require("./bin/contracts/CrowdsaleBlockNumberLimit.abi");
var CrowdsaleBlockNumberLimitAbi = [{ "constant": true, "inputs": [], "name": "startLimit", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "rate", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "cap", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "weiRaised", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "minted", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "wallet", "outputs": [{ "name": "", "type": "address" }], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "endLimit", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "type": "function" }, { "constant": false, "inputs": [{ "name": "beneficiary", "type": "address" }], "name": "buyTokens", "outputs": [], "payable": true, "type": "function" }, { "constant": true, "inputs": [], "name": "hasEnded", "outputs": [{ "name": "", "type": "bool" }], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "token", "outputs": [{ "name": "", "type": "address" }], "payable": false, "type": "function" }, { "inputs": [{ "name": "_tokenAddress", "type": "address" }, { "name": "_startLimit", "type": "uint256" }, { "name": "_endLimit", "type": "uint256" }, { "name": "_rate", "type": "uint256" }, { "name": "_wallet", "type": "address" }], "payable": false, "type": "constructor" }, { "payable": true, "type": "fallback" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "purchaser", "type": "address" }, { "indexed": true, "name": "beneficiary", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" }, { "indexed": false, "name": "amount", "type": "uint256" }], "name": "TokenPurchase", "type": "event" }];

var accountNames = ["Alice", "Bobby", "Carl", "Daniel", "Eric"];
var accountIds = [0, 0, 0, 0, 0];

var printAccounts = function() {
    console.log("There are " + accountIds.length + " nodes in the network:");
    for (var i = 0; i < accountIds.length && i < accountNames.length; ++i) {
        var balance = web3.eth.getBalance(accountIds[i]).valueOf();
        var balanceEther = balance / 1000000000000000000;
        console.log(" " + i + ". " + accountNames[i] + "\t: " + accountIds[i] + " has " + balanceEther.toFixed(3) + " ether");
    }
    console.log();
};

var canBuyPPR = function(fromIndex, amount) {
    return PapyrusToken.deployed().then(function(instance) {
        var papyrusPrice = web3.toWei(amount, 'ether');
        var initialBalance = web3.eth.getBalance(accountIds[fromIndex]).valueOf();
        return instance.totalSupply.call().then(function(initialTotalSupply) {
            return instance.buy({ from: accountIds[fromIndex], value: papyrusPrice }).then(function() {
                var newBalance = web3.eth.getBalance(accountIds[fromIndex]).valueOf();
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
        var initialBalance = web3.eth.getBalance(accountIds[fromIndex]).valueOf();
        return instance.totalSupply.call().then(function(initialTotalSupply) {
            return instance.buyTokens({ from: accountIds[fromIndex], value: papyrusPrice }).then(function() {
                var newBalance = web3.eth.getBalance(accountIds[fromIndex]).valueOf();
                assert.equal(newBalance, initialBalance, "Difference should be zero");
                return instance.totalSupply.call().then(function(totalSupply) {
                    assert.equal(totalSupply.valueOf(), initialTotalSupply.valueOf(), "Total supply should not be changed");
                });
            });
        });
    });
};

contract('PapyrusToken', function(accounts) {

    accountIds = accounts;

    printAccounts();

    it("Should have owner", function() {
        return PapyrusToken.deployed().then(function(instance) {
            return instance.owner.call().then(function(owner) {
                assert(owner.length > 0);
                console.log("    Owner of the contract: " + owner);
            });
        });
    });

    it("Should be able to create crowdsale contract", function() {
        return PapyrusToken.deployed().then(function(instance) {
            var CrowdsaleBlockNumberLimit = web3.eth.contract(CrowdsaleBlockNumberLimitAbi);
            var crowdsale = CrowdsaleBlockNumberLimit.new(instance.contract.address, 350, 360, 1, accountIds[0], { from: accountIds[0], gas: 3000000 });
            console.log(crowdsale);
        });
    });

    it("Should not be able to buy ", function() { return cannotBuyPPR(0, 1.1); });
});