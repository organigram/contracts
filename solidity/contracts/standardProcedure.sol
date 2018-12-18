pragma solidity >=0.4.22 <0.6.0;


/// @title Standard organ contract

import "./Kelsen.sol";


contract Procedure is Kelsen {
    // Identifiers to adapt procedure interface
    int public procedureTypeNumber;
    address[] public linkedOrgans;
    bool public isAnOrgan = false;
    bool public isAProcedure = true;
    string public procedureName;
    function getLinkedOrgans() public view returns (address[] _linkedOrgans)
    {return linkedOrgans;}
    function getProcedureName() public view returns (string _procedureName)
    {return procedureName;}
}
