pragma solidity ^0.4.11;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../standardOrgan.sol";
import "../procedures/normsCooptationProcedure.sol";




contract deployNormsCooptationProcedure is normsCooptationProcedure {

    function deployNormsCooptationProcedure (address _membersOrganContract, address _membersWithVetoOrganContract, address _finalPromulgatorsOrganContract, uint _quorumSize, uint _votingPeriodDuration, uint _promulgationPeriodDuration) public {

    membersOrganContract = _membersOrganContract;
    membersWithVetoOrganContract = _membersWithVetoOrganContract;
    finalPromulgatorsOrganContract = _finalPromulgatorsOrganContract; 
    linkedOrgans = [finalPromulgatorsOrganContract,membersWithVetoOrganContract,membersOrganContract];

    quorumSize = _quorumSize;
    minimumDepositSize = 1000;
    // votingPeriodDuration = 3 minutes;
    // promulgationPeriodDuration = 3 minutes;

    votingPeriodDuration = _votingPeriodDuration;
    promulgationPeriodDuration = _promulgationPeriodDuration;


    kelsenVersionNumber = 1;

    }
}
