pragma solidity ^0.4.8;

contract Arbiter {
  struct Request {
    address requestor;
    uint input1;
    uint input2;
    uint8 operation;
    uint result;
    uint8 status;
    bool finished;
  }

  address[] public service;
  mapping(address => uint) internal serviceIndex;

  uint256[] public requestId;
  mapping(address => uint256) public TaskRequestId;
  mapping(uint256 => Request) public request;

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
        delete service[next_index];
        this_index++;
        next_index++;
      }
    }
  }

  function requestComputation(uint _input1, uint _input2, uint8 _operation) {
    id = rand(0, 2**256);
    requestId.push(id);

    Request memory _request = Request(
        msg.sender,
        _input1,
        _input2,
        _operation,
        0,
        0,
        0
    );
    request[id] = _request;

    TaskRequestId[msg.sender] = id;
  }

  function compute(string _val1, string _val2, uint _variable, uint _numVerifiers) payable {
    address[_numVerifiers] memory _verifiers;

    if (_numVerifiers > (service.length - 1) throw;



    for (uint i = 0; i < _numVerifiers; i++) {
      _verifiers[i] = service[i];
    }
  }


  function rand(uint min, uint max) constant returns (uint256){
    uint256 blockValue = uint256(block.blockhash(block.number-1));
    uint256 random = uint256(uint256(blockValue)%(min+max));
    return random
  }

  function __callback() {

  }

}
