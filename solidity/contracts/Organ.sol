pragma solidity >=0.4.22 <0.7.0;

/// @title Standard Kelsen Organ contract.

import "./Kelsen.sol";
import "./libraries/organLibrary.sol";

contract Organ is Kelsen {
    // Kelsen definition.
    bool public isOrgan = true;
    bool public isProcedure = false;

    // Linking to Organ library.
    using OrganLibrary for OrganLibrary.OrganData;
    OrganLibrary.OrganData public organData;

    /*
        Organ management.
    */

    // Constructor.
    constructor(bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize) public {
        organData.init(_metadataIpfsHash, _metadataHashFunction, _metadataHashSize);
    }

    // Receiving funds.
    function () external payable {
        organData.deposit();
    }

    function updateMetadata(bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize)
        public
    {
        organData.updateMetadata(_ipfsHash, _hashFunction, _hashSize);
    }

    function withdraw(address payable _to, uint _value)
        public
    {
        organData.withdraw(_to, _value);
    }

    /*
        Masters management.
    */

    function addMaster(address _newMasterAddress, bool _canAdd, bool _canRemove)
        public
    {
        organData.addMaster(_newMasterAddress, _canAdd, _canRemove);
    }

    function removeMaster(address _masterToRemove)
        public
    {
        organData.removeMaster(_masterToRemove);
    }

    function replaceMaster(address _masterToRemove, address _masterToAdd, bool _canAdd, bool _canRemove)
        public
    {
        organData.replaceMaster(_masterToRemove, _masterToAdd, _canAdd, _canRemove);
    }

    /*
        Admins management.
    */

    function addAdmin(address _newAdminAddress, bool _canAdd, bool _canRemove, bool _canDeposit, bool _canWithdraw)
        public
    {
        organData.addAdmin(_newAdminAddress, _canAdd, _canRemove, _canDeposit, _canWithdraw);
    }

    function removeAdmin(address _adminToRemove)
        public
    {
        organData.removeAdmin(_adminToRemove);
    }

    function replaceAdmin(
        address _adminToRemove, address _adminToAdd,
        bool _canAdd, bool _canRemove, bool _canDeposit, bool _canWithdraw
    )
        public
    {
        organData.replaceAdmin(_adminToRemove, _adminToAdd, _canAdd, _canRemove, _canDeposit, _canWithdraw);
    }

    /*
        Norms management.
    */

    function addNorm(address payable _normAddress, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize)
        public returns (uint _normPosition)
    {
        return organData.addNorm(_normAddress, _ipfsHash, _hashFunction, _hashSize);
    }

    function removeNorm(uint _normIndex)
        public
    {
       organData.removeNorm(_normIndex);
    }

    function replaceNorm(uint _normIndex, address payable _normAddress, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize)
        public
    {
       organData.replaceNorm(_normIndex, _normAddress, _ipfsHash, _hashFunction, _hashSize);
    }

    /*
        Utilities for contracts.
    */

    function isMaster(address _adressToCheck)
        public view returns (bool canAdd, bool canRemove)
    {
        return (organData.masters[_adressToCheck].canAdd, organData.masters[_adressToCheck].canRemove);
    }

    function isAdmin(address _adressToCheck)
        public view returns (bool canAdd, bool canRemove, bool canDeposit, bool canWithdraw)
    {
        return (
            organData.admins[_adressToCheck].canAdd,
            organData.admins[_adressToCheck].canRemove,
            organData.admins[_adressToCheck].canDeposit,
            organData.admins[_adressToCheck].canWithdraw
        );
    }

    // Retrieve contract state info.
    // Size of norm array, to list elements.
    function getNormListSize()
        public view returns (uint normArraySize)
    {
        return organData.norms.length;
    }

    function getNormIndexByAddress(address _addressToCheck)
        public view returns (uint addressInNormPosition)
    {
        return organData.addressPositionInNorms[_addressToCheck];
    }

    function getNorm(uint _index)
        public view returns (address payable normAddress, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
    {
        return (
            organData.norms[_index].normAddress,
            organData.norms[_index].ipfsHash,
            organData.norms[_index].hashFunction,
            organData.norms[_index].hashSize
        );
    }
}