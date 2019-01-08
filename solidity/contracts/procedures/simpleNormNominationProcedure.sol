pragma solidity >=0.4.22 <0.6.0;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../Organ.sol";

contract simpleNormNominationProcedure is Procedure{

    // 1: Cyclical many to one election (Presidential Election)
    // 2: Cyclical many to many election (Moderators Election)
    // 3: Simple norm nomination 
    // 4: Simple admins and master nomination
    // 5: Vote on Norms 
    // 6: Vote on masters and admins 
    // 7: Cooptation
    int public procedureTypeNumber = 3;
    // address public affectedOrganContract;
    address public authorizedNominatersOrgan;

    // // Gathering connected organs for easier DAO mapping
    // address[] public linkedOrgans;

    // // Storage for procedure name
    // string public procedureName;
    constructor (address _authorizedNominatersOrgan, string _name) 
    public
    {

    authorizedNominatersOrgan = _authorizedNominatersOrgan;
    linkedOrgans = [authorizedNominatersOrgan];
    kelsenVersionNumber = 1;
    
    // Procedure name 
    procedureName = _name;

    }

    function addNorm(address _targetOrgan, address _normAdress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size)  public returns (uint newNormNumber) {

        // Checking if caller is an admin
        Organ authorizedNominatorsInstance = Organ(authorizedNominatersOrgan);
        require(authorizedNominatorsInstance.isNorm(msg.sender));
        delete authorizedNominatorsInstance;

        // Checking that the nomination procedure is an admin to the target organ
        Organ targetOrganInstance = Organ(_targetOrgan);
        bool canAdd;
        bool canDelete;
        (canAdd, canDelete) = targetOrganInstance.isAdmin(address(this));

        
        // Adding a norm if the procedure is allowed
        if (canAdd) {

            return targetOrganInstance.addNorm(_normAdress, _name, _ipfsHash, _hash_function, _size);
        }

    }
    function remNorm(address _targetOrgan, uint _normNumber) public {

        // Checking if caller is an admin
        Organ authorizedNominatorsInstance = Organ(authorizedNominatersOrgan);
        require(authorizedNominatorsInstance.isNorm(msg.sender));
        delete authorizedNominatorsInstance;

        // Checking that the nomination procedure is an admin to the target organ
        Organ targetOrganInstance = Organ(_targetOrgan);
        bool canAdd;
        bool canDelete;
        (canAdd, canDelete) = targetOrganInstance.isAdmin(address(this));

        
        // Removing a norm if the procedure is allowed
        if (canDelete) {

            targetOrganInstance.remNorm(_normNumber);
        }

    }
    function replaceNorm(address _targetOrgan, uint _oldNormNumber, address _newNormAdress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) public {

        // Checking if caller is an admin
        Organ authorizedNominatorsInstance = Organ(authorizedNominatersOrgan);
        require(authorizedNominatorsInstance.isNorm(msg.sender));
        delete authorizedNominatorsInstance;

        // Checking that the nomination procedure is an admin to the target organ
        Organ targetOrganInstance = Organ(_targetOrgan);
        bool canAdd;
        bool canDelete;
        (canAdd, canDelete) = targetOrganInstance.isAdmin(address(this));

        // Replacing an admin if the procedure is allowed
        if (canAdd && canDelete) {

            targetOrganInstance.replaceNorm(_oldNormNumber, _newNormAdress, _name, _ipfsHash, _hash_function, _size);

        }
        
    }
    // function getLinkedOrgans() public view returns (address[] _linkedOrgans)
    // {return linkedOrgans;}
    // function getProcedureName() public view returns (string _procedureName)
    // {return procedureName;}

  

}