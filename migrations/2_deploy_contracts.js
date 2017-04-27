// var usingOraclize = artifacts.require("./usingOraclize.sol");
var Arbiter = artifacts.require("./Arbiter.sol");
var Judge = artifacts.require("./Judge.sol");
var ComputationService = artifacts.require("./ComputationService.sol");

module.exports = function(deployer) {
  var arbiter, judge, computation;

  deployer.deploy(Arbiter);
  deployer.deploy(Judge);

  deployer.then(function() {
    return Judge.deployed();
  }).then(function(instance) {
    judge = instance;
    return Arbiter.deployed();
  }).then(function(instance) {
    arbiter = instance;
    return arbiter.setJudge(judge.address);
  });

  // deploy six computation services
  for (i = 0; i < 6; i++) {
    deployer.deploy(ComputationService);

    deployer.then(function() {
      return ComputationService.deployed();
    }).then(function(instance) {
      computation = instance;
      return computation.registerOperation(0);
    });

    deployer.then(function() {
      return Arbiter.deployed();
    }).then(function(instance) {
      arbiter = instance;
      return ComputationService.deployed();
    }).then(function(instance) {
      computation = instance;
      return computation.enableArbiter(arbiter.address);
    });
  }
};
