pragma solidity ^0.4.8;
import "./usingOraclize.sol";

contract ComputationService is usingOraclize {
  uint public result;
  bytes32 public oraclizeID;

  event newOraclizeQuery(string description);
  event newResult(string comp_result);

  string URL = "https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/int";
  string JSON = '{"val1": 4, "val2": 9}';
  // constructor
  function ComputationService() {
    OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
  }

  function __callback(bytes32 _oraclizeID, string _result) {
    if (msg.sender != oraclize_cbAddress()) throw;
    newResult(_result);
    result = parseInt(_result);
  }

  function multiply() payable {
    newOraclizeQuery("Oraclize query was sent, standing by for the answer.");
    oraclize_query(60, "URL", URL, JSON);
  }

  function getResult() constant returns (uint) {
    return result;
  }
}
