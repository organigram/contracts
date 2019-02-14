pragma solidity ^0.4.24;

import "../Organ.sol";

/**

Kelsen Framework
Procedure library
This library is used to hold the logic common to all procedures

**/
library procedureLibrary {
  
    struct ProcedureData 
    {
        int procedureTypeNumber;
        string procedureName;
        address[] linkedOrgans;
    }

  function isAllowed(address _organAddress)
  public
  view
    {
      // Verifying the evaluator is an admin
      Organ authorizedUsersOrgan = Organ(_organAddress);

      require(authorizedUsersOrgan.getAddressPositionInNorm(msg.sender) != 0);
      delete _organAddress;
    }

}