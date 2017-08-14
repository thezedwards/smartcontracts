var PapyrusToken = artifacts.require("./PapyrusToken.sol");
var PrePapyrusToken = artifacts.require("./PrePapyrusToken.sol");
var PapyrusDAO = artifacts.require("./dao/PapyrusDAO.sol");

module.exports = function(deployer) {
    deployer.deploy(PrePapyrusToken, "0xf61e02f629e3ca8af430f8db8d1ab22c7093303b",
        ["0x1311ad419343f0bb20750e295aab1dd6299b3ac7",
         "0x74d1a4b07a1af3f38e4c7c91e177bd2195909bf1",
         "0xde0a0ab0af829dd7ba1c62f5b3fe9b88f7d92496",
         "0x9aaa67a61c893fbd5b92e3bfce2661a6c2695805"], [100.0, 100.0, 100.0, 100.0]
    ).then(function() {
      return deployer.deploy(PapyrusDAO, PrePapyrusToken.address);
    });
};