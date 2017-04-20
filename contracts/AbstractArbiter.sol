pragma solidity ^0.4.8;

contract Arbiter {
  function enableService();

  function disableService();

  function requestComputation(string _input1, string _input2, uint _operation);

  function executeComputation(uint _numVerifiers) payable;

  function rand(uint min, uint max) constant returns (uint256);

  function __callback();
}
