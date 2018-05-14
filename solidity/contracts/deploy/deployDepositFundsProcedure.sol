pragma solidity ^0.4.11;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../standardOrgan.sol";
import "../procedures/depositFundsProcedure.sol";




contract deployDepositFundsProcedure is depositFundsProcedure {

function deployDepositFundsProcedure (address _authorizedDepositors, address _defaultReceivingOrgan) public {

    authorizedDepositorsOrganContract = _authorizedDepositors;
    defaultReceivingOrganContract = _defaultReceivingOrgan;
    linkedOrgans = [defaultReceivingOrganContract,authorizedDepositorsOrganContract];

    kelsenVersionNumber = 1;

    }
}
