pragma solidity ^0.4.11;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../standardOrgan.sol";
import "../procedures/voteOnNormsProcedure.sol";




contract deployVoteOnNormsProcedure is voteOnNormsProcedure {

function deployVoteOnNormsProcedure (address _affectedOrganContract, address _votersOrganContract, address _membersWithVetoOrganContract, address _finalPromulgatorsOrganContract, uint _quorumSize, uint _votingPeriodDuration, uint _promulgationPeriodDuration) public {

    affectedOrganContract = _affectedOrganContract;
    votersOrganContract = _votersOrganContract;
    membersWithVetoOrganContract = _membersWithVetoOrganContract;
    finalPromulgatorsOrganContract = _finalPromulgatorsOrganContract; 

    quorumSize = _quorumSize;
    // votingPeriodDuration = 3 minutes;
    // promulgationPeriodDuration = 3 minutes;

    votingPeriodDuration = _votingPeriodDuration;
    promulgationPeriodDuration = _promulgationPeriodDuration;

    isAnOrgan = false;
    isAProcedure = true;
    kelsenVersionNumber = 1;

    }
}
