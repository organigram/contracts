pragma solidity ^0.4.11;

// Standard contract for a constitutionnal reform

import "../procedures/simpleAdminsAndMasterNominationProcedure.sol";




contract deploySimpleAdminsAndMasterNominationProcedure is simpleAdminsAndMasterNominationProcedure {

    function deploySimpleAdminsAndMasterNominationProcedure (address _authorizedReformersOrgan) public {

    authorizedReformersOrgan = _authorizedReformersOrgan;
    linkedOrgans = [authorizedReformersOrgan];

    kelsenVersionNumber = 1;
    
    }
}
