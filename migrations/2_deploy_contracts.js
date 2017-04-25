// var usingOraclize = artifacts.require("./usingOraclize.sol");
var Arbiter = artifacts.require("./Arbiter.sol");
var Judge = artifacts.require("./Judge.sol");
var ComputationService = artifacts.require("./ComputationService.sol");

module.exports = function(deployer) {
  //deployer.deploy(usingOraclize);
  //deployer.link(ConvertLib, MetaCoin);
  var contracts = [];

  // deploy one Arbiter
  contracts.push(Arbiter);

  // deploy one Judge
  contracts.push(Judge);

  // deploy six computation services
  for (i = 0; i < 6; i++) {
    contracts.push(ComputationService);
  }

  deployer.deploy(contracts);
};
