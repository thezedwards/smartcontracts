var Migrations = artifacts.require("./zeppelin/lifecycle/Migrations.sol");

module.exports = function(deployer) {
    deployer.deploy(Migrations);
};