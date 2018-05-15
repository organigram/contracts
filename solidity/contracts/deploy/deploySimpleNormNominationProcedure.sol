pragma solidity ^0.4.11;

// Standard contract for a constitutionnal reform

import "../procedures/simpleNormNominationProcedure.sol";




contract deploySimpleNormNominationProcedure is simpleNormNominationProcedure {

    function deploySimpleNormNominationProcedure (address _authorizedNominatersOrgan, string _name) public {

    authorizedNominatersOrgan = _authorizedNominatersOrgan;
    linkedOrgans = [authorizedNominatersOrgan];
    kelsenVersionNumber = 1;
    
    // Procedure name 
    procedureName = _name;

    }
}
