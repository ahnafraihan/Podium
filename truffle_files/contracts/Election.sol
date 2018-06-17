pragma solidity ^0.4.23;

import "./Owned.sol";

contract Election {
    //TODO: Candidate struct
    struct Candidate {
		String name;
		String party;
		uint votes;
    }
    //TODO: Voter struct
    //TODO: addCandidate (Owned only) function
    //TODO: viewCandidates function
    //TODO: vote function (electionActive only)
    //TODO: startElection function takes duration (Owned only)
    //TODO: checkRemainingTime
    //TODO: checkResults (electionComplete only)
    //TODO: createCandidate (Owned only)
    //TODO: register (unique, no address should be able to register twice)
}
