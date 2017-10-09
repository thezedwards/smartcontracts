var fs = require('fs');

var MultiSigWalletWithDailyLimit = artifacts.require("./gnosis/MultiSigWalletWithDailyLimit.sol");
var PapyrusPrototypeToken = artifacts.require("./PapyrusPrototypeToken.sol");
var PapyrusDAO = artifacts.require("./dao/PapyrusDAO.sol");
var SSPRegistry = artifacts.require("./registry/impl/SSPRegistryImpl.sol");
var DSPRegistry = artifacts.require("./registry/impl/DSPRegistryImpl.sol");
var PublisherRegistry = artifacts.require("./registry/impl/PublisherRegistryImpl.sol");
var AuditorRegistry = artifacts.require("./registry/impl/AuditorRegistryImpl.sol");
var SecurityDepositRegistry = artifacts.require("./registry/impl/SecurityDepositRegistry.sol");
var ECRecovery = artifacts.require("./zeppelin/ECRecovery.sol");
var ChannelLibrary = artifacts.require("./channel/ChannelLibrary.sol");
var EndpointRegistryContract = artifacts.require("./channel/EndpointRegistryContract.sol");
var ChannelManagerContract = artifacts.require("./channel/ChannelManagerContract.sol");

var addressWalletPRP; // Containing 10% (5,000,000) of created PRP to pay bounty, bonuses, etc.
var addressWalletETH_A; // Containing received ETH during TGE 1 auction and 90% (45,000,000) of created PRP

var addressPapyrusKYC;
var addressPapyrusPrototypeToken;
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
var addressECRecovery;
var addressChannelLibrary;
var addressEndpointRegistry;
var addressChannelManager;


function printAddresses() {
    console.log("====================================");
    console.log("Core account: " + addressCoreAccount);
    console.log("Wallets owner A: " + addressOwnerWallets_A);
    console.log("Wallets:");
    console.log("  PRP holder: " + addressWalletPRP);
    console.log("  ETH holder (TGE1): " + addressWalletETH_A);
    console.log("Contracts:");
    console.log("  Papyrus KYC: " + addressPapyrusKYC);
    console.log("  Papyrus Prototype Token: " + addressPapyrusPrototypeToken);
    console.log("  Papyrus Token: " + addressPapyrusToken);
    console.log("  Papyrus DAO: " + addressPapyrusDAO);
    console.log("    SSP Registry: " + addressSSPRegistry);
    console.log("    DSP Registry: " + addressDSPRegistry);
    console.log("    Publisher Registry: " + addressPublisherRegistry);
    console.log("    Auditor Registry: " + addressAuditorRegistry);
    console.log("    Security Deposit Registry: " + addressSecurityDepositRegistry);
    console.log("  Endpoint Registry: " + addressEndpointRegistry);
    console.log("  Channel Manager: " + addressChannelManager);
    console.log("    Channel Library: " + addressChannelLibrary);
    console.log("      ECRecovery: " + addressECRecovery);
    console.log("====================================");
    fs.writeFileSync("contracts.properties", "dao=" + addressPapyrusDAO + "\n" + "token=" + addressPapyrusPrototypeToken);
}

function linkDao(registryName, registryContract) {
    registryContract.transferDao(addressPapyrusDAO).then(function(result) {
        console.log("Dao linked to " + registryName);
    }).catch(function(err) {
        console.log("Error while linking Dao to " + registryName + " : " + err);
    });
}

var CR = 3; // Confirmation count required for Papyrus Wallets
var DL = 0; // Daily limit used for Papyrus Wallets (in weis)

module.exports = function(deployer) {
    // First of all deploy all necessary multi signature wallets
    // For now use daily non limit multi signature wallets with 5 owners and zero daily limit
    deployer.deploy(MultiSigWalletWithDailyLimit, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL).then(function() {
        addressWalletPRP = MultiSigWalletWithDailyLimit.address;
        return deployer.deploy(MultiSigWalletWithDailyLimit, [addressOwnerWallets_A, addressOwnerWallets_B, addressOwnerWallets_C, addressOwnerWallets_D, addressOwnerWallets_E], CR, DL);
    }).then(function() {
        addressWalletETH_A = MultiSigWalletWithDailyLimit.address;
        // Deploy smart-contract implementing PRP token
        return deployer.deploy(PapyrusPrototypeToken, [addressWalletPRP, addressWalletETH_A], [web3.toWei(5000000, "ether"), web3.toWei(45000000, "ether")]);
    }).then(function() {
        addressPapyrusPrototypeToken = PapyrusPrototypeToken.address;
        return deployer.deploy(DSPRegistry);
    }).then(function() {
        addressDSPRegistry = DSPRegistry.address;
        return deployer.deploy(SSPRegistry);
    }).then(function() {
        addressSSPRegistry = SSPRegistry.address;
        return deployer.deploy(PublisherRegistry);
    }).then(function() {
        addressPublisherRegistry = PublisherRegistry.address;
        return deployer.deploy(AuditorRegistry);
    }).then(function() {
        addressAuditorRegistry = AuditorRegistry.address;
        return deployer.deploy(SecurityDepositRegistry);
    }).then(function() {
        addressSecurityDepositRegistry = SecurityDepositRegistry.address;
        return deployer.deploy(PapyrusDAO, addressPapyrusPrototypeToken, addressSSPRegistry, addressDSPRegistry, addressPublisherRegistry,
            addressAuditorRegistry, addressSecurityDepositRegistry);
    }).then(function() {
        addressPapyrusDAO = PapyrusDAO.address;
        return deployer.deploy(ECRecovery);
    }).then(function () {
        addressECRecovery = ECRecovery.address;
        deployer.link(ECRecovery, ChannelLibrary);
        return deployer.deploy(ChannelLibrary);
    }).then(function () {
        addressChannelLibrary = ChannelLibrary.address;
        return deployer.deploy(EndpointRegistryContract);
    }).then(function () {
        addressEndpointRegistry = EndpointRegistryContract.address;
        deployer.link(ChannelLibrary, ChannelManagerContract);
        return deployer.deploy(ChannelManagerContract, addressPapyrusPrototypeToken, addressPapyrusDAO);
    }).then(function () {
        addressChannelManager = ChannelManagerContract.address;
        linkDao("SSPRegistry", SSPRegistry.at(addressSSPRegistry));
        linkDao("DSPRegistry", DSPRegistry.at(addressDSPRegistry));
        linkDao("PublisherRegistry", PublisherRegistry.at(addressPublisherRegistry));
        linkDao("AuditorRegistry", AuditorRegistry.at(addressAuditorRegistry));
        linkDao("SecurityDepositRegistry", SecurityDepositRegistry.at(addressSecurityDepositRegistry));
        PapyrusDAO.at(addressPapyrusDAO).replaceChannelContractAddress(addressChannelManager).then(function(result) {
            console.log("Dao linked to ChannelManagerContract");
        }).catch(function(err) {
            console.log("Error while linking Dao to ChannelManagerContract : " + err);
        });
    }).then(function () {
        //TODO: Must be removed before deploying to anything public
        PapyrusPrototypeToken.at(addressPapyrusPrototypeToken).setTransferable(true).then(function(result) {
            console.log("[WARNING] PapyrusPrototypeToken set transferable!");
        }).catch(function(err) {
            console.log("Error while setting PapyrusPrototypeToken transferable");
        });
    }).then(function () {
        printAddresses();
    });
};