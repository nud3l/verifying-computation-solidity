pragma solidity ^0.4.8;

contract AbstractArbiter {

  function enableService();

  function disableService();

  function requestComputation(string _input1, string _input2, uint _operation, uint _numVerifiers);

  function executeComputation() payable;

  function receiveResults(string _result, uint256 _computationId);

  function compareResults() returns (uint);

  function requestIndex();

  function receiveIndex(uint _index1, uint _index2, uint _operation, uint256 _computationId, bool _end);

  function setJudge(address _judge) payable;

  function stringToUint(string s) internal constant returns (uint result);

  function stringsEqual(string _a, string _b) internal constant returns (bool);

  function rand(uint min, uint max) internal constant returns (uint256);

}
