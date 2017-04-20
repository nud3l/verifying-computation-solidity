pragma solidity ^0.4.8;
import "./usingOraclize.sol";
import "./Verification.sol";

contract ComputationService is usingOraclize {
  struct Query {
    string URL;
    string JSON;
  }
  mapping(uint => Query) public computation;
  mapping(bytes32 => uint) public result;
  mapping(bytes32 => address) public request;
  mapping(address => bool) public arbiter;

  event newOraclizeQuery(string description);
  event newResult(string comp_result);
  event newOraclizeID(bytes32 ID);

  // constructor
  function ComputationService() {
    OAR = OraclizeAddrResolverI(0xafC1A0eDAF76076f2FDEAa968B85E3ef46fad79E);
  }

  function __callback(bytes32 _oraclizeID, string _result) {
    if (msg.sender != oraclize_cbAddress()) throw;
    newResult(_result);
    result[_oraclizeID] = parseInt(_result);

    // TODO: send result to verification contract
  }

  function compute(string _val1, string _val2, uint _variable) payable{
    if (!arbiter[msg.sender]) throw;
    bytes32 oraclizeID;

    Query memory _query = computation[_variable];
    _query.JSON = strConcat('\n{"val1": ', _val1, ', "val2": ', _val2, '}');

    newOraclizeQuery("Oraclize query was sent, standing by for the answer.");
    oraclizeID = oraclize_query(60, "URL", _query.URL, _query.JSON);

    // store address for specific request
    request[oraclizeID] = msg.sender;

    newOraclizeID(oraclizeID);
  }

  function register(uint _variable) payable {
    if (_variable == 0) {
      Query memory twoInt = Query("https://r98ro6hfj5.execute-api.eu-west-1.amazonaws.com/test/int", "");
      computation[0] = twoInt;
    }
  }

  function enableArbiter(address _verification) payable {
    arbiter[_verification] = true;
    Verification myArbiter = Verification(_verification);
    myArbiter.enableService();
  }

  function disableArbiter(address _verification) payable {
    arbiter[_verification] = false;
    Verification myArbiter = Verification(_verification);
    myArbiter.disableService();
  }

  function getResult(bytes32 _oraclizeID) constant returns (uint) {
    return result[_oraclizeID];
  }
}
