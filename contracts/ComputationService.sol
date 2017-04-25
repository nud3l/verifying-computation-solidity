pragma solidity ^0.4.8;
import "./usingOraclize.sol";
import "./AbstractArbiter.sol";

contract ComputationService is usingOraclize {
  struct Query {
    string URL;
    string JSON;
  }
  mapping(uint => Query) public computation;

  struct Request {
    string input1;
    string input2;
    uint operation;
    uint256 computationId;
    string result;
    address arbiter;
  }

  mapping(uint256 => bytes32) public requestId;
  mapping(bytes32 => Request) public requestOraclize;

  address public arbiter;

  event newOraclizeQuery(string description);
  event newResult(string comp_result);
  event newOraclizeID(bytes32 ID);

  function ComputationService() {
    OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
  }

  function __callback(bytes32 _oraclizeID, string _result) {
    if (msg.sender != oraclize_cbAddress()) throw;
    newResult(_result);

    Request memory _request = requestOraclize[_oraclizeID];
    _request.result = _result;

    requestOraclize[_oraclizeID] = _request;

    // send result to arbiter contract
    AbstractArbiter myArbiter = AbstractArbiter(requestOraclize[_oraclizeID].arbiter);
    myArbiter.receiveResults(_result, requestOraclize[_oraclizeID].computationId);
  }

  function compute(string _val1, string _val2, uint _operation, uint256 _computationId) payable {
    bytes32 oraclizeID;

    Query memory _query = computation[_operation];
    _query.JSON = strConcat('\n{"val1": ', _val1, ', "val2": ', _val2, '}');

    newOraclizeQuery("Oraclize query was sent, standing by for the answer.");
    oraclizeID = oraclize_query(60, "URL", _query.URL, _query.JSON);

    // store address for specific request
    Request memory _request;
    _request.input1 = _val1;
    _request.input2 = _val2;
    _request.operation = _operation;
    _request.computationId = _computationId;
    _request.arbiter = msg.sender;

    requestId[_computationId] = oraclizeID;
    requestOraclize[oraclizeID] = _request;

    newOraclizeID(oraclizeID);
  }

  function provideIndex(string _resultSolver, uint _computationId) {
    // this is for two intergers: always returns 0 and 1 for two two intergers
    Request memory _request = requestOraclize[requestId[_computationId]];

    AbstractArbiter myArbiter = AbstractArbiter(msg.sender);
    myArbiter.receiveIndex(0, 1, _request.operation, _request.computationId, true);
  }

  function registerOperation(uint _operation) payable {
    // operation 0: add two integers
    if (_operation == 0) {
      Query memory twoInt = Query("https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/int", "");
      computation[0] = twoInt;
    }
  }

  function enableArbiter(address _arbiterAddress) payable {
    arbiter = _arbiterAddress;
    AbstractArbiter myArbiter = AbstractArbiter(_arbiterAddress);
    myArbiter.enableService();
  }

  function disableArbiter(address _arbiterAddress) payable {
    delete arbiter;
    AbstractArbiter myArbiter = AbstractArbiter(_arbiterAddress);
    myArbiter.disableService();
  }

  function getResult(bytes32 _oraclizeID) constant returns (string) {
    return requestOraclize[_oraclizeID].result;
  }
}
