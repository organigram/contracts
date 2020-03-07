pragma solidity >=0.4.22 <0.7.0;

/// @title Standard Kelsen contract.

contract Kelsen {

    uint8 public kelsenVersion = 3;
    bool public isOrgan;
    bool public isProcedure;

    constructor(bool _isOrgan, bool _isProcedure) public {
        isOrgan = _isOrgan;
        isProcedure = _isProcedure;
    }

    function getKelsenData()
        public view returns(bool _isOrgan, bool _isProcedure, uint8 _version)
    {
        return (isOrgan, isProcedure, kelsenVersion);
    }
}