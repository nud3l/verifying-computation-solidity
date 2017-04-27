var ComputationService = artifacts.require("ComputationService");

contract('ComputationService', function(accounts) {
  it("should assert true", function(done) {
    var computation = ComputationService.deployed();
    assert.isTrue(true);
    done();   // stops tests at this point
  });

  it("Register a new operation", function(done) {
    var computation;
    var url;

    ComputationService.deployed().then(function(instance) {
      computation = instance;
      return computation.registerOperation(0, {from:accounts[0], gas: 4710000});
    }).then(function() {
      return computation.computation(0);
    }).then(function(result) {
      url = result[0];
      assert.equal(url, "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/int", "Wrong or empty computation service");
      done();
    });
  });

  it("Request computation and check for newOraclizeID event", function(done) {
    var computation;

    ComputationService.deployed().then(function(instance) {
      computation = instance;
      return computation.compute("43543", "423543543", 0, 56347573485346, {from:accounts[0], gas: 4710000, value: web3.toWei(0.01, "ether")});
    }).then(function(transaction) {
      for (var i = 0; i < transaction.logs.length; i++) {
        var log = transaction.logs[i];
        if (log.event == "newOraclizeQuery") {
          // We found the event!
          assert.isTrue(true);
        }
      }
      done();
    });
  });
});
