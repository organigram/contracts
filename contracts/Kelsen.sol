// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

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
        public view returns(bool, bool, uint8)
    {
        return (isOrgan, isProcedure, kelsenVersion);
    }
}