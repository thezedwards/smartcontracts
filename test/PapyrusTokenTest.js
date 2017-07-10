/*jshint esversion: 6 */

import {
    waitMiner,
    shareEther,
    ensureSynchronization,
    printAccounts,
    printAccountsShort,
    printTokenInfo,
    getPapyrusToken,
    startCrowdsale,
    testSolidityEvents,
    checkAbilityToBuyPPR,
    checkAbilityToTransferPPR,
    waitUntilBlockNumber,
    deinitialize
} from './PapyrusLibraryTest.js';

var startPrivatePreSale = 0;
var startPublicPreSale = 0;
var startSalePhase1 = 0;
var startSalePhase2 = 0;

describe("Waiting until main account has enough ether to start testing...", function() {
    this.timeout(600000);
    it("OK", function() { waitMiner(); });
});

describe("Make sure all donating accounts have enough ether to start testing...", function() {
    this.timeout(600000);
    it("OK", function() { return shareEther(); });
});

/*describe("Ensuring all transactions are synchronized with the Ethereum...", function() {
    this.timeout(600000);
    it("OK", function() { ensureSynchronization(); });
});*/

describe("Retrieving information about known accounts...", function() {
    this.timeout(600000);
    it("OK", function() { printAccounts(); });
});

describe("Preparing Papyrus Token smart-contract...", function() {
    this.timeout(600000);
    it("OK", function() {
        return getPapyrusToken().then(function(instance) {
            return instance.owner.call().then(function(owner) {
                assert(owner.length > 0);
                console.log("    Owner of the Papyrus Token contract: " + owner);
                return printTokenInfo();
            });
        });
    });
});

describe("Creating private pre-sale Papyrus Crowdsale contract...", function() {
    this.timeout(600000);
    it("OK", function() {
        startPrivatePreSale = web3.eth.blockNumber + 10;
        return startCrowdsale(startPrivatePreSale, startPrivatePreSale + 100, 10, 1);
    });
});

describe("Ensuring all transactions are synchronized with the Ethereum...", function() {
    this.timeout(600000);
    it("OK", function() { ensureSynchronization(); });
});

describe("Checking common state of Papyrus Token...", function() {
    this.timeout(600000);
    it("Should not be able to buy PPR before crowdsale is started", function() { return checkAbilityToBuyPPR(4, 1.0, false); });
});

describe("Waiting until crowdsale is started...", function() {
    this.timeout(600000);
    it("OK", function() { waitUntilBlockNumber(startPrivatePreSale); });
});

describe("Checking common state of Papyrus Token...", function() {
    this.timeout(600000);
    it("Should be able to buy PPR after crowdsale is started", function() { return checkAbilityToBuyPPR(3, 0.1, true); });
});

describe("Finishing testing...", function() {
    it("OK", function() { deinitialize(); });
});