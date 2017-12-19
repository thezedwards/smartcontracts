var fs = require('fs');

var MultiSigWalletWithDailyLimit = artifacts.require("./gnosis/MultiSigWalletWithDailyLimit.sol");
var PapyrusPrototypeToken = artifacts.require("./PapyrusPrototypeToken.sol");
var PapyrusDAO = artifacts.require("./dao/PapyrusDAO.sol");
var SSPRegistry = artifacts.require("./registry/impl/SSPRegistryImpl.sol");
var DSPRegistry = artifacts.require("./registry/impl/DSPRegistryImpl.sol");
var PublisherRegistry = artifacts.require("./registry/impl/PublisherRegistryImpl.sol");
var AuditorRegistry = artifacts.require("./registry/impl/AuditorRegistryImpl.sol");
var SecurityDepositRegistry = artifacts.require("./registry/impl/SecurityDepositRegistry.sol");
var ECRecovery = artifacts.require("./common/ECRecovery.sol");
var EndpointRegistryContract = artifacts.require("./channel/EndpointRegistryContract.sol");
var ChannelManagerContract = artifacts.require("./channel/ChannelManagerContract.sol");

var addressCoreAccount = web3.eth.accounts[0];
var addressPapyrusPrototypeToken;
var addressPapyrusDAO;
var addressSSPRegistry;
var addressDSPRegistry;
var addressPublisherRegistry;
var addressAuditorRegistry;
var addressSecurityDepositRegistry;
var addressECRecovery;
var addressEndpointRegistry;
var addressChannelManager;


function printAddresses() {
    console.log("====================================");
    console.log("Core account: " + addressCoreAccount);
    console.log("Contracts:");
    console.log("  Papyrus Prototype Token: " + addressPapyrusPrototypeToken);
    console.log("  Papyrus DAO: " + addressPapyrusDAO);
    console.log("    SSP Registry: " + addressSSPRegistry);
    console.log("    DSP Registry: " + addressDSPRegistry);
    console.log("    Publisher Registry: " + addressPublisherRegistry);
    console.log("    Auditor Registry: " + addressAuditorRegistry);
    console.log("    Security Deposit Registry: " + addressSecurityDepositRegistry);
    console.log("  Endpoint Registry: " + addressEndpointRegistry);
    console.log("  Channel Manager: " + addressChannelManager);
    console.log("    ECRecovery: " + addressECRecovery);
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

module.exports = function(deployer) {
    // First of all deploy all necessary multi signature wallets
    // For now use daily non limit multi signature wallets with 5 owners and zero daily limit
    deployer.deploy(PapyrusPrototypeToken).then(function() {
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
    }).then(function() {
        addressECRecovery = ECRecovery.address;
        return deployer.deploy(EndpointRegistryContract);
    }).then(function() {
        addressEndpointRegistry = EndpointRegistryContract.address;
        deployer.link(ECRecovery, ChannelManagerContract);
        return deployer.deploy(ChannelManagerContract, addressPapyrusPrototypeToken, addressPapyrusDAO);
    }).then(function() {
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
    }).then(function() {
        //TODO: Must be removed before deploying to anything public
        PapyrusPrototypeToken.at(addressPapyrusPrototypeToken).setTransferable(true).then(function(result) {
            console.log("[WARNING] PapyrusPrototypeToken set transferable!");
        }).catch(function(err) {
            console.log("Error while setting PapyrusPrototypeToken transferable");
        });
    }).then(function() {
        printAddresses();
    });
};