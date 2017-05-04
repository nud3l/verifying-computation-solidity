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
    address solver;
    address[] verifier;
    string resultSolver;
    string[6] resultVerifier;
    uint status;
    bool finished;
  }

  mapping(uint256 => Request) public requests;
  mapping(address => uint256) public currentRequest;

  address[] public service;
  mapping(address => uint) internal serviceIndex;

  event newRequest(uint newRequest);
  event solverFound(address solverFound);
  event verifierFound(address verifierFound);
  event StatusChange(uint status_code);
  event newExecution(uint newExecution);
  event solverExecution(address solverExecution);
  event verifierExecution(address verifierExecution);

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
    uint256 computationId;
    uint count = 0;
    uint check;
    uint index;
    uint length = service.length;
    address[] memory remainingService = new address[](length);

    // number of services for potential verifiers minus solver; maximum 6 verifiers
    if (_numVerifiers > (service.length - 1)) throw;
    if (_numVerifiers > 6) throw;

    remainingService = service;

    computationId = rand(0, 2**64);

    currentRequest[msg.sender] = computationId;

    requests[computationId].input1 = _input1;
    requests[computationId].input2 = _input2;
    requests[computationId].operation = _operation;

    newRequest(computationId);

    // select a random solver from the list of computation services
    index = rand(0, length - 1);
    solver = remainingService[index];
    requests[computationId].solver = solver;
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
      requests[computationId].verifier.push(verifier);
      verifierFound(verifier);

      for (uint k = index; k < length - 1; k++) {
        remainingService[k] = remainingService[k + 1];
      }
      length--;
    }

    // status 100: request is created, no solutions are provided
    requests[computationId].status = 100;
    StatusChange(requests[computationId].status);
  }

  function executeComputation() payable {
    uint256 computationId = currentRequest[msg.sender];

    newExecution(computationId);
    // send computation request to the solver
    AbstractComputationService mySolver = AbstractComputationService(requests[computationId].solver);
    mySolver.compute.value(10000000000000000).gas(500000)(requests[computationId].input1, requests[computationId].input2, requests[computationId].operation, computationId);
    solverExecution(requests[computationId].solver);

    // send computation request to all verifiers
    for (uint i = 0; i < requests[computationId].verifier.length; i++) {
      AbstractComputationService myVerifier = AbstractComputationService(requests[computationId].verifier[i]);
      myVerifier.compute.value(10000000000000000).gas(500000)(requests[computationId].input1, requests[computationId].input2, requests[computationId].operation, computationId);
      verifierExecution(requests[computationId].verifier[i]);
    }

    // status 200: request for computations send; awaiting results
    requests[computationId].status = 200;
    StatusChange(requests[computationId].status);
  }

  function receiveResults(string _result, uint256 _computationId) {
    uint count = 0;
    // receive results from solvers and verifiers
    if (msg.sender == requests[_computationId].solver) {
      requests[_computationId].resultSolver = _result;
      count = 1;
    } else {
      for (uint i; i < requests[_computationId].verifier.length; i++) {
        if (msg.sender == requests[_computationId].verifier[i]) {
          requests[_computationId].resultVerifier[i] = _result;
          count = 1;
          break;
        }
      }
    }

    // status 300 + n: 0 + n results are in (i.e 301 := 1 result is in)
    if (requests[_computationId].status == 200) {
      requests[_computationId].status = 300 + count;
    } else {
      requests[_computationId].status += count;
    }

    if ((requests[_computationId].status - 300) == (1 + requests[_computationId].verifier.length)) {
      // status 400: all results are in
      requests[_computationId].status = 400;
    }

    StatusChange(requests[_computationId].status);
  }

  function compareResults() returns (uint) {
    uint256 computationId = currentRequest[msg.sender];

    if (requests[computationId].status != 400) throw;

    uint count = 0;

    for (uint i; i < requests[computationId].verifier.length; i++) {
      if (!(stringsEqual(requests[computationId].resultSolver,requests[computationId].resultVerifier[i]))) {
        count += 2**i;
      }
    }

    if (count == 0) {
      // status 500: solver and validators match
      requests[computationId].status = 500;
    } else {
      // status 700: solver and validators mismatch
      requests[computationId].status = 700 + count;
    }

    return requests[computationId].status;
    StatusChange(requests[computationId].status);
  }

  function requestIndex() {
    uint256 computationId = currentRequest[msg.sender];

    // get all verifiers that disagreed with the solver
    uint[] memory verifierIndex;
    uint count = requests[computationId].status - 700;
    uint insert;

    for (uint i = requests[computationId].verifier.length - 1; i >= 0; i--) {
      if (count >= 2**i) {
        insert = verifierIndex.length - 1;
        verifierIndex[insert] = i;
        count -= 2**i;
      }
    }

    // request an index in the result, which is different
    for (uint j = 0; j < verifierIndex.length; j++) {
      AbstractComputationService myVerifier = AbstractComputationService(requests[computationId].verifier[verifierIndex[j]]);
      myVerifier.provideIndex(requests[computationId].resultSolver, computationId);
    }

    // status 800: dispute resolution started
    requests[computationId].status = 800;
    StatusChange(requests[computationId].status);
  }

  function receiveIndex(uint _index1, uint _index2, uint _operation, uint256 _computationId, bool _end) {
    // receives two coordinates
    uint result;
    bool solverCorrect;

    // check if solver and verifier value differ for given coordinates
    // this is just an integer check

    if (_end) {
      result = stringToUint(requests[_computationId].resultSolver);
      Judge myJudge = Judge(judge);
      solverCorrect = myJudge.resolveDispute(_index1, _index2, result, _operation);
      if (solverCorrect) {
        // status 901: dispute resolved; solver correct
        requests[_computationId].status = 901;
      } else {
        // status 902: dispute resolved; solver incorrect
        requests[_computationId].status = 902;
      }
    }
    StatusChange(requests[_computationId].status);
    // TODO: matrix check
  }

  function setJudge(address _judge) {
    judge = _judge;
  }

  function getStatus(address _requester) constant returns (uint status) {
    status = requests[currentRequest[_requester]].status;
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
