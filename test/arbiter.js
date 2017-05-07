var Arbiter = artifacts.require("Arbiter");
var ComputationService = artifacts.require("ComputationService");

contract('Arbiter', function(accounts) {
  xit("Contract is deployed", function(done) {
    var arbiter = Arbiter.deployed();
    assert.isTrue(true);
    done();   // stops tests at this point
  });

  xit("Request a new computation", function(done) {
    var arbiter;
    var status;

    Arbiter.deployed().then(function(instance) {
      arbiter = instance;
      return arbiter.requestComputation("43543", "423543543", 0, 2, {from:accounts[0], gas: 4710000});
    }).then(function() {
      return arbiter.getStatus(accounts[0]);
    }).then(function(result) {
      status = result;
      assert.equal(status, 100, "Computation request creation failed");
      done();
    });
  });

  xit("Request and execute computation and receive result: 1 verifier", function(done) {
    var arbiter, status, result;

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

  xit("Full process: 1 cheater, 2 honest computation services", function(done) {
    // register computation[0] to correct and incorrect ones
    var arbiter, status, result, solver;
    var computation, url, query, address;

    ComputationService.deployed().then(function(instance) {
      computation = instance;
      query = "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/multiplicationWrong"
      return computation.registerOperation(0, query, {from:accounts[0], gas: 4710000});
    }).then(function() {
      return computation.computation(0);
    }).then(function(result) {
      url = result[0];
      assert.equal(url, "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/multiplicationWrong", "Wrong or empty computation service");
      return computation.address;
    }).then(function(thisAddress){
      address = thisAddress;
      return Arbiter.deployed();
    }).then(function(instance) {
      arbiter = instance;
      return arbiter.requestComputation("43543", "423543543", 0, 2, {from:accounts[0], gas: 4710000});
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
      return new Promise(resolve => setTimeout(resolve, 100000));
    }).then(function(){
      return arbiter.getStatus(accounts[0]);
    }).then(function(received){
      status = received;
      assert.equal(status, 400, "Not all results are in.");
    }).catch(function(e){
      console.log(e);
    }).then(function(){
      return arbiter.compareResults(accounts[0], {from:accounts[0], gas: 200000});
    }).then(function(){
      return arbiter.getStatus(accounts[0]);
    }).then(function(issue){
      status = issue;
      assert.isAtLeast(status, 700, "Should have identified a mismatch");
      done();
    });
    // .then(function(){
    //   arbiter.requestIndex({from:accounts[0], gas: 100000});
    //   return arbiter.getStatus(accounts[0]);
    // }).then(function(resolution){
    //   status = resolution;
    //   assert.equal(status, 800, "Dispute resolution not started.");
    // }).then(function(){
    //   return new Promise(resolve => setTimeout(resolve, 2000));
    // }).then(function(){
    //   return arbiter.getCurrentSolver(accounts[0]);
    // }).then(function(thisSolver){
    //   solver = thisSolver;
    //   return arbiter.getStatus(accounts[0]);
    // }).then(function(solution){
    //   status = solution;
    //   if (solver = address) {
    //     assert.equal(status, 901, "Dispute not resolved or did not detect that solver was wrong");
    //   } else {
    //     assert.equal(status, 902, "Dispute not resolved or did not detect that verifier was wrong");
    //   }
    //   done();
    // });
  });
});
