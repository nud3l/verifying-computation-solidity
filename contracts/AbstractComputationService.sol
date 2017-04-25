pragma solidity ^0.4.8;

contract AbstractComputationService {
  function __callback(bytes32 _oraclizeID, string _result);

  function compute(string _val1, string _val2, uint _operation, uint256 _computationId) payable;

  function provideIndex(string _resultSolver, uint _computationId);

  function registerOperation(uint _operation) payable;

  function enableArbiter(address _arbiterAddress) payable;

  function disableArbiter(address _arbiterAddress) payable;

  function getResult(bytes32 _oraclizeID) constant returns (string);
}
