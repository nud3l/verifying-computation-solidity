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

  address judge;

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
  mapping(address => Request) public requests;

  address[] public service;
  mapping(address => uint) internal serviceIndex;

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
    address solver;
    address verifier;
    uint count = 0;
    uint check;

    // number of services for potential verifiers minus solver; maximum 6 verifiers
    if (_numVerifiers > (service.length - 1)) throw;
    if (_numVerifiers > 6) throw;

    Request memory _request;
    _request.input1 = _input1;
    _request.input2 = _input2;
    _request.operation = _operation;

    // select a random solver from the list of computation services
    solver = service[rand(0, service.length)];
    _request.solver = solver;

    // select random verifiers from the list of computation services
    while (count < _numVerifiers) {
      check = 0;
      verifier = service[rand(0, service.length)];
      if (verifier != solver) {
        for (uint i; i < count; i++) {
          if (verifier == _request.verifier[i]) {
            check = 1;
            break;
          }
        }
        if (check == 0) {
          _request.verifier[count] = verifier;
          count++;
        }
      }
    }

    // status 100: request is created, no solutions are provided
    _request.status = 100;

    requests[msg.sender] = _request;
  }

  function executeComputation() payable {
    // send computation request to the solver
    AbstractComputationService mySolver = AbstractComputationService(requests[msg.sender].solver);
    mySolver.compute(requests[msg.sender].input1, requests[msg.sender].input2, requests[msg.sender].operation, msg.sender);

    // send computation request to all verifiers
    for (uint i = 0; i < requests[msg.sender].verifier.length; i++) {
      AbstractComputationService myVerifier = AbstractComputationService(requests[msg.sender].verifier[i]);
        myVerifier.compute(requests[msg.sender].input1, requests[msg.sender].input2, requests[msg.sender].operation, msg.sender);
    }

    // status 200: request for computations send; awaiting results
    requests[msg.sender].status = 200;
  }

  function receiveResults(string _result, address _origin) {
    uint count = 0;
    // receive results from solvers and verifiers
    if (msg.sender == requests[_origin].solver) {
      requests[_origin].resultSolver = _result;
      count = 1;
    } else {
      for (uint i; i < requests[_origin].verifier.length; i++) {
        if (msg.sender == requests[_origin].verifier[i]) {
          requests[_origin].resultVerifier[i] = _result;
          count = 1;
          break;
        }
      }
    }

    // status 300 + n: 0 + n results are in (i.e 301 := 1 result is in)
    if (requests[_origin].status == 200) {
      requests[_origin].status = 300 + count;
    } else {
      requests[_origin].status += count;
    }

    if ((requests[_origin].status - 300) == (1 + requests[_origin].verifier.length)) {
      // status 400: all results are in
      requests[_origin].status = 400;
    }
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
  }

  function requestIndex() {
    // get all verifiers that disagreed with the solver
    uint[] memory verifierIndex;
    uint count = requests[msg.sender].status - 700;
    for (uint i = requests[msg.sender].verifier.length; i >= 0; i--) {
      if (count >= 2**i) {
        for (uint k = 0; k < verifierIndex.length; k ++) {

          verifierIndex.push(i);
        }
        count -= 2**i;
      }
    }

    // request an index in the result, which is different
    for (uint j = 0; verifierIndex.length; j++) {
      AbstractComputationService myVerifier = AbstractComputationService(requests[msg.sender].verifier[verifierIndex[j]]);
      myVerifier.provideIndex(requests[msg.sender].resultSolver, msg.sender);
    }

    // status 800: dispute resolution started
    requests[msg.sender].status = 800;
  }

  function receiveIndex(uint _index1, uint _index2, uint _operation, address _origin, bool _end) {
    // receives two coordinates
    uint result;
    bool solverCorrect;

    // check if solver and verifier value differ for given coordinates
    // this is just an integer check

    if (_end) {
      result = stringToUint(requests[_origin].resultSolver);
      Judge myJudge = Judge(judge);
      solverCorrect = myJudge.resolveDispute(_index1, _index2, result, _operation);
      if (solverCorrect) {
        // status 901: dispute resolved; solver correct
        requests[_origin].status = 901;
      } else {
        // status 902: dispute resolved; solver incorrect
        requests[_origin].status = 902;
      }
    }
    // TODO: matrix check
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
    if (_a.length != _b.length) return false;

    for (uint i = 0; i < a.length; i ++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  function rand(uint min, uint max) internal constant returns (uint256){
    uint256 blockValue = uint256(block.blockhash(block.number-1));
    uint256 random = uint256(uint256(blockValue)%(min+max));
    return random;
  }
}
