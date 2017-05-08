var present = require('present');
var fs = require("fs");
var csvWriter = require('csv-write-stream');
var writer = csvWriter();

var Arbiter = artifacts.require("Arbiter");
var ComputationServiceLocally = artifacts.require("ComputationServiceLocally");

var counter = 0;
var runs = 1000;
var startTime, endTime;

contract('Experiments', function(accounts) {
  it("Send ether to accounts[0]", function (done) {
    for (i = 1; i < 51; i++) {
      web3.eth.sendTransaction({ from: accounts[i], to: accounts[0], value: web3.toWei(95, "ether")});
    }
    var balance = web3.fromWei(web3.eth.getBalance(accounts[0]), "ether");
    assert.isAtLeast(balance, 4500, "Ether not transferred");
    done();
  });

  for (i = 0; i < runs; i++) {
    it("Select 1 verifier with 50% probability of cheaters", function(done) {
      verifyComputation(accounts, done, 1, counter, 0);
    });
    it("Select 2 verifier with 50% probability of cheaters", function(done) {
      verifyComputation(accounts, done, 2, counter, 1);
    });
    it("Select 3 verifier with 50% probability of cheaters", function(done) {
      verifyComputation(accounts, done, 3, counter, 1);
    });
    it("Select 4 verifier with 50% probability of cheaters", function(done) {
      verifyComputation(accounts, done, 4, counter, 1);
    });
    it("Select 5 verifier with 50% probability of cheaters", function(done) {
      verifyComputation(accounts, done, 5, counter, 1);
    });
    it("Select 6 verifier with 50% probability of cheaters", function(done) {
      verifyComputation(accounts, done, 6, counter, 2);
    });
  }
});

function verifyComputation(accounts, done, verifier, index, writeCode) {
  var arbiter, status, result, solver;
  var computation, query, desiredStatus;

  // experiment outputs
  var gasUsed, time, correct;

  Arbiter.deployed().then(function(instance){
    if ((index == 0) && (writeCode == 0)) {
      writer.pipe(fs.createWriteStream(('50_percent_cheaters.csv')));
    }
    startTime = present();
    gasUsed = 0;
    arbiter = instance;
    return new Promise(resolve => setTimeout(resolve, 50));
  }).then(function() {
    return arbiter.requestComputation("43543", "423543543", 0, verifier, {from:accounts[0], gas: 4710000});
  }).then(function(transaction) {
    gasUsed += transaction.receipt.gasUsed;
    return arbiter.getStatus(accounts[0]);
  }).then(function(result) {
    status = result;
    assert.equal(status, 100, "Computation request creation failed");
  }).then(function(){
    return arbiter.getCurrentSolver(accounts[0]);
  }).then(function(thisSolver){
    solver = thisSolver;
    // console.log("Identified solver:" + solver);
    computation = ComputationServiceLocally.at(solver);
    return computation.correctComputation();
  }).then(function(thisComputation){
    correct = thisComputation;
    // console.log("The result of the computation is: " + correct);
    return arbiter.executeComputation({from:accounts[0], gas: 4712388, value: web3.toWei(0.05, "ether")});
  }).then(function(transaction) {
    gasUsed += transaction.receipt.gasUsed;
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
  }).then(function(transaction){
    gasUsed += transaction.receipt.gasUsed;
    // console.log("Getting new status (desired: 700)");
    return arbiter.getStatus(accounts[0]);
  }).then(function(issue){
    // console.log("Received new status (desired: 700)");
    status = issue;
    // console.log(status);
    if (status != 500) {
      return arbiter.requestIndex({from:accounts[0], gas: 1000000});
    }
  }).then(function(transaction){
    if (transaction) {
      gasUsed += transaction.receipt.gasUsed;
    }
    // console.log("Getting new status (desired: 800)");
    return arbiter.getStatus(accounts[0]);
  }).then(function(resolution){
    // console.log("Received new status (desired: 800)");
    status = resolution;
    if (status != 500) {
      assert.isAtLeast(status, 800, "Dispute resolution not started.");
    }
  }).then(function(){
    if (status != 500) {
      if (correct) {
        desiredStatus = 901;
      } else {
        desiredStatus = 902;
      }
      // console.log("The desired status is: " + desiredStatus);
    }
    return arbiter.getStatus(accounts[0]);
  }).then(function(solution){
    status = solution;
    if (status != 500) {
      if (desiredStatus == 901) {
        assert.equal(status, 901, "Dispute not resolved or did not detect that solver was right");
      } else {
        assert.equal(status, 902, "Dispute not resolved or did not detect that verifier was right");
      }
    }
  }).then(function(){
    // write results to CSV file
    endTime = present();
    time = endTime - startTime;
    writer.write({Run: index, Time: time, Status: status, Solver: correct, Gas: gasUsed, Verifiers: verifier});

    if (writeCode == 2) {
      counter++;
    }

    if ((index == (runs - 1)) && (writeCode == 2)) {
      writer.end();
    }
    done()
  });
}
