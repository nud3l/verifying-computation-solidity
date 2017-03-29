// var usingOraclize = artifacts.require("./usingOraclize.sol");
var ComputationService = artifacts.require("./ComputationService.sol");

module.exports = function(deployer) {
  //deployer.deploy(usingOraclize);
  //deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(ComputationService);
};
