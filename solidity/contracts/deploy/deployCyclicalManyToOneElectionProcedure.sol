pragma solidity ^0.4.11;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../standardOrgan.sol";
import "../procedures/cyclicalManyToOneElectionProcedure.sol";




contract deployCyclicalManyToOneElectionProcedure is cyclicalManyToOneElectionProcedure {

    function deployCyclicalManyToOneElectionProcedure (address _referenceOrganContract, address _affectedOrganContract) public {
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
    
    linkedOrgans = [referenceOrganContract,affectedOrganContract];

    quorumSize = 40;
    ballotDuration = 3 minutes;
    candidacyDuration = 3 minutes;
    ballotFrequency = 9 minutes;
    nextElectionDate = now;
    neutralVoteAccepted = true;
    reelectionMaximum = 2;
    totalBallotNumber = 0;


    kelsenVersionNumber = 1;
    lastElectionNumber = 0;
    }
}
