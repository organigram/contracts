pragma solidity ^0.4.11;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../standardOrgan.sol";
import "../procedures/voteOnExpenseProcedure.sol";




contract deployVoteOnExpenseProcedure is voteOnExpenseProcedure {

function deployVoteOnExpenseProcedure (address _affectedOrganContract, address _votersOrganContract, address _membersWithVetoOrganContract, address _finalPromulgatorsOrganContract, uint _quorumSize, uint _votingPeriodDuration, uint _promulgationPeriodDuration, string _name) public {

    affectedOrganContract = _affectedOrganContract;
    votersOrganContract = _votersOrganContract;
    membersWithVetoOrganContract = _membersWithVetoOrganContract;
    finalPromulgatorsOrganContract = _finalPromulgatorsOrganContract; 
    linkedOrgans = [affectedOrganContract,votersOrganContract,membersWithVetoOrganContract,finalPromulgatorsOrganContract];

    // Procedure name 
    procedureName = _name;
    
    quorumSize = _quorumSize;
    // votingPeriodDuration = 3 minutes;
    // promulgationPeriodDuration = 3 minutes;

    votingPeriodDuration = _votingPeriodDuration;
    promulgationPeriodDuration = _promulgationPeriodDuration;

    kelsenVersionNumber = 1;

    }
}
