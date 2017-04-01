// var usingOraclize = artifacts.require("./usingOraclize.sol");
var ComputationService = artifacts.require("./ComputationService.sol");

module.exports = function(deployer) {
  //deployer.deploy(usingOraclize);
  //deployer.link(ConvertLib, MetaCoin);
  var contracts = [];
  for (i = 0; i < 2; i++) {
    contracts.push(ComputationService);
  }

  deployer.deploy(contracts);
};
