var fs = require('fs');

var PapyrusRegistry = artifacts.require("./PapyrusRegistry.sol");

var MultiSigWalletWithDailyLimit = artifacts.require("./gnosis/MultiSigWalletWithDailyLimit.sol");
var PapyrusTokenTest = artifacts.require("./PapyrusTokenTest.sol");
var PapyrusDAO = artifacts.require("./dao/PapyrusDAO.sol");
var SSPRegistry = artifacts.require("./registry/impl/SSPRegistryImpl.sol");
var DSPRegistry = artifacts.require("./registry/impl/DSPRegistryImpl.sol");
var PublisherRegistry = artifacts.require("./registry/impl/PublisherRegistryImpl.sol");
var AuditorRegistry = artifacts.require("./registry/impl/AuditorRegistryImpl.sol");
var SecurityDepositRegistry = artifacts.require("./registry/impl/SecurityDepositRegistry.sol");
var ECRecovery = artifacts.require("./common/ECRecovery.sol");
var EndpointRegistryContract = artifacts.require("./channel/EndpointRegistryContract.sol");
var ChannelManagerContract = artifacts.require("./channel/ChannelManagerContract.sol");
var CampaignManagerContract = artifacts.require("./channel/CampaignManagerContract.sol");
var SspManagerContract = artifacts.require("./channel/SspManagerContract.sol");
var RtbSettlementContract = artifacts.require("./channel/RtbSettlementContract.sol");
var CampaignContract = artifacts.require("./channel/CampaignContract.sol");
var SspContract = artifacts.require("./channel/SspContract.sol");

var addressPapyrusRegistry = '0x8Ef23e41a64722a28acFC12F5b0Ac326E0aBdD13';

var addressCoreAccount = web3.eth.accounts[0];
var addressPapyrusTokenTest;
var addressPapyrusDAO;
var addressSSPRegistry;
var addressDSPRegistry;
var addressPublisherRegistry;
var addressAuditorRegistry;
var addressSecurityDepositRegistry;
var addressECRecovery;
var addressEndpointRegistry;
var addressChannelManager;
var addressCampaignManager;
var addressSspManager;


function printAddresses() {
    console.log("====================================");
    console.log("Core account: " + addressCoreAccount);
    console.log("Contracts:");
    console.log("  Test Papyrus Token: " + addressPapyrusTokenTest);
    console.log("  Papyrus DAO: " + addressPapyrusDAO);
    console.log("    SSP Registry: " + addressSSPRegistry);
    console.log("    DSP Registry: " + addressDSPRegistry);
    console.log("    Publisher Registry: " + addressPublisherRegistry);
    console.log("    Auditor Registry: " + addressAuditorRegistry);
    console.log("    Security Deposit Registry: " + addressSecurityDepositRegistry);
    console.log("  Endpoint Registry: " + addressEndpointRegistry);
    console.log("  Channel Manager: " + addressChannelManager);
    console.log("    ECRecovery: " + addressECRecovery);
    console.log("  Campaign Manager: " + addressCampaignManager);
    console.log("  SSP Manager: " + addressSspManager);
    console.log("====================================");
    fs.writeFileSync("contracts.properties", "dao=" + addressPapyrusDAO + "\n" + "token=" + addressPapyrusTokenTest);
}

function linkDao(registryName, registryContract) {
    registryContract.transferDao(addressPapyrusDAO).then(function(result) {
        console.log("Dao linked to " + registryName);
    }).catch(function(err) {
        console.log("Error while linking Dao to " + registryName + " : " + err);
    });
}

module.exports = function(deployer) {
    let papyrusRegistry = PapyrusRegistry.at(addressPapyrusRegistry);
    // First of all deploy all necessary multi signature wallets
    // For now use daily non limit multi signature wallets with 5 owners and zero daily limit
    deployer.deploy(PapyrusTokenTest).then(function() {
        addressPapyrusTokenTest = PapyrusTokenTest.address;
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
        return deployer.deploy(PapyrusDAO, addressPapyrusTokenTest, addressSSPRegistry, addressDSPRegistry, addressPublisherRegistry,
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
        return deployer.deploy(ChannelManagerContract, addressPapyrusDAO);
    }).then(function() {
        addressChannelManager = ChannelManagerContract.address;
        return deployer.deploy(CampaignManagerContract,
            addressPapyrusTokenTest,
            addressChannelManager
        );
    }).then(function() {
        addressCampaignManager = CampaignManagerContract.address;
        return deployer.deploy(SspManagerContract,
            addressPapyrusTokenTest,
            addressChannelManager
        );
    }).then(function() {
        addressSspManager = SspManagerContract.address;
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
        PapyrusTokenTest.at(addressPapyrusTokenTest).setTransferable(true).then(function(result) {
            console.log("[WARNING] PapyrusTokenTest set transferable!");
        }).catch(function(err) {
            console.log("Error while setting PapyrusTokenTest transferable");
        });
    }).then(function() {
        return papyrusRegistry.updateTokenContract(addressPapyrusTokenTest, JSON.stringify(PapyrusTokenTest.abi));
    }).then(function() {
        return papyrusRegistry.updateDaoContract(addressPapyrusDAO, JSON.stringify(PapyrusDAO.abi));
    }).then(function() {
        return papyrusRegistry.updateChannelManagerContract(addressChannelManager, JSON.stringify(ChannelManagerContract.abi));
    }).then(function() {
        return papyrusRegistry.updateCampaignManagerContract(addressCampaignManager, JSON.stringify(CampaignManagerContract.abi));
    }).then(function() {
        return papyrusRegistry.updateSspManagerContract(addressSspManager, JSON.stringify(SspManagerContract.abi));
    }).then(function() {
        return papyrusRegistry.updateRtbSettlementAbi(JSON.stringify(RtbSettlementContract.abi));
    }).then(function() {
        return papyrusRegistry.updateCampaignAbi(JSON.stringify(CampaignContract.abi));
    }).then(function() {
        return papyrusRegistry.updateSspAbi(JSON.stringify(SspContract.abi));
    }).then(function() {
        printAddresses();
    });
};