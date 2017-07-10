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

const MINER_ETHER_MIN = 150;
const MINER_ETHER_MIN_WEI = web3.toBigNumber(web3.toWei(MINER_ETHER_MIN, "ether"));
const ACCOUNT_ETHER_MIN = 25;
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

    var messageEther = "";
    var messagePPR = "";
    var index = 0;

    for (var i = 0, c = accountIds.length; i < c; ++i) {
        messageEther += (i == 0 ? "" : "    ") + accountNames[i] + ": " + web3.fromWei(web3.eth.getBalance(accountIds[i])).toPrecision(7);
    }

    function balanceReceived(result) {
        if (index < accountIds.length) {
            messagePPR += (index == 0 ? "" : "    ") + accountNames[index] + ": " + web3.toBigNumber(web3.fromWei(result)).toPrecision(7);
            if (index < accountIds.length - 1) {
                return tokenContract.balanceOf.call(accountIds[++index]).then(balanceReceived);
            } else {
                var block = web3.eth.getBlock("latest");
                console.log("Block " + block.number + " : Account balances (Ether):    " + messageEther);
                console.log("Block " + block.number + " : Account balances (PPR):      " + messagePPR);
            }
        }
    }

    return tokenContract.balanceOf.call(accountIds[index]).then(balanceReceived);
}

export function printTokenInfo() {
    return tokenContract.totalSupply.call().then(function(totalSupply) {
        var block = web3.eth.getBlock("latest");
        console.log("Block " + block.number + " : Papyrus Token (" + tokenContract.address + ") : Total supply " + web3.fromWei(totalSupply).toPrecision(7) + " PPR");
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
        console.log("    Creating new Papyrus Crowdsale contract...");
        return Crowdsale.new(tokenContract.address, accountIds[targetAccountIndex], start, end, 1, web3.toWei(cap, "ether"), { from: accountMinerId }).then(function(instance) {
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
            return tokenContract.registerMinter(crowdsaleContract.address, { from: accountMinerId }).then(function(result) {
                if (result) {
                    console.log("    Papyrus Crowdsale contract registered at Papyrus Token");
                }
                return crowdsaleContract;
            });
        });
    } else {
        return Crowdsale.at(crowdsaleContract.address);
    }
}

export function makeTransferable() {
    console.log("    Making Papyrus Token contract to be transferable so users can send PPR to each other");
    return tokenContract.makeTransferable({ from: accountMinerId }).then(function(result) {
        if (result) {}
    }).catch(function(err) {
        throw err;
    });
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
            return new Promise(function(resolve, reject) {
                console.log("    Making transfer " + amount + " ether from " + accountNames[fromIndex] + " to Crowdsale contract address " + crowdsaleContract.address + "...");
                return crowdsaleContract.sendTransaction({
                    from: accountIds[fromIndex],
                    value: amountWei,
                    gas: estimatedGas
                }).then(function(result) {
                    //ensureSynchronization();
                    resolve(result);
                }).catch(function(err) {
                    //ensureSynchronization();
                    if (shouldBeAble)
                        reject(err);
                    else
                        resolve();
                });
            }).then(function(result) {
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
    }
}

export function checkAbilityToTransferPPR(fromIndex, toIndex, amount, shouldBeAble) {
    var amountWei = web3.toBigNumber(web3.toWei(amount, 'ether'));
    var initialBalanceFrom = web3.toBigNumber(0);
    var initialBalanceTo = web3.toBigNumber(0);
    var newBalanceFrom = web3.toBigNumber(0);
    var newBalanceTo = web3.toBigNumber(0);
    return tokenContract.balanceOf.call(accountIds[fromIndex]).then(function(result) {
        initialBalanceFrom = web3.toBigNumber(result);
        return tokenContract.balanceOf.call(accountIds[toIndex]);
    }).then(function(result) {
        initialBalanceTo = web3.toBigNumber(result);
        return new Promise(function(resolve, reject) {
            console.log("    Making transfer " + amount + " PPR from " + accountNames[fromIndex] + " to " + accountNames[toIndex] + "...");
            return tokenContract.transfer(accountIds[toIndex], amountWei, {
                from: accountIds[fromIndex]
            }).then(function(result) {
                //ensureSynchronization();
                resolve(result);
            }).catch(function(err) {
                //ensureSynchronization();
                if (shouldBeAble)
                    reject(err);
                else
                    resolve();
            });
        });
    }).then(function(result) {
        return tokenContract.balanceOf.call(accountIds[fromIndex]).then(function(result) {
            newBalanceFrom = web3.toBigNumber(result);
            return tokenContract.balanceOf.call(accountIds[toIndex]);
        }).then(function(result) {
            newBalanceTo = web3.toBigNumber(result);
            assert(initialBalanceFrom.minus(amountWei).equals(newBalanceFrom) && initialBalanceTo.plus(amountWei).equals(newBalanceTo));
        });
    }).catch(function(err) {
        if (shouldBeAble)
            throw err;
    });
}

export function waitUntilBlockNumber(blockNumber) {
    while (blockNumber > web3.eth.blockNumber) {}
}

export function deinitialize() {
    for (var i = 0; i < events.length; ++i) {
        events[i].stopWatching();
    }
}