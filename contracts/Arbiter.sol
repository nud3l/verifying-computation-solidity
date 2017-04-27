pragma solidity ^0.4.8;
import "./AbstractComputationService.sol";
import "./Judge.sol";

contract Arbiter {
  // Requests can have different status with a default of 0
  // status 100: request is created, no solutions are provided
  // status 200: request for computations send; awaiting results
  // status 300 + n: 0 + n results are in (i.e 301 := 1 result is in)
  // status 400: all results are in
  // status 500: solver and validators match
  // status 600: result send to requester
  // status 700 + n: solver and validators mismatch with n binary encoding of mismatches
  // e.g. status 729: 700 + 16 + 8 + 4 + 1 => verfier 0, 2, 3, 4 indicated a mismatch
  // status 800: dispute resolution started
  // status 801: dispute resolution state 1
  // status 901: dispute resolved; solver correct
  // status 902: dispute resolved; solver incorrect

  address public judge;

  struct Request {
    string input1;
    string input2;
    uint operation;
    uint256 computationId;
    address solver;
    address[] verifier;
    string resultSolver;
    string[6] resultVerifier;
    uint status;
    bool finished;
  }
  mapping(address => Request) public requests;
  mapping(uint256 => address) public computation;

  address[] public service;
  mapping(address => uint) internal serviceIndex;

  event newRequest(uint newRequest);
  event solverFound(address solverFound);
  event verifierFound(address verifierFound);
  event StatusChange(uint status_code);

  // event thisIndex(uint thisIndex);
  // event step(uint thisStep);
  // event setLength(uint setLength);

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

  function requestComputation(string _input1, string _input2, uint _operation, uint _numVerifiers) {
    // testEvent("Request computation started");
    address solver;
    address verifier;
    uint count = 0;
    uint check;
    uint index;
    uint length = service.length;
    address[] memory remainingService = new address[](length);

    // number of services for potential verifiers minus solver; maximum 6 verifiers
    if (_numVerifiers > (service.length - 1)) throw;
    if (_numVerifiers > 6) throw;

    remainingService = service;

    requests[msg.sender].input1 = _input1;
    requests[msg.sender].input2 = _input2;
    requests[msg.sender].operation = _operation;
    requests[msg.sender].computationId = rand(0, 2**64);

    newRequest(requests[msg.sender].computationId);

    // select a random solver from the list of computation services
    index = rand(0, length - 1);
    solver = remainingService[index];
    requests[msg.sender].solver = solver;
    solverFound(solver);

    for (uint i = index; i < length - 1; i++) {
      remainingService[i] = remainingService[i + 1];
    }
    // length-- is a workaround since memory arrays can NOT be resized
    length--;

    // select random verifiers from the list of computation services
    for (uint j = 0; j < _numVerifiers; j++) {
      index = rand(0, length - 1);
      verifier = remainingService[index];
      requests[msg.sender].verifier.push(verifier);
      verifierFound(verifier);

      for (uint k = index; k < length - 1; k++) {
        remainingService[k] = remainingService[k + 1];
      }
      length--;
    }

    // status 100: request is created, no solutions are provided
    requests[msg.sender].status = 100;
    StatusChange(requests[msg.sender].status);
  }

  function executeComputation() payable {
    // send computation request to the solver
    AbstractComputationService mySolver = AbstractComputationService(requests[msg.sender].solver);
    mySolver.compute(requests[msg.sender].input1, requests[msg.sender].input2, requests[msg.sender].operation, requests[msg.sender].computationId);

    // send computation request to all verifiers
    for (uint i = 0; i < requests[msg.sender].verifier.length; i++) {
      AbstractComputationService myVerifier = AbstractComputationService(requests[msg.sender].verifier[i]);
        myVerifier.compute(requests[msg.sender].input1, requests[msg.sender].input2, requests[msg.sender].operation, requests[msg.sender].computationId);
    }

    // status 200: request for computations send; awaiting results
    requests[msg.sender].status = 200;
    StatusChange(requests[msg.sender].status);
  }

  function receiveResults(string _result, uint256 _computationId) {
    uint count = 0;
    // receive results from solvers and verifiers
    if (msg.sender == requests[computation[_computationId]].solver) {
      requests[computation[_computationId]].resultSolver = _result;
      count = 1;
    } else {
      for (uint i; i < requests[computation[_computationId]].verifier.length; i++) {
        if (msg.sender == requests[computation[_computationId]].verifier[i]) {
          requests[computation[_computationId]].resultVerifier[i] = _result;
          count = 1;
          break;
        }
      }
    }

    // status 300 + n: 0 + n results are in (i.e 301 := 1 result is in)
    if (requests[computation[_computationId]].status == 200) {
      requests[computation[_computationId]].status = 300 + count;
    } else {
      requests[computation[_computationId]].status += count;
    }

    if ((requests[computation[_computationId]].status - 300) == (1 + requests[computation[_computationId]].verifier.length)) {
      // status 400: all results are in
      requests[computation[_computationId]].status = 400;
    }

    StatusChange(requests[computation[_computationId]].status);
  }

  function compareResults() returns (uint) {
    if (requests[msg.sender].status != 400) throw;

    uint count = 0;

    for (uint i; i < requests[msg.sender].verifier.length; i++) {
      if (!(stringsEqual(requests[msg.sender].resultSolver,requests[msg.sender].resultVerifier[i]))) {
        count += 2**i;
      }
    }

    if (count == 0) {
      // status 500: solver and validators match
      requests[msg.sender].status = 500;
    } else {
      // status 700: solver and validators mismatch
      requests[msg.sender].status = 700 + count;
    }

    return requests[msg.sender].status;
    StatusChange(requests[msg.sender].status);
  }

  function requestIndex() {
    // get all verifiers that disagreed with the solver
    uint[] memory verifierIndex;
    uint count = requests[msg.sender].status - 700;
    uint insert;

    for (uint i = requests[msg.sender].verifier.length - 1; i >= 0; i--) {
      if (count >= 2**i) {
        insert = verifierIndex.length - 1;
        verifierIndex[insert] = i;
        count -= 2**i;
      }
    }

    // request an index in the result, which is different
    for (uint j = 0; j < verifierIndex.length; j++) {
      AbstractComputationService myVerifier = AbstractComputationService(requests[msg.sender].verifier[verifierIndex[j]]);
      myVerifier.provideIndex(requests[msg.sender].resultSolver, requests[msg.sender].computationId);
    }

    // status 800: dispute resolution started
    requests[msg.sender].status = 800;
    StatusChange(requests[msg.sender].status);
  }

  function receiveIndex(uint _index1, uint _index2, uint _operation, uint256 _computationId, bool _end) {
    // receives two coordinates
    uint result;
    bool solverCorrect;

    // check if solver and verifier value differ for given coordinates
    // this is just an integer check

    if (_end) {
      result = stringToUint(requests[computation[_computationId]].resultSolver);
      Judge myJudge = Judge(judge);
      solverCorrect = myJudge.resolveDispute(_index1, _index2, result, _operation);
      if (solverCorrect) {
        // status 901: dispute resolved; solver correct
        requests[computation[_computationId]].status = 901;
      } else {
        // status 902: dispute resolved; solver incorrect
        requests[computation[_computationId]].status = 902;
      }
    }
    StatusChange(requests[computation[_computationId]].status);
    // TODO: matrix check
  }

  function setJudge(address _judge) {
    judge = _judge;
  }

  function getStatus(address _requester) constant returns (uint status) {
    status = requests[_requester].status;
  }

  function stringToUint(string s) internal constant returns (uint result) {
    bytes memory b = bytes(s);
    uint i;
    result = 0;
    for (i = 0; i < b.length; i++) {
      uint c = uint(b[i]);
      if (c >= 48 && c <= 57) {
          result = result * 10 + (c - 48);
      }
    }
  }

  function stringsEqual(string _a, string _b) internal constant returns (bool) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    if (a.length != b.length) return false;

    for (uint i = 0; i < a.length; i ++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  function rand(uint min, uint max) internal constant returns (uint256 random) {
    uint256 blockValue = uint256(block.blockhash(block.number-1));
    random = uint256(uint256(blockValue)%(min+max));
    return random;
  }
}
