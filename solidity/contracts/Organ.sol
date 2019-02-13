pragma solidity >=0.4.22 <0.6.0;


/// @title Standard organ contract


import "./Kelsen.sol";
import "./libraries/organLibrary.sol";


contract Organ is Kelsen{


    // Declaring structures for different organ roles:
    // Masters can add/remove admins
    // Admins can add / remove norms
    // Norms are sets of adresses, contracts or references gathered by the organ
    bool public isAnOrgan = true;
    bool public isAProcedure = false;
    int public kelsenVersionNumber = 2;
    
    using organLibrary for organLibrary.OrganInfo;
    // Storing organ infos
    organLibrary.OrganInfo public organInfos;

    // Events
    // Norm management events
    event addNormEvent(address _from, address _normAddress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size);
    event remNormEvent(address _from, address _normAddress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size);


    // Organ declaration
    constructor(string _organName) public {
        organInfos.initOrganLib(_organName);
    }

    // ################# Organ managing functions

    function setName(string _organName) 
    public 
    {
        organInfos.setNameLib(_organName);
    }
        // Money managing function
    function () 
    public 
    payable 
    {
        organInfos.payInLib();
    }

    function payout(address _to, uint _value) 
    public 
    {
        organInfos.payoutLib(_to, _value);
    }

    // ################# Master managing functions
    function addMaster(address _newMasterAddress, bool _canAdd, bool _canDelete) 
    public
    {
        organInfos.addMasterLib(_newMasterAddress, _canAdd, _canDelete);
    }

    function remMaster(address _masterToRemove) 
    public 
    {
        organInfos.remMasterLib(_masterToRemove);
    }

    function replaceMaster(address _masterToRemove, address _masterToAdd, bool _canAdd, bool _canDelete) 
    public 
    {
        organInfos.replaceMasterLib(_masterToRemove, _masterToAdd, _canAdd, _canDelete);
    }

    // ################# Admin managing functions
    function addAdmin(address _newAdminAddress, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend) 
    public 
    {
        organInfos.addAdminLib(_newAdminAddress, _canAdd, _canDelete, _canDeposit, _canSpend);
    }

    function replaceAdmin(address _adminToRemove, address _adminToAdd, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend) 
    public 
    {
        organInfos.replaceAdminLib(_adminToRemove, _adminToAdd, _canAdd, _canDelete, _canDeposit, _canSpend);
    }

    function remAdmin(address _adminToRemove) public {
        organInfos.remAdminLib(_adminToRemove);
    }

    // ################# Norms managing functions

    function addNorm (address _normAddress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) public  returns (uint _normPosition)
    {
        // Check sender is allowed
        require(organInfos.admins[msg.sender].canAdd);

        // If the norm has an address, we check that the address has not been used before.
        if (_normAddress != 0x0000) { require(organInfos.addressPositionInNorms[_normAddress] != 0);}

        // Adding the norm
        organInfos.norms.push(organLibrary.Norm({
                name: _name,
                normAddress: _normAddress,
                ipfsHash: _ipfsHash,
                hash_function: _hash_function,
                size: _size
            }));
        // Registering norm position relative to its address
        organInfos.addressPositionInNorms[_normAddress] = organInfos.norms.length -1;
        // Incrementing active norm number and total norm number trackers
        organInfos.activeNormNumber += 1;
        emit addNormEvent(msg.sender, _normAddress,  _name,  _ipfsHash,  _hash_function,  _size);

        // Registering the address as active
        return organInfos.addressPositionInNorms[_normAddress] ;
    }

    function replaceNorm (uint _normNumber, address _normAddress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) public
    {
        require((organInfos.admins[msg.sender].canDelete) && (organInfos.admins[msg.sender].canAdd));
        if (_normAddress != 0x0000) { require(organInfos.addressPositionInNorms[_normAddress] != 0);}
        
        organInfos.addressPositionInNorms[organInfos.norms[_normNumber].normAddress] = 0;
        emit remNormEvent(msg.sender, organInfos.norms[_normNumber].normAddress, organInfos.norms[_normNumber].name, organInfos.norms[_normNumber].ipfsHash,  organInfos.norms[_normNumber].hash_function,  organInfos.norms[_normNumber].size);

        delete organInfos.norms[_normNumber];
        organInfos.norms[_normNumber] = organLibrary.Norm({
                name: _name,
                normAddress: _normAddress,
                ipfsHash: _ipfsHash,
                hash_function: _hash_function,
                size: _size
            });
        
        organInfos.addressPositionInNorms[_normAddress] = _normNumber;
        emit addNormEvent(msg.sender, _normAddress,  _name,  _ipfsHash,  _hash_function,  _size);

    }

    function remNorm (uint _normNumber) public
    {
        // Check sender is allowed:
        // - Sender is admin
        // - Norm number is trying to delete himself
        require(organInfos.admins[msg.sender].canDelete || (organInfos.addressPositionInNorms[organInfos.norms[_normNumber].normAddress] != 0 && msg.sender == organInfos.norms[_normNumber].normAddress));
        // Deleting norm position from addressPositionInNorms
        delete organInfos.addressPositionInNorms[organInfos.norms[_normNumber].normAddress];
        // Logging event
        emit remNormEvent(msg.sender, organInfos.norms[_normNumber].normAddress, organInfos.norms[_normNumber].name, organInfos.norms[_normNumber].ipfsHash,  organInfos.norms[_normNumber].hash_function,  organInfos.norms[_normNumber].size);

        // Removing norm from norms
        delete organInfos.norms[_normNumber];
        organInfos.activeNormNumber -= 1;


    }

    //////////////////////// Functions to communicate with other contracts
    // Checking individual addresses
    function isMaster (address _adressToCheck) 
    public 
    view 
    returns (bool canAdd, bool canDelete) 
    {
        return (organInfos.masters[_adressToCheck].canAdd, organInfos.masters[_adressToCheck].canDelete);
    }

    function isAdmin (address _adressToCheck) 
    public 
    view 
    returns (bool canAdd, bool canDelete, bool canDeposit, bool canSpend) 
    {
        return (organInfos.admins[_adressToCheck].canAdd, organInfos.admins[_adressToCheck].canDelete, organInfos.admins[_adressToCheck].canDeposit, organInfos.admins[_adressToCheck].canSpend);
    }

    function isNorm (address _adressToCheck) 
    public 
    view 
    returns (bool isAddressInNorm) 
    {
        if (organInfos.addressPositionInNorms[_adressToCheck] != 0)
            {return true;}
        else
            {return false;}
    }

    // Retrieve contract state info
    // Size of norm array, to list elements
    function getNormListSize() 
    public 
    view 
    returns (uint normArraySize)
    {
        return organInfos.norms.length;
    }

    function getAddressPositionInNorm(address _addressToCheck) 
    public 
    view 
    returns (uint addressInNormPosition)
    {
        return organInfos.addressPositionInNorms[_addressToCheck];
    }

    function getSingleNorm(uint _desiredNormPosition) 
    public 
    view 
    returns (string name, address normAddress, bytes32 ipfsHash, uint8 hash_function, uint8 size)
    {
        return (organInfos.norms[_desiredNormPosition].name, organInfos.norms[_desiredNormPosition].normAddress, organInfos.norms[_desiredNormPosition].ipfsHash, organInfos.norms[_desiredNormPosition].hash_function, organInfos.norms[_desiredNormPosition].size);
    }

    // Retrieve lists of adresses
    function getMasterList() 
    public 
    view 
    returns (address[] _masterList)
    {
        return organInfos.masterList;
    }

    function getAdminList() 
    public 
    view 
    returns (address[] _adminList)
    {
        return organInfos.adminList;
    }

    function getKelsenVersion() 
    public 
    view 
    returns(bool _isAnOrgan, bool _isAProcedure, int _versionNumber)
    {
        return (isAnOrgan, isAProcedure, kelsenVersionNumber);
    }
}

