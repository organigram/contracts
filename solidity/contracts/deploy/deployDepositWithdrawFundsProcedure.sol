pragma solidity ^0.4.11;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../standardOrgan.sol";
import "../procedures/depositWithdrawFundsProcedure.sol";




contract deployDepositWithdrawFundsProcedure is depositWithdrawFundsProcedure {

function deployDepositWithdrawFundsProcedure (address _authorizedDepositors, address _authorizedWithdrawers, address _defaultReceivingOrgan, string _name) public {

    authorizedDepositorsOrganContract = _authorizedDepositors;
    authorizedWithdrawersOrganContract = _authorizedWithdrawers;
    defaultReceivingOrganContract = _defaultReceivingOrgan;
    linkedOrgans = [defaultReceivingOrganContract,authorizedDepositorsOrganContract];
	// Procedure name 
    procedureName = _name;
    kelsenVersionNumber = 1;

    }
}
