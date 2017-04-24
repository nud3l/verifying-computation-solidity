pragma solidity ^0.4.8;
import "./usingOraclize.sol";
import "./AbstractArbiter.sol";

contract ComputationService is usingOraclize {
  struct Query {
    string URL;
    string JSON;
  }
  mapping(uint => Query) public computation;
  mapping(bytes32 => string) public result;
  mapping(bytes32 => address) public request;
  mapping(bytes32 => address) public origin;
  address public arbiter;

  event newOraclizeQuery(string description);
  event newResult(string comp_result);
  event newOraclizeID(bytes32 ID);

  function ComputationService() {
    OAR = OraclizeAddrResolverI(0xafC1A0eDAF76076f2FDEAa968B85E3ef46fad79E);
  }

  function __callback(bytes32 _oraclizeID, string _result) {
    if (msg.sender != oraclize_cbAddress()) throw;
    newResult(_result);
    result[_oraclizeID] = _result;

    // send result to arbiter contract
    AbstractArbiter myArbiter = AbstractArbiter(request[_oraclizeID]);
    myArbiter.receiveResults(_result, origin[_oraclizeID]);
  }

  function compute(string _val1, string _val2, uint _operation, address _origin) payable{
    if (!arbiter[msg.sender]) throw;
    bytes32 oraclizeID;

    Query memory _query = computation[_operation];
    _query.JSON = strConcat('\n{"val1": ', _val1, ', "val2": ', _val2, '}');

    newOraclizeQuery("Oraclize query was sent, standing by for the answer.");
    oraclizeID = oraclize_query(60, "URL", _query.URL, _query.JSON);

    // store address for specific request
    request[oraclizeID] = msg.sender;
    origin[oraclizeID] = _origin;

    newOraclizeID(oraclizeID);
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
    return result[_oraclizeID];
  }
}
