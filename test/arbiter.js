var Arbiter = artifacts.require("Arbiter");

contract('Arbiter', function(accounts) {
  it("Contract is deployed", function(done) {
    var arbiter = Arbiter.deployed();
    assert.isTrue(true);
    done();   // stops tests at this point
  });

  it("Request a new computation", function(done) {
    var arbiter;
    var status;

    Arbiter.deployed().then(function(instance) {
      arbiter = instance;
      return arbiter.requestComputation("43543", "423543543", 0, 3, {from:accounts[0], gas: 4710000});
    }).then(function() {
      return arbiter.getStatus(accounts[0]);
    }).then(function(result) {
      status = result;
      assert.equal(status, 100, "Computation request creation failed");
      done();
    });
  });
});
