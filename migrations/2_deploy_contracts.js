var PapyrusWallet = artifacts.require("./PapyrusWallet.sol");
var PapyrusKYC = artifacts.require("./PapyrusKYC.sol");
var PrePapyrusToken = artifacts.require("./PrePapyrusToken.sol");
var PapyrusToken = artifacts.require("./PapyrusToken.sol");
var PapyrusDAO = artifacts.require("./dao/PapyrusDAO.sol");
var SSPRegistry = artifacts.require("./registry/impl/SSPRegistryImpl.sol");
var DSPRegistry = artifacts.require("./registry/impl/DSPRegistryImpl.sol");
var PublisherRegistry = artifacts.require("./registry/impl/PublisherRegistryImpl.sol");
var AuditorRegistry = artifacts.require("./registry/impl/AuditorRegistryImpl.sol");
var SecurityDepositRegistry = artifacts.require("./registry/impl/SecurityDepositRegistry.sol");
var SpendingDepositRegistry = artifacts.require("./registry/impl/SpendingDepositRegistry.sol");

var addressWalletPRP; // Containing 10% (5,000,000) of created PRP to pay bounty, bonuses, etc.
var addressWalletPPR_A; // Containing PPR for Papyrus Foundation (10%)
var addressWalletPPR_B; // Containing PPR for Papyrus Founding Team (10%)
var addressWalletPPR_C; // Containing PPR for Papyrus Network Growth (15%)
var addressWalletPPR_D; // Containing PPR for Papyrus Pre-sale & Sale Phase 1 auctions (35%)
var addressWalletPPR_E; // Containing PPR for Papyrus Sale Phase 2 auction (20%)
var addressWalletPPR_F; // Containing PPR for Papyrus DAO (10%)
var addressWalletETH_A; // Containing received ETH during TGE 1 auction and 90% (45,000,000) of created PRP

var addressPapyrusKYC;
var addressPrePapyrusToken;
var addressPapyrusToken;

var addressCoreAccount = web3.eth.accounts[0]; // TODO: Replace this with proper address
var addressOwnerWallets_A = web3.eth.accounts[2]; // TODO: Replace this with proper address
var addressOwnerWallets_B = web3.eth.accounts[3]; // TODO: Replace this with proper address
var addressOwnerWallets_C = web3.eth.accounts[4]; // TODO: Replace this with proper address
var addressOwnerWallets_D = web3.eth.accounts[5]; // TODO: Replace this with proper address
var addressOwnerWallets_E = web3.eth.accounts[6]; // TODO: Replace this with proper address

var addressPapyrusDAO;
var addressSSPRegistry;
var addressDSPRegistry;
var addressPublisherRegistry;
var addressAuditorRegistry;
var addressSecurityDepositRegistry;
var addressSpendingDepositRegistry;


function printAddresses() {
    console.log("====================================");
    console.log("Core account: " + addressCoreAccount);
    console.log("Wallets owner A: " + addressOwnerWallets_A);
    console.log("Wallets owner B: " + addressOwnerWallets_B);
    console.log("Wallets owner C: " + addressOwnerWallets_C);
    console.log("Wallets owner D: " + addressOwnerWallets_D);
    console.log("Wallets owner E: " + addressOwnerWallets_E);
    console.log("Wallets:");
    console.log("  PRP holder: " + addressWalletPRP);
    console.log("  PPR holder A: " + addressWalletPPR_A);
    console.log("  PPR holder B: " + addressWalletPPR_B);
    console.log("  PPR holder C: " + addressWalletPPR_C);
    console.log("  PPR holder D: " + addressWalletPPR_D);
    console.log("  PPR holder E: " + addressWalletPPR_E);
    console.log("  PPR holder F: " + addressWalletPPR_F);
    console.log("  ETH holder (TGE1): " + addressWalletETH_A);
    console.log("Contracts:");
    console.log("  Papyrus KYC: " + addressPapyrusKYC);
    console.log("  PrePapyrus Token: " + addressPrePapyrusToken);
    console.log("  Papyrus Token: " + addressPapyrusToken);
    console.log("  Papyrus DAO: " + addressPapyrusDAO);
    console.log("    SSP Registry: " + addressSSPRegistry);
    console.log("    DSP Registry: " + addressDSPRegistry);
    console.log("    Publisher Registry: " + addressPublisherRegistry);
    console.log("    Auditor Registry: " + addressAuditorRegistry);
    console.log("    Security Deposit Registry: " + addressSecurityDepositRegistry);
    console.log("    Spending Deposit Registry: " + addressSpendingDepositRegistry);
    console.log("====================================");
}

function linkDao(registryContract) {
    registryContract.transferDao(addressPapyrusDAO).then(function(result) {
        console.log("Dao transferred");
    }).catch(function(err) {
        console.log("Error while transferring: " + err);
    });
}

var CR = 3; // Confirmation count required for Papyrus Wallets
var DL = 0; // Daily limit used for Papyrus Wallets (in weis)

module.exports = function(deployer) {
    // First of all deploy all necessary multi signature wallets
    // For now use daily non limit multi signature wallets with 5 owners and zero daily limit
    deployer.deploy(PapyrusWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL).then(function() {
        addressWalletPRP = PapyrusWallet.address;
        return deployer.deploy(PapyrusWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL);
    }).then(function() {
        addressWalletPPR_A = PapyrusWallet.address;
        return deployer.deploy(PapyrusWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL);
    }).then(function() {
        addressWalletPPR_B = PapyrusWallet.address;
        return deployer.deploy(PapyrusWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL);
    }).then(function() {
        addressWalletPPR_C = PapyrusWallet.address;
        return deployer.deploy(PapyrusWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL);
    }).then(function() {
        addressWalletPPR_D = PapyrusWallet.address;
        return deployer.deploy(PapyrusWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL);
    }).then(function() {
        addressWalletPPR_E = PapyrusWallet.address;
        return deployer.deploy(PapyrusWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL);
    }).then(function() {
        addressWalletPPR_F = PapyrusWallet.address;
        return deployer.deploy(PapyrusWallet, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL);
    }).then(function() {
        addressWalletETH_A = PapyrusWallet.address;
        return deployer.deploy(PapyrusKYC);
    }).then(function() {
        addressPapyrusKYC = PapyrusKYC.address;
        // Deploy smart-contract implementing PRP token and pre-sale auction
        return deployer.deploy(PrePapyrusToken, [addressWalletPRP, addressWalletETH_A], [web3.toWei(5000000, "ether"), web3.toWei(45000000, "ether")]);
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
        return deployer.deploy(SSPRegistry);
    }).then(function() {
        addressSSPRegistry = SSPRegistry.address;
        return deployer.deploy(DSPRegistry);
    }).then(function() {
        addressDSPRegistry = DSPRegistry.address;
        return deployer.deploy(PublisherRegistry);
    }).then(function() {
        addressPublisherRegistry = PublisherRegistry.address;
        return deployer.deploy(AuditorRegistry);
    }).then(function() {
        addressAuditorRegistry = AuditorRegistry.address;
        return deployer.deploy(SecurityDepositRegistry);
    }).then(function() {
        addressSecurityDepositRegistry = SecurityDepositRegistry.address;
        return deployer.deploy(SpendingDepositRegistry);
    }).then(function() {
        addressSpendingDepositRegistry = SpendingDepositRegistry.address;
        return deployer.deploy(PapyrusDAO, addressPrePapyrusToken, addressSSPRegistry, addressDSPRegistry, addressPublisherRegistry,
            addressAuditorRegistry, addressSecurityDepositRegistry, addressSpendingDepositRegistry);
    }).then(function() {
        addressPapyrusDAO = PapyrusDAO.address;
        linkDao(SSPRegistry.at(addressSSPRegistry));
        linkDao(DSPRegistry.at(addressDSPRegistry));
        linkDao(PublisherRegistry.at(addressPublisherRegistry));
        linkDao(AuditorRegistry.at(addressAuditorRegistry));
        linkDao(SecurityDepositRegistry.at(addressSecurityDepositRegistry));
        linkDao(SpendingDepositRegistry.at(addressSpendingDepositRegistry));
        printAddresses();
    });
};