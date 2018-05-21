pragma solidity ^0.4.11;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../standardOrgan.sol";
import "../procedures/cyclicalManyToManyElectionProcedure.sol";




contract deployCyclicalManyToManyElectionProcedure is cyclicalManyToManyElectionProcedure {
    // To implement function deployCyclicalManyToManyElectionProcedure (address _referenceOrganContract, address _affectedOrganContract, uint[6] _voteVariables, string _name) public {
    function deployCyclicalManyToManyElectionProcedure (address _referenceOrganContract, address _affectedOrganContract, string _name) public {
    //     // Variables for Presidential election
    // voterRegistry = 0x0000;
    // quorumSize = 40;
    // ballotDuration = 7 days;
    // candidacyDuration = 7 days;
    // ballotFrequency = 2 years;
    // nextElectionDate = now;
    // neutralVoteAccepted = true;
    // reelectionMaximum = 2;
    // totalBallotNumber = 0;

        // Variables for testing
        // Adress of voter registry organ
    referenceOrganContract = _referenceOrganContract;
    // Adress of president registry organ
    affectedOrganContract = _affectedOrganContract;

    // Procedure name 
    procedureName = _name;

    linkedOrgans = [referenceOrganContract,affectedOrganContract];

    // Former method
    quorumSize = 40;
    ballotDuration = 3 minutes;
    candidacyDuration = 3 minutes;
    ballotFrequency = 9 minutes;
    reelectionMaximum = 2;
    voterToCandidateRatio = 2;

    // To implement
    // // Assigning vote variables
    // quorumSize = _voteVariables[0];
    // ballotDuration = _voteVariables[1];
    // candidacyDuration = _voteVariables[2];
    // ballotFrequency = _voteVariables[3];
    // reelectionMaximum = _voteVariables[4];
    // voterToCandidateRatio = _voteVariables[5];

    // To be implemented
    neutralVoteAccepted = true;
    
    // Initializing
    totalBallotNumber = 0;
    nextElectionDate = now;

    kelsenVersionNumber = 1;
    lastElectionNumber = 0;
    }
}
