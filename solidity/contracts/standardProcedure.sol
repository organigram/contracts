pragma solidity ^0.4.11;

/// @title Standard organ contract

import "./Kelsen.sol";


contract Procedure is Kelsen {
    // Identifiers to adapt procedure interface
    int public procedureTypeNumber;
    address[] public linkedOrgans;
    bool public isAnOrgan = false;
    bool public isAProcedure = true;
    function getLinkedOrgans() public view returns (address[] _linkedOrgans);
}
