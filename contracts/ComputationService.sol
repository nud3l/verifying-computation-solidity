pragma solidity ^0.4.8;
import "./usingOraclize.sol";

contract ComputationService is usingOraclize {
  bytes32 result;
  string URL = "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/int";
  string JSON = '{"val1": 4, "val2": 7}';
  // constructor
  function ComputationService() {
    OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
  }

  function IntMultiplication() {
    result = oraclize_query("URL", URL, JSON);
  }

  function getResult() constant returns (bytes32) {
    return result;
  }
}
