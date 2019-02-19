pragma solidity ^0.4.24;

import "../Organ.sol";

/**

Kelsen Framework
Procedure library
This library is used to hold the logic common to all procedures

**/
library votingLibrary {
  
    struct VotingProcessInfo 
    {
        uint startDate;
        uint votingPeriodEndDate;
        bool wasVetoed;
        bool wasCounted;
        bool wasAccepted;
        bool wasEnded;
        uint voteFor;
        uint totalVoteCount;
        mapping(address => bool) hasUserVoted;
    }

    struct RecurringElectionInfo 
    {
        uint ballotFrequency;
        // Max parallel election running
        uint nextElectionDate;
        // Time to vote
        uint ballotDuration;
        // Time to declare as a candidate
        uint candidacyDuration;
        // Maximum time someone can be candidate
        uint reelectionMaximum;
        // Minimum participation to validate election
        uint quorumSize;
        // // Is blank vote accepted
        // bool neutralVoteAccepted;
    }

    // Candidacies structure, to keep track of candidacies for an election
    struct Candidacy 
    {
        address candidateAddress;
        bytes32 ipfsHash; // ID of proposal on IPFS
        uint8 hash_function;
        uint8 size;
        uint voteNumber;
    }

    struct ElectionBallot 
    {
        bytes32 name;   // short name (up to 32 bytes)
        uint startDate;
        uint candidacyEndDate;
        uint electionEndDate;
        bool wasEnded;
        bool wasEnforced;
        uint totalVoteCount;
        address[] candidateList;
        mapping(address => bool) hasUserVoted;
        mapping(address => Candidacy) candidacies;
    }

    function initElectionParameters(RecurringElectionInfo storage self, uint _ballotFrequency, uint _ballotDuration, uint _quorumSize, uint _reelectionMaximum, uint _candidacyDuration)
    public
    {
        self.ballotFrequency = _ballotFrequency;
        self.nextElectionDate = now;
        self.ballotDuration = _ballotDuration;
        self.quorumSize = _quorumSize;
        self.reelectionMaximum = _reelectionMaximum;
        self.candidacyDuration = _candidacyDuration;
    }

}