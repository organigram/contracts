pragma solidity >=0.4.22 <0.7.0;

/// @title Base contract from which procedures factories inherit.

contract ProcedureFactory {
    address public owner;
    address[] public procedures;

    constructor() public {
        owner = msg.sender;
    }

    function createProcedure() public pure {
        revert("Factory must override the createProcedure method.");
    }

    function registerProcedure(address _contractAddress)
        internal returns (address)
    {
        procedures.push(_contractAddress);
        return _contractAddress;
    }
}