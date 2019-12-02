pragma solidity >=0.4.22 <0.7.0;

/// @title Base contract from which procedures factories inherit.

contract ProcedureFactory {

    address public owner;
    address[] public procedures;

    // Events.
    event procedureRegistered(address _from, address _address);

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
        emit procedureRegistered(msg.sender, _contractAddress);
        return _contractAddress;
    }
}