pragma solidity ^0.4.8;

contract Judge {
  function resolveDispute(uint _input1, uint _input2, uint _result, uint8 _operation) returns (bool check) {
    uint check_result;

    if (operation == 0) {
      check_result = _input1 + _input2;
      if (check_result == _result) check = true;
    }
    else if (operation == 1) {
      check_result = _input1 - _input2;
      if (check_result == _result) check = true;
    }
    else if (operation== 2) {
      check_result = _input1 * _input2;
      if (check_result == _result) check = true;
    }
    return check;
  }
}
