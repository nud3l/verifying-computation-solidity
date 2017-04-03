pragma solidity ^0.4.8;

contract Resolver {
  struct Request {
    uint input1;
    uint input2;
    uint result;
    uint8 operation;
  }

  mapping(bytes32 => Request) requestMapping;

  address[] public verifiers;

  function createRequest(bytes32 _identifier, uint _input1, uint _input2, uint _result, uint8 _operation) payable {
    Request memory _request;
    _request.input1 = _input1;
    _request.input2 = _input2;
    _request.result = _result;
    _request.operation = _operation;

    requestMapping[_identifier] = _request;
  }

  function resolveDispute(bytes32 _identifier) returns (bool check) {
    uint input1 = requestMapping[_identifier].input1;
    uint input2 = requestMapping[_identifier].input2;
    uint result = requestMapping[_identifier].result;
    uint8 operation = requestMapping[_identifier].operation;
    uint check_result;

    if (operation == 0) {
      check_result = input1 + input2;
      if (check_result == result) check = true;
    }
    else if (operation == 1) {
      check_result = input1 - input2;
      if (check_result == result) check = true;
    }
    else if (operation== 2) {
      check_result = input1 * input2;
      if (check_result == result) check = true;
    }
    return check;
  }
}
