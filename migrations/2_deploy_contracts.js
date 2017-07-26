var PapyrusToken = artifacts.require("./PapyrusToken.sol");
var SenselessContract = artifacts.require("./registry/SenselessContract.sol");
var ArbiterRegistry = artifacts.require("./registry/ArbiterRegistry.sol");
var DSPRegistry = artifacts.require("./registry/DSPRegistry.sol");

module.exports = function(deployer) {
    deployer.deploy(PapyrusToken);
    deployer.deploy(SenselessContract);
    deployer.deploy(ArbiterRegistry);
    deployer.deploy(DSPRegistry);
};