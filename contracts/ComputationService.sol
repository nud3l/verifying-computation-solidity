pragma solidity ^0.4.8;
import "./usingOraclize.sol";
import "./Verification.sol"

contract ComputationService is usingOraclize {
  struct Query {
    string URL;
    string JSON;
  }
  mapping(uint => Query) public computation;
  mapping(bytes32 => uint) public result;
  mapping(bytes32 => address) public request;
  mapping(address => bool) public verifier;

  event newOraclizeQuery(string description);
  event newResult(string comp_result);
  event newOraclizeID(bytes32 ID);

  // constructor
  function ComputationService() {
    OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
  }

  function __callback(bytes32 _oraclizeID, string _result) {
    if (msg.sender != oraclize_cbAddress()) throw;
    newResult(_result);
    result[_oraclizeID] = parseInt(_result);

    // TODO: send result to verification contract
  }

  function compute(string _val1, string _val2, uint _variable) payable{
    if (!verifier[msg.sender]) throw;
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

  function enableVerifier(address _verification) payable {
    verifier[_verification] = true;
    Verification myVerifier = Verification(_verification);
    myVerifier.enableService();
  }

  function disableVerifier(address _verification) payable {
    verifier[_verification] = false;
    Verification myVerifier = Verification(_verification);
    myVerifier.disableService();
  }

  function getResult(bytes32 _oraclizeID) constant returns (uint) {
    return result[_oraclizeID];
  }
}
