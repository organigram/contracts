pragma solidity >=0.4.22 <0.6.0;

// Standard contract for promulgation of a norm

import "../standardProcedure.sol";
import "../Organ.sol";


contract depositWithdrawFundsProcedure is Procedure{
    // 1: Cyclical many to one election (Presidential Election)
    // 2: Cyclical many to many election (Moderators Election)
    // 3: Simple norm nomination 
    // 4: Simple admins and master nomination
    // 5: Vote on Norms 
    // 6: Vote on masters and admins 
    // 7: Cooptation
    // 8: Vote on an expense
    // 9: Deposit/Withdraw funds on an organ

    // Where are authorized depositors registered. If authorizedDepositorsOrganContract is set to 0, anyone can deposit funds
    address public authorizedDepositorsOrganContract;

    // Where are authorized depositors registered. If authorizedDepositorsOrganContract is set to 0, anyone can deposit funds
    address public authorizedWithdrawersOrganContract;

    // Default organ to which deposits are sent
    address public defaultReceivingOrganContract;

    // Events
    event depositedFunds(address _from, address _payoutAddress, uint _amount);
    event withdrewFunds(address _from, address _payoutAddress, uint _amount);

    constructor (address _authorizedDepositors, address _authorizedWithdrawers, address _defaultReceivingOrgan, string _name) 
    public 
    {
        authorizedDepositorsOrganContract = _authorizedDepositors;
        authorizedWithdrawersOrganContract = _authorizedWithdrawers;
        defaultReceivingOrganContract = _defaultReceivingOrgan;

        procedureInfo.linkedOrgans = [defaultReceivingOrganContract,authorizedDepositorsOrganContract];
        procedureInfo.procedureName = _name;
        procedureInfo.procedureTypeNumber = 9;
    }

    function () 
    public 
    payable 
    {
        depositToOrgan(defaultReceivingOrganContract);
    }

    function depositToOrgan(address _targetOrgan) 
    public 
    payable 
    {
        // Checking if depositors are restricted
        if (authorizedDepositorsOrganContract != 0x0000) 
        {
            authorizedDepositorsOrganContract.isAllowed();   
        }

        // Sending funds to organ
        _targetOrgan.transfer(msg.value);

        // Log event
        emit depositedFunds(msg.sender, _targetOrgan, msg.value);
    }

    function withdrawOnOrgan(address _targetOrgan, address _receiver, uint _amount) 
    public 
    {

        // Checking if withdrawers are restricted
        authorizedWithdrawersOrganContract.isAllowed();    
   
        // Instanciating target organ for withdrawal
        Organ organToWithdrawFrom = Organ(_targetOrgan);

        // Withdrawing funds from organ
        organToWithdrawFrom.payout(_receiver, _amount);

        // Log event
        emit withdrewFunds( _targetOrgan, msg.sender, _amount);
    }
}

