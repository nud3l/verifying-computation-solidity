// Specifically request an abstraction for MetaCoin
var ComputationService = artifacts.require("ComputationService");

contract('ComputationService', function(accounts) {
  it("should store 28 as result", function() {
    var meta;
    var computation;

    return ComputationService.deployed().then(function(instance) {
      meta = instance;
      return meta.IntMultiplication.call(accounts[0]);
    }).then(function() {
      return meta.getResult.call(accounts[0]);
    }).then(function(result) {
      computation = result;
      assert.equal(computation, 28, "The result wasn't 28");
    });
  });
});
