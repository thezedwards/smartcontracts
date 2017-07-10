/*jshint esversion: 6 */

var PapyrusToken = artifacts.require("PapyrusToken");
var Crowdsale = artifacts.require("CrowdsaleBlockNumberLimit");

var accountNames = ["Alice", "Eric", "Bobby", "Carl", "Daniel"];
var accountDescriptions = [
    "Alice is very important account. Alice has access to Papyrus Token. Alice is only miner also.",
    "Eric is account that accumulate all pre-sale crowdsale sales (ether at wallet).",
    "Bobby is account that accumulate all crowdsale sales (ether at wallet).",
    "Carl is a person who is interested in our project.",
    "Daniel is a whale of Ad and what to support our project dramatically."
];
var accountIds = web3.eth.accounts;

var accountMinerId = accountIds[0];
var accountPreSaleWalletId = accountIds[1];
var accountSaleWalletId = accountIds[2];

const MINER_ETHER_MIN = 100;
const MINER_ETHER_MIN_WEI = web3.toBigNumber(web3.toWei(MINER_ETHER_MIN, "ether"));
const ACCOUNT_ETHER_MIN = 10;
const ACCOUNT_ETHER_MIN_WEI = web3.toBigNumber(web3.toWei(ACCOUNT_ETHER_MIN, "ether"));

var tokenContract = null;
var crowdsaleContract = null;

var events = [];

function registerEvent(event, callback) {
    event.watch(function(error, result) {
        callback(error, result);
    });
    events.push(event);
}

export function waitMiner() {
    while (web3.toBigNumber(web3.eth.getBalance(accountMinerId)).lessThan(MINER_ETHER_MIN_WEI)) {}
}

export function shareEther() {
    var checkDonationAccount = function(resolve, reject, index) {
        var accountId = accountIds[index];
        var accountBalance = web3.toBigNumber(web3.eth.getBalance(accountId));
        if (accountBalance.lessThan(ACCOUNT_ETHER_MIN_WEI)) {
            var donateAmount = ACCOUNT_ETHER_MIN_WEI.minus(accountBalance);
            console.log("    Donating " + web3.fromWei(donateAmount) + " ether from Alice to " + accountNames[index]);
            web3.eth.sendTransaction({ from: accountMinerId, to: accountId, value: donateAmount }, function(err, address) {
                ensureSynchronization();
                if (err)
                    reject();
                else
                    resolve();
            });
        } else {
            resolve();
        }
    };
    var promises = [
        new Promise(function(resolve, reject) { checkDonationAccount(resolve, reject, 3); }),
        new Promise(function(resolve, reject) { checkDonationAccount(resolve, reject, 4); })
    ];
    return Promise.all(promises);
}

export function ensureSynchronization() {
    // TODO: Rework this! Use events?
    var blockNumber = web3.eth.blockNumber + 1;
    while (blockNumber > web3.eth.blockNumber) {}
}

export function printAccounts() {
    console.log("    There are " + accountIds.length + " nodes in the network:");
    for (var i = 0; i < accountIds.length && i < accountNames.length; ++i) {
        console.log("     " + i + ". " + accountNames[i] + "\t: " + accountIds[i] + " has " + web3.fromWei(web3.eth.getBalance(accountIds[i])).toPrecision(7) + " ether. " + accountDescriptions[i]);
    }
}

export function printAccountsShort() {
    var message = "";
    for (var i = 0, c = accountIds.length; i < c; ++i) {
        message += (i == 0 ? "" : "    ") + i + ": " + web3.fromWei(web3.eth.getBalance(accountIds[i])).toPrecision(7);
    }
    console.log("    Account balances:    " + message + "                   Block: " + web3.eth.blockNumber + "    Timestamp: " + web3.eth.getBlock("latest").timestamp);
}

export function printTokenInfo() {
    return getPapyrusToken().then(function(instance) {
        return instance.totalSupply.call().then(function(totalSupply) {
            console.log("    Papyrus Token (" + instance.address + "): Total supply PPR = " + web3.fromWei(totalSupply).toPrecision(7) +
                "; Balance = " + web3.fromWei(web3.eth.getBalance(instance.address)).toPrecision(7) +
                "    Block: " + web3.eth.blockNumber + "    Timestamp: " + web3.eth.getBlock("latest").timestamp);
        });
    });
}

export function getPapyrusToken() {
    if (!tokenContract) {
        console.log("    Creating new Papyrus Token contract...");
        return PapyrusToken.new({ from: accountMinerId }).then(function(instance) {
            tokenContract = instance;
            assert(web3.eth.getCode(tokenContract.address) != "0x0");
            console.log("    Papyrus Token contract address: " + tokenContract.address);
            registerEvent(tokenContract.Transfer(), function(error, result) {
                if (!error) {
                    console.log("[EVENT] ERC20Basic::Transfer: from " + result.args.from + " to " + result.args.to + " (" + web3.fromWei(result.args.value) + " PPR) (block:" + result.blockNumber + ")");
                }
            });
            registerEvent(tokenContract.Approval(), function(error, result) {
                if (!error) {
                    console.log("[EVENT] ERC20::Approval: from " + result.args.owner + " to " + result.args.spender + " (" + web3.fromWei(result.args.value) + " PPR) (block:" + result.blockNumber + ")");
                }
            });
            registerEvent(tokenContract.MinterRegistered(), function(error, result) {
                if (!error) {
                    console.log("[EVENT] MintableToken::MinterRegistered: " + result.args.minter + " (block:" + result.blockNumber + ")");
                }
            });
            registerEvent(tokenContract.MinterUnregistered(), function(error, result) {
                if (!error) {
                    console.log("[EVENT] MintableToken::MinterUnregistered: " + result.args.minter + " (block:" + result.blockNumber + ")");
                }
            });
            registerEvent(tokenContract.Mint(), function(error, result) {
                if (!error) {
                    console.log("[EVENT] MintableToken::Mint: " + result.args.to + " (" + web3.fromWei(result.args.amount) + " PPR) (block:" + result.blockNumber + ")");
                }
            });
            registerEvent(tokenContract.MintFinished(), function(error, result) {
                if (!error) {
                    console.log("[EVENT] MintableToken::MintFinished (block:" + result.blockNumber + ")");
                }
            });
            registerEvent(tokenContract.BecameTransferable(), function(error, result) {
                if (!error) {
                    console.log("[EVENT] PapyrusToken::BecameTransferable (block:" + result.blockNumber + ")");
                }
            });
            return PapyrusToken.at(tokenContract.address);
        });
    } else {
        return PapyrusToken.at(tokenContract.address);
    }
}

export function startCrowdsale(start, end, cap, targetAccountIndex) {
    assert(!crowdsaleContract);
    if (!crowdsaleContract) {
        return getPapyrusToken().then(function(instance) {
            var papyrusToken = instance;
            console.log("    Creating new Papyrus Crowdsale contract...");
            return Crowdsale.new(instance.address, accountIds[targetAccountIndex], start, end, 1, web3.toWei(cap, "ether"), { from: accountMinerId }).then(function(instance) {
                crowdsaleContract = instance;
                assert(web3.eth.getCode(crowdsaleContract.address) != "0x0");
                console.log("    Papyrus Crowdsale contract address: " + crowdsaleContract.address);
                registerEvent(crowdsaleContract.LogMessage(), function(error, result) {
                    if (!error) {
                        console.log("[EVENT] Crowdsale::LogMessage: " + result.args.message + " (" + web3.fromWei(result.args.value) + " ether) (block:" + result.blockNumber + ")");
                    }
                });
                registerEvent(crowdsaleContract.TokenPurchase(), function(error, result) {
                    if (!error) {
                        var msg = "[EVENT] Crowdsale::TokenPurchase: " + result.args.purchaser + " bought " + web3.fromWei(result.args.value) + " PPR on wallet " + result.args.beneficiary + " (block:" + result.blockNumber + ")";
                        console.log(msg);
                    }
                });
                return papyrusToken.registerMinter(crowdsaleContract.address, { from: accountMinerId }).then(function(result) {
                    if (result) {
                        console.log("    Papyrus Crowdsale contract registered at Papyrus Token");
                    }
                    return crowdsaleContract;
                });
            });
        });
    } else {
        return Crowdsale.at(crowdsaleContract.address);
    }
}

export function checkAbilityToBuyPPR(fromIndex, amount, shouldBeAble) {
    var amountWei = web3.toBigNumber(web3.toWei(amount, 'ether'));
    var estimatedGas = web3.eth.estimateGas({
        to: crowdsaleContract.address,
        value: amountWei
    });
    if (shouldBeAble || estimatedGas < web3.eth.getBlock("pending").gasLimit) {
        var initialBalanceWei = web3.toBigNumber(web3.eth.getBalance(accountIds[fromIndex]));
        return tokenContract.totalSupply.call().then(function(initialTotalSupply) {
            printAccountsShort();
            return printTokenInfo().then(function() {
                return Crowdsale.at(crowdsaleContract.address).then(function(instance) {
                    return new Promise(function(resolve, reject) {
                        console.log("    Making transfer " + amount + " ether from " + accountNames[fromIndex] + " to Crowdsale contract address " + instance.address + "...");
                        return instance.sendTransaction({
                            from: accountIds[fromIndex],
                            value: amountWei,
                            gas: estimatedGas
                        }).then(function(result) {
                            //ensureSynchronization();
                            printAccountsShort();
                            resolve(result);
                        }).catch(function(err) {
                            //ensureSynchronization();
                            printAccountsShort();
                            if (shouldBeAble)
                                reject(err);
                            else
                                resolve();
                        });
                    }).then(function(result) {
                        //console.log(result);
                        return printTokenInfo().then(function() {
                            var newBalanceWei = web3.toBigNumber(web3.eth.getBalance(accountIds[fromIndex]));
                            if (shouldBeAble) {
                                var differenceWei = initialBalanceWei.minus(newBalanceWei);
                                assert(differenceWei.greaterThanOrEqualTo(amountWei));
                                assert(differenceWei.lessThanOrEqualTo(amountWei.plus(estimatedGas * web3.eth.gasPrice)));
                            }
                            return tokenContract.totalSupply.call().then(function(totalSupply) {
                                if (shouldBeAble) {
                                    assert(totalSupply.equals(initialTotalSupply.plus(amountWei)));
                                } else {
                                    assert(totalSupply.equals(initialTotalSupply));
                                }
                            });
                        });
                    });
                });
            });
        });
    }
}

export function checkAbilityToTransferPPR(fromIndex, toIndex, amount, shouldBeAble) {
    /*return getPapyrusToken().then(function(instance) {
        var papyrusPrice = web3.toWei(amount, 'ether');
        var initialBalance = web3.eth.getBalance(accountIds[fromIndex]).valueOf();
        return instance.totalSupply.call().then(function(initialTotalSupply) {
            return instance.buy({ from: accountIds[fromIndex], value: papyrusPrice }).then(function() {
                var newBalance = web3.eth.getBalance(accountIds[fromIndex]).valueOf();
                if (shouldBeAble) {
                    var difference = initialBalance - newBalance;
                    assert(difference >= papyrusPrice);
                }
                return instance.totalSupply.call().then(function(totalSupply) {
                    if (shouldBeAble) {
                        assert.equal(totalSupply.valueOf(), initialTotalSupply.plus(papyrusPrice), "Total supply should be changed on difference");
                    } else {
                        assert.equal(totalSupply.valueOf(), initialTotalSupply.valueOf(), "Total supply should not be changed");
                    }
                    return printTokenInfo();
                });
            });
        });
    });*/
}

export function waitUntilBlockNumber(blockNumber) {
    while (blockNumber > web3.eth.blockNumber) {}
}

export function deinitialize() {
    for (var i = 0; i < events.length; ++i) {
        events[i].stopWatching();
    }
}