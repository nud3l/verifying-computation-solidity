var Arbiter = artifacts.require("Arbiter");
var ComputationServiceLocally = artifacts.require("ComputationServiceLocally");

contract('Experiments', function(accounts) {
  it("Full process: select 1 with 50% probability of cheaters", function(done) {
    // register computation[0] to correct and incorrect ones
    var arbiter, status, result, solver;
    var computation, query, desiredStatus;
    var gasUsed, time, finished, correct;

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
    }).then(function(){
      // console.log("Getting new status (desired: 400)");
      return arbiter.getStatus(accounts[0]);
    }).then(function(received){
      // console.log("Received new status (desired: 400)");
      status = received;
      assert.equal(status, 400, "Not all results are in.");
    }).catch(function(e){
      console.log(e);
    }).then(function(){
      // console.log("Comparing results");
      return arbiter.compareResults(accounts[0], {from:accounts[0], gas: 400000});
    }).then(function(){
      // console.log("Getting new status (desired: 700)");
      return arbiter.getStatus(accounts[0]);
    }).then(function(issue){
      // console.log("Received new status (desired: 700)");
      status = issue;
      assert.isAtLeast(status, 700, "Should have identified a mismatch");
    }).then(function(){
      // console.log("Requesting resolution");
      return arbiter.requestIndex({from:accounts[0], gas: 1000000});
    }).then(function(){
      // console.log("Getting new status (desired: 800)");
      return arbiter.getStatus(accounts[0]);
    }).then(function(resolution){
      // console.log("Received new status (desired: 800)");
      status = resolution;
      assert.isAtLeast(status, 800, "Dispute resolution not started.");
    }).then(function(){
      return arbiter.getCurrentSolver(accounts[0]);
    }).then(function(thisSolver){
      solver = thisSolver;
      console.log("Identified solver:" + solver);
      computation = ComputationServiceLocally.at(solver);
      return computation.correctComputation();
    }).then(function(thisComputation){
      console.log("The result of the computation is: " + thisComputation);
      if (thisComputation) {
        desiredStatus = 901;
      } else {
        desiredStatus = 902;
      }
      console.log("The desired status is: " + desiredStatus);
      return arbiter.getStatus(accounts[0]);
    }).then(function(solution){
      status = solution;
      if (desiredStatus == 901) {
        assert.equal(status, 901, "Dispute not resolved or did not detect that solver was right");
      } else {
        assert.equal(status, 902, "Dispute not resolved or did not detect that verifier was right");
      }
      // write results to CSV file
      done();
    });
  });
});
