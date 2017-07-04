var PapyrusToken = artifacts.require("./PapyrusToken.sol");

module.exports = function(deployer) {
    deployer.deploy(PapyrusToken);
};