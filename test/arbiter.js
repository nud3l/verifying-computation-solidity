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

  it("Request and execute computation and receive result: 1 verifier", function(done) {
    var arbiter;
    var status;
    var result;

    Arbiter.deployed().then(function(instance) {
      arbiter = instance;
      return arbiter.requestComputation("43543", "423543543", 0, 1, {from:accounts[0], gas: 4710000});
    }).then(function() {
      return arbiter.getStatus(accounts[0]);
    }).then(function(result) {
      status = result;
      assert.equal(status, 100, "Computation request creation failed");
      return arbiter.executeComputation({from:accounts[0], gas: 4712388, value: web3.toWei(0.10, "ether")});
    }).then(function() {
      return arbiter.getStatus(accounts[0]);
    }).then(function(result) {
      status = result;
      assert.equal(status, 200, "Computation execution failed");
    }).then(function(){
      return new Promise(resolve => setTimeout(resolve, 200000));
    }).then(function(){
      return arbiter.getStatus(accounts[0]);
    }).then(function(received){
      status = received;
      assert.equal(status, 400, "Not all results are in.");
    }).then(function(){
      arbiter.compareResults(accounts[0], {from:accounts[0], gas: 100000});
      return arbiter.getStatus(accounts[0]);
    }).then(function(resolved){
      status = resolved;
      assert.equal(status, 500, "Results don't match");
      done();
    });
  });
});
