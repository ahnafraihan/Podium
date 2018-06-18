pragma solidity ^0.4.23;

// Utility contract for ownership functionality.
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

//TODO: hashing definely should be in here somewhere this is not secure in the slightest
contract ElectionPlatform is Owned {
    Election[] elections;                                   // store elections

    Voter[] public voters;                                  // hold voters
    mapping (address => uint) voterID;

    //hold info about election
    struct Election {
        string name;
        Candidate[] candidates;                              // hold candidates
        mapping (address => uint) candidateID;

        uint startDate;                                      // time of election start
        bool hasBeenStarted;                                 // used so election can only be started once
        uint endDate;                                        // time election ends
        bool finished;                                      // has winner been computed

        Candidate winner;                                    // hold winner of election
    }

    // hold info about candidates
    struct Candidate {
        string name;
        string party;
        mapping (address => uint) supporters;
        uint votes;
    }

    // hold info about registered voters
    struct Voter {
        string name;
        string party;
        bool voted;
    }

    modifier onlyVoters {
        require(voterID[msg.sender] != 0);
        _;
    }

    constructor() Owned() public {
        //add 0 index empty voter
        addVoter(0, "", "");
    }

    //create a candidate
    function addCandidate(uint targetElection, address targetCandidate, string name, string party) onlyOwner public {
        //pull election
        Election storage e = elections[targetElection];

        //check if candidate already exists
        uint id = e.candidateID[targetCandidate];

        //if doesn't exist create
        if(id == 0) {
            e.candidateID[targetCandidate] = e.candidates.length;
            id = e.candidates.length++;
        }

        // create or update struct info
        Candidate storage c = e.candidates[id];
        c.name = name;
        c.party = party;
    }

    //create a voter
    function addVoter(address targetVoter, string name, string party) onlyOwner public {
        //check if candidate already exists
        uint id = voterID[targetVoter];

        //if doesn't exist create
        if(id == 0) {
            voterID[targetVoter] = voters.length;
            id = voters.length++;
        }

        // create or update struct info
        Voter storage v = voters[id];
        v.name = name;
        v.party = party;
    }

    function addElection(string name) onlyOwner public {
        uint id = elections.length++;
        Election storage e = elections[id];

        e.name = name;

        // add 0 index empty candidate
        addCandidate(id, 0, "", "");


    }

    //TODO: for front end, need getters for voter and candidate arrays

    //allow owner to start election, gives a duration and sets the boolean
    function startElection(uint targetElection, uint durationInMinutes) onlyOwner public {
        //pull election
        Election storage e = elections[targetElection];

        //check if has been started
        require(!e.hasBeenStarted, "election has already been started");

        e.hasBeenStarted = true;
        e.startDate = now;
        e.endDate = e.startDate + durationInMinutes * 1 minutes;
    }

    //give the remaining time in minutes
    function checkRemainingTime(uint targetElection) public view returns (uint) {
        //pull election
        Election storage e = elections[targetElection];
        require(e.hasBeenStarted, "election has not been started");

        if(now < e.endDate) {
            return ((e.endDate - now) / 60) + 1; // plus 1 to round up
        } else {
            return 0;
        }
    }

    // function to vote for a candidate
    function vote(uint targetElection, address candidate) onlyVoters public {
        //pull election
        Election storage e = elections[targetElection];

        // make sure election has been started
        require(e.hasBeenStarted, "election has not been started");

        // make sure election is still running
        require(now < e.endDate, "time is up");

        //make sure candidate is valid
        require(e.candidateID[candidate] != 0, "invalid candidate");

        // get that candidate
        uint id = e.candidateID[candidate];
        Candidate storage c = e.candidates[id];

        //pull voter
        id = voterID[msg.sender];
        Voter storage v = voters[id];

        //check if voter has voted before, if so undo vote for that candidate
        if (v.voted) {
            uint i = 0;
            Candidate storage oldC;
            while(true) {
                oldC = e.candidates[i];
                if(oldC.supporters[msg.sender] == 1){
                    break;
                }
                i++;
            }

            oldC.supporters[msg.sender] = 0;
            oldC.votes--;
        }

        //vote for candidate
        c.supporters[msg.sender] = 1;
        c.votes++;
        v.voted = true;
    }

    // finish the election, first time computes winner after that just returns
    function endElection(uint targetElection) public {
        //get election
        Election storage e = elections[targetElection];

        // make sure election has concluded
        require(now > e.endDate, "election still going");

        // make sure hasn't already been computed
        require (!e.finished, "result already concluded");

        // compute and set winner
        Candidate storage c;
        e.winner = e.candidates[1];
        for(uint i = 1; i < e.candidates.length; i++) {
            c = e.candidates[i];
            if(c.votes > e.winner.votes) {
                e.winner = c;
            }
        }

        e.finished = true;
    }

    //view result
    function viewResults(uint targetElection) public view returns (string) {
        //get election
        Election storage e = elections[targetElection];

        // make sure result has been computed
        require(e.finished, "not yet computed");

        //return winners name
        return e.winner.name;
    }
}
