// var usingOraclize = artifacts.require("./usingOraclize.sol");
var Arbiter = artifacts.require("./Arbiter.sol");
var Judge = artifacts.require("./Judge.sol");
var ComputationService = artifacts.require("./ComputationServiceLocally.sol");

module.exports = function(deployer) {
  var arbiter, judge, computation, query, counter;

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

  counter = 0;

  // deploy six computation services
  for (i = 0; i < 10; i++) {
    deployer.deploy(ComputationService);

    deployer.then(function() {
      return ComputationService.deployed();
    }).then(function(instance) {
      computation = instance;
      // correct: "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/int"
      // false: "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/multiplicationWrong"
      query = "";
      if (counter < 3 ) {
        // query = "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/int";
        computation.registerOperation(0, query);
      } else {
        // query = "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/multiplicationWrong";
        computation.registerOperation(1, query);
      }
      counter += 1;
      // computation.registerOperation(0, query);
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
