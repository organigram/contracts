pragma solidity ^0.4.11;

// Standard contract for a constitutionnal reform

import "../procedures/simpleNormNominationProcedure.sol";




contract deploySimpleNormNominationProcedure is simpleNormNominationProcedure {

    function deploySimpleNormNominationProcedure (address _authorizedNominatersOrgan) public {

    authorizedNominatersOrgan = _authorizedNominatersOrgan;

    }
}
