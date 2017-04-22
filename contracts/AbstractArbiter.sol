pragma solidity ^0.4.8;

contract AbstractArbiter {
  function enableService();

  function disableService();

  function requestComputation(string _input1, string _input2, uint _operation, uint _numVerifiers);

  function executeComputation() payable;

  function receiveResults(string _result, address _origin);

  function compareResults() returns (uint);

  function requestIndex();

  function receiveIndex(uint _index1, uint _index2, uint _operation, address _origin, bool _end);

}
