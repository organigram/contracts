pragma solidity ^0.4.11;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../standardOrgan.sol";
import "../procedures/cyclicalManyToManyElectionProcedure.sol";




contract deployCyclicalManyToManyElectionProcedure is cyclicalManyToManyElectionProcedure {

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

    quorumSize = 40;
    ballotDuration = 3 minutes;
    candidacyDuration = 3 minutes;
    ballotFrequency = 9 minutes;
    // ballotDuration = 10 seconds;
    // candidacyDuration = 10 seconds;
    // ballotFrequency = 30 seconds;

    nextElectionDate = now;
    neutralVoteAccepted = true;
    reelectionMaximum = 2;
    totalBallotNumber = 0;
    voterToCandidateRatio = 2;

    kelsenVersionNumber = 1;
    lastElectionNumber = 0;
    }
}
