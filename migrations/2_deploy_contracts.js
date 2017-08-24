var MiltiSigWallet = artifacts.require("./MultiSigWallet.sol");
var PapyrusKYC = artifacts.require("./PapyrusKYC.sol");
var PrePapyrusToken = artifacts.require("./PrePapyrusToken.sol");
var PapyrusToken = artifacts.require("./PapyrusToken.sol");
var PapyrusSalePhase1 = artifacts.require("./PapyrusSalePhase1.sol");
var PapyrusDAO = artifacts.require("./dao/PapyrusDAO.sol");

var addressWalletPRP; // Containing 5-10% of created PRP to pay bounty, bonuses, etc.
var addressWalletPPR_A; // Containing PPR for Papyrus Foundation (10%)
var addressWalletPPR_B; // Containing PPR for Papyrus Founding Team (10%)
var addressWalletPPR_C; // Containing PPR for Papyrus Network Growth (15%)
var addressWalletPPR_D; // Containing PPR for Papyrus Pre-sale & Sale Phase 1 auctions (35%)
var addressWalletPPR_E; // Containing PPR for Papyrus Sale Phase 2 auction (20%)
var addressWalletPPR_F; // Containing PPR for Papyrus DAO (10%)
var addressWalletETH_A; // Containing received ETH during pre-sale auction
var addressWalletETH_B; // Containing received ETH during sale phase 1 auction

var addressPapyrusKYC;
var addressPrePapyrusToken;
var addressPapyrusToken;
var addressPapyrusSalePhase1;
var addressPapyrusDAO;

var addressCoreAccount = web3.eth.accounts[0]; // TODO: Replace this with proper address
var addressOwnerWallets_A = web3.eth.accounts[1]; // TODO: Replace this with proper address
var addressOwnerWallets_B = web3.eth.accounts[2]; // TODO: Replace this with proper address
var addressOwnerWallets_C = web3.eth.accounts[3]; // TODO: Replace this with proper address

function printAddresses() {
    console.log("Core cccount: " + addressCoreAccount);
    console.log("Wallets owner A: " + addressOwnerWallets_A);
    console.log("Wallets owner B: " + addressOwnerWallets_B);
    console.log("Wallets owner C: " + addressOwnerWallets_C);
    console.log("Wallets:");
    console.log("  PRP holder: " + addressWalletPRP);
    console.log("  PPR holder A: " + addressWalletPPR_A);
    console.log("  PPR holder B: " + addressWalletPPR_B);
    console.log("  PPR holder C: " + addressWalletPPR_C);
    console.log("  PPR holder D: " + addressWalletPPR_D);
    console.log("  PPR holder E: " + addressWalletPPR_E);
    console.log("  PPR holder F: " + addressWalletPPR_F);
    console.log("  ETH holder (pre-sale): " + addressWalletETH_A);
    console.log("  ETH holder (sale phase 1): " + addressWalletETH_B);
    console.log("Contracts:");
    console.log("  Papyrus KYC: " + addressPapyrusKYC);
    console.log("  PrePapyrus Token: " + addressPrePapyrusToken);
    console.log("  Papyrus Token: " + addressPapyrusToken);
    console.log("  Papyrus Sale Phase 1: " + addressPapyrusSalePhase1);
    console.log("  Papyrus DAO: " + addressPapyrusDAO);
}

module.exports = function(deployer) {
    // First of all deploy all necessary multisignature wallets
    // For now use daily non limit multisignature wallets with 3 owners
    deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2).then(function() {
        addressWalletPRP = MiltiSigWallet.address;
        return deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2);
    }).then(function() {
        addressWalletPPR_A = MiltiSigWallet.address;
        return deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2);
    }).then(function() {
        addressWalletPPR_B = MiltiSigWallet.address;
        return deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2);
    }).then(function() {
        addressWalletPPR_C = MiltiSigWallet.address;
        return deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2);
    }).then(function() {
        addressWalletPPR_D = MiltiSigWallet.address;
        return deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2);
    }).then(function() {
        addressWalletPPR_E = MiltiSigWallet.address;
        return deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2);
    }).then(function() {
        addressWalletPPR_F = MiltiSigWallet.address;
        return deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2);
    }).then(function() {
        addressWalletETH_A = MiltiSigWallet.address;
        return deployer.deploy(MiltiSigWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C], 2);
    }).then(function() {
        addressWalletETH_B = MiltiSigWallet.address;
        // Then deploy another important smart-contract implementing KYC verifications
        return deployer.deploy(PapyrusKYC);
    }).then(function() {
        addressPapyrusKYC = PapyrusKYC.address;
        // Deploy smart-contract implementing PRP token and pre-sale auction
        return deployer.deploy(PrePapyrusToken, addressPapyrusKYC, [addressWalletPRP], [web3.toWei(2500000, "ether")]);
    }).then(function() {
        addressPrePapyrusToken = PrePapyrusToken.address;
        // Deploy smart-contract implementing PPR token
        return deployer.deploy(PapyrusToken, [
            addressWalletPPR_A,
            addressWalletPPR_B,
            addressWalletPPR_C,
            addressWalletPPR_D,
            addressWalletPPR_E,
            addressWalletPPR_F
        ], [
            web3.toWei(100000000, "ether"),
            web3.toWei(100000000, "ether"),
            web3.toWei(150000000, "ether"),
            web3.toWei(350000000, "ether"),
            web3.toWei(200000000, "ether"),
            web3.toWei(100000000, "ether")
        ]);
    }).then(function() {
        addressPapyrusToken = PapyrusToken.address;
        // Deploy smart-contract implementing PPR sale phase 1 auction
        return deployer.deploy(PapyrusSalePhase1, addressPrePapyrusToken, addressWalletETH_B);
    }).then(function() {
        addressPapyrusSalePhase1 = PapyrusSalePhase1.address;
        // Deploy smart-contract implementing DAO
        return deployer.deploy(PapyrusDAO, addressPrePapyrusToken);
    }).then(function() {
        addressPapyrusDAO = PapyrusDAO.address;
    }).then(function() {
        printAddresses();
    });
};