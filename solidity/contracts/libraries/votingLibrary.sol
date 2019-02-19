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

    struct recurringElectionInfo 
        {
            uint ballotFrequency;
            // Max parallel election running
            uint nextElectionDate;
            // Time to vote
            uint ballotDuration;
            // Is blank vote accepted
            bool neutralVoteAccepted;
            // Time to declare as a candidate
            uint candidacyDuration;
            // Maximum time someone can be candidate
            uint reelectionMaximum;
            // Minimum participation to validate election
            uint quorumSize;
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
}