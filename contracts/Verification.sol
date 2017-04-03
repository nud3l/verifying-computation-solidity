pragma solidity ^0.4.8;

contract Verification {
  struct Request {
    address requestor;
    string result;
  }

  address[] public service;
  mapping(address => uint) internal serviceIndex;
  mapping(bytes32 => Request) public request;

  function enableService() {
    uint index;
    service.push(msg.sender);
    index = (service.length - 1);
    serviceIndex[msg.sender] = index;
  }

  function disableService() {
    uint index;
    index = serviceIndex[msg.sender];
    delete service[index];
    serviceIndex[msg.sender] = 0;

    // update service array and index mapping
    if (index < (service.length - 1)) {
      uint next_index;
      uint this_index;
      this_index = index;
      next_index = this_index + 1;

      while (this_index < (service.length - 1)) {
        service[this_index] = service[next_index];
        serviceIndex[service[this_index]] = this_index;
        delete service[next_index];
        this_index++;
        next_index++;
      }
    }
  }

  function compute(string _val1, string _val2, uint _variable, uint _numVerifiers) payable {
    address[_numVerifiers] memory _verifiers;

    if (_numVerifiers > (service.length - 1) throw;

    for (uint i = 0; i < _numVerifiers; i++) {
      _verifiers[i] = service[i];
    }



  }

  function __callback() {

  }

}
