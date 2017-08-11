var PapyrusToken = artifacts.require("./PapyrusToken.sol");
var PrePapyrusToken = artifacts.require("./PrePapyrusToken.sol");
var PapyrusDAO = artifacts.require("./dao/PapyrusDAO.sol");

module.exports = function(deployer) {
    deployer.deploy(PrePapyrusToken).then(function() {
      return deployer.deploy(PapyrusDAO, PrePapyrusToken.address);
    });
};