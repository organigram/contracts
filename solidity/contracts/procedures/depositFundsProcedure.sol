pragma solidity ^0.4.11;

// Standard contract for promulgation of a norm

import "../standardProcedure.sol";
import "../standardOrgan.sol";


contract depositFundsProcedure is Procedure{
    // 1: Cyclical many to one election (Presidential Election)
    // 2: Cyclical many to many election (Moderators Election)
    // 3: Simple norm nomination 
    // 4: Simple admins and master nomination
    // 5: Vote on Norms 
    // 6: Vote on masters and admins 
    // 7: Cooptation
    // 8: Vote on an expense
    // 9: Deposit funds on an organ
    int public procedureTypeNumber = 9;

    // Storage for procedure name
    string public procedureName;

    // Where are authorized depositors registered. If authorizedDepositorsOrganContract is set to 0, anyone can deposit funds
    address public authorizedDepositorsOrganContract;

    // Default organ to which deposits are sent
    address public defaultReceivingOrganContract;

    // Gathering connected organs for easier DAO mapping
    address[] public linkedOrgans;

    // Mapping each proposition to the user creating it
    mapping (address => uint) public amountDepositedByDepositorAddress;    

    // Mapping each proposition to the user who participated
    mapping (address => uint) public amountDepositedToReceiverAddress;

    // Events
    event depositedFunds(address _from, address _payoutAddress, uint _amount);

    function () public payable {

        // Instanciating Organ
        Organ authorizedDepositorsOrgan = Organ(authorizedDepositorsOrganContract);

        // Checking if depositors are restricted
        if (authorizedDepositorsOrganContract != 0x0000) {

            require(authorizedDepositorsOrgan.isNorm(msg.sender));
            
        }

        delete authorizedDepositorsOrgan;

        // Sending funds to organ
        defaultReceivingOrganContract.transfer(msg.value);

        // Recording value transfer
        amountDepositedByDepositorAddress[msg.sender] += msg.value;
        amountDepositedToReceiverAddress[defaultReceivingOrganContract] += msg.value;

        // Log event
        depositedFunds(msg.sender, defaultReceivingOrganContract, msg.value);


    }

        function depositToOrgan(address _targetOrgan) public payable {

        // Instanciating Organ
        Organ authorizedDepositorsOrgan = Organ(authorizedDepositorsOrganContract);

        // Checking if depositors are restricted
        if (authorizedDepositorsOrganContract != 0x0000) {

            require(authorizedDepositorsOrgan.isNorm(msg.sender));
            
        }

        delete authorizedDepositorsOrgan;

        // Sending funds to organ
        _targetOrgan.transfer(msg.value);

        // Recording value transfer
        amountDepositedByDepositorAddress[msg.sender] += msg.value;
        amountDepositedToReceiverAddress[_targetOrgan] += msg.value;

        // Log event
        depositedFunds(msg.sender, _targetOrgan, msg.value);


    }


    function getFundsDepositedByUser(address _userAddress) public view returns (uint)
    {return amountDepositedByDepositorAddress[_userAddress];}    
    function getFundsDepositedToOrgan(address _organAddress) public view returns (uint)
    {return amountDepositedToReceiverAddress[_organAddress];} 


}

