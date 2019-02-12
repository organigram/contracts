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
    int public kelsenVersionNumber = 1;
    
    // Storing organ infos
    organLibrary.OrganInfo organInfos;
    // Events
    // Organ management events
    event changeOrganName(address _from, string _newName);
    event spendMoney(address _from, address _to, uint256 _amount);
    event receiveMoney(address _from, uint256 _amount);

    // Master management events
    event addMasterEvent(address _from, address _newMaster, bool _canAdd, bool _canDelete, string _name);
    event remMasterEvent(address _from, address _masterToRemove);

    // Admin management events
    event addAdminEvent(address _from, address _newAdmin, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend, string _name);
    event remAdminEvent(address _from, address _adminToRemove);

    // Norm management events
    event addNormEvent(address _from, address _normAddress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size);
    event remNormEvent(address _from, address _normAddress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size);



    // This declares two state variable that
    // stores a `Master` and a 'admin' struct for each possible address.
    //mapping(address => organLibrary.Master) public masters;
    //mapping(address => organLibrary.Admin) public admins;

    // One mapping to signal adresses that are included in norms
    mapping(address => bool) public isAddressInNorms;
    // One mapping to track norm position of each address. Careful, each address is tracked only once here
    mapping(address => uint) public addressPositionInNorms;

    // This declares two dynamically-sized array of `Admin` and 'Master' structs for easy referencing.
    //address[] public masterList;
    //address[] public adminList;

    // A dynamically-sized array of `Norm` structs.
    //organLibrary.Norm[] public norms;

    //string public organName;
    // Keeping track of active norms
    //uint256 public activeNormNumber;


    constructor(string _name) public {

        // Initializing with deployer as master
        organInfos.masters[msg.sender].canAdd = true;
        organInfos.masters[msg.sender].canDelete = true;
        organInfos.masters[msg.sender].name = 'Original Master';
        organInfos.masterList.push(msg.sender);
        organInfos.organName = _name;
        // Initializing with deployer as admin
        // admins[msg.sender].canAdd = true;
        // admins[msg.sender].canDelete = true;
        // admins[msg.sender].name = 'Original Master';
        // adminList.push(msg.sender);
        // Initializing first norms to avoid errors when deleting norms
        organLibrary.Norm memory initNorm;
        organInfos.norms.push(initNorm);
        kelsenVersionNumber = 1;

    }
    // ################# Organ managing functions

    function setName(string _name) public {
        // Check sender is allowed
        require((organInfos.masters[msg.sender].canAdd) && (organInfos.masters[msg.sender].canDelete));
        organInfos.organName = _name;
        emit changeOrganName(msg.sender, _name);
    }
        // Money managing function
    function () public payable {
        require(organInfos.admins[msg.sender].canDeposit);
        emit receiveMoney(msg.sender, msg.value);


    }
    function payout(address _to, uint _value) public {
        require(organInfos.admins[msg.sender].canSpend);
        _to.transfer(_value);
        emit spendMoney(msg.sender, _to, _value);

    }

    // ################# Master managing functions

    function addMaster(address _newMasterAddress, bool _canAdd, bool _canDelete, string _name) public{
        // Check that the sender is allowed
        require((organInfos.masters[msg.sender].canAdd));
        // Check new master is not already a master
        require((!organInfos.masters[_newMasterAddress].canAdd) && (!organInfos.masters[_newMasterAddress].canDelete));

        // Check new master has at least one permission activated
        require(_canAdd || _canDelete);

        // Adding master to master list and retrieving position
        organInfos.masters[_newMasterAddress].rankInMasterList = organInfos.masterList.push(_newMasterAddress) - 1;

        // Creating master privileges
        organInfos.masters[_newMasterAddress].canAdd = _canAdd;
        organInfos.masters[_newMasterAddress].canDelete = _canDelete;
        organInfos.masters[_newMasterAddress].name = _name;
        emit addMasterEvent(msg.sender, _newMasterAddress, _canAdd, _canDelete, _name);

    }

    function replaceMaster(address _masterToRemove, address _masterToAdd, bool _canAdd, bool _canDelete, string _name) public {
        // Check sender is allowed
        require((organInfos.masters[msg.sender].canAdd) && (organInfos.masters[msg.sender].canDelete));
        // Check new master has at least one permission activated
        require(_canAdd || _canDelete);

        // Check if we are replacing a master with another, or if we are modifying permissions
        if (_masterToRemove != _masterToAdd)
        {
            // Replacing a master
            addMaster(_masterToAdd, _canAdd, _canDelete, _name);
            remMaster(_masterToRemove);
        }

        else
        {
            // Modifying permissions
            

            // Triggering events
            emit remMasterEvent(msg.sender, _masterToRemove);
            emit addMasterEvent(msg.sender, _masterToAdd, _canAdd, _canDelete, _name);

            //Modifying permissions
            organInfos.masters[_masterToRemove].canAdd = _canAdd;
            organInfos.masters[_masterToRemove].canDelete = _canDelete;
            organInfos.masters[_masterToRemove].name = _name;

        }


    }
    function remMaster(address _masterToRemove) public {
        // Check sender is allowed
        require((organInfos.masters[msg.sender].canDelete));
        // Check affected account is a master
        require((organInfos.masters[_masterToRemove].canDelete) || (organInfos.masters[_masterToRemove].canAdd) );
        // Deleting entry in masterList
        delete organInfos.masterList[organInfos.masters[_masterToRemove].rankInMasterList];
        // Deleting master privileges
        delete organInfos.masters[_masterToRemove];
        emit remMasterEvent(msg.sender, _masterToRemove);
    }

    // ################# Admin managing functions

    function addAdmin(address _newAdminAddress, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend, string _name) public {
        // Check the sender is allowed
        require((organInfos.masters[msg.sender].canAdd));
        // Check new admin is not already an admin
        require((!organInfos.admins[_newAdminAddress].canAdd) && (!organInfos.admins[_newAdminAddress].canDelete) && (!organInfos.admins[_newAdminAddress].canDeposit) && (!organInfos.admins[_newAdminAddress].canSpend));

        // Check new admin has at least one permission activated
        require(_canAdd || _canDelete || _canDeposit || _canSpend);

        // Adding admin to admin list and retrieving position
        organInfos.admins[_newAdminAddress].rankInAdminList = organInfos.adminList.push(_newAdminAddress) - 1;

        // Creating master privileges
        organInfos.admins[_newAdminAddress].canAdd = _canAdd;
        organInfos.admins[_newAdminAddress].canDelete = _canDelete;
        organInfos.admins[_newAdminAddress].canDeposit = _canDeposit;
        organInfos.admins[_newAdminAddress].canSpend = _canSpend;
        organInfos.admins[_newAdminAddress].name = _name;
        emit addAdminEvent(msg.sender, _newAdminAddress,  _canAdd,  _canDelete,  _canDeposit,  _canSpend,  _name);
   
    }

    function replaceAdmin(address _adminToRemove, address _adminToAdd, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend, string _name) public {
        // Check sender is allowed
        require((organInfos.masters[msg.sender].canAdd) && (organInfos.masters[msg.sender].canDelete));
        // Check new admin has at least one permission activated
        require(_canAdd || _canDelete || _canDeposit || _canSpend);
        
        remAdmin(_adminToRemove);
        addAdmin(_adminToAdd, _canAdd, _canDelete, _canDeposit, _canSpend, _name);

    }

    function remAdmin(address _adminToRemove) public {
        // Check sender is allowed
        require((organInfos.masters[msg.sender].canDelete));
        // Check affected account is admin
        require((organInfos.admins[_adminToRemove].canDelete) || (organInfos.admins[_adminToRemove].canAdd) );
        // Deleting entry in adminList
        delete organInfos.adminList[organInfos.admins[_adminToRemove].rankInAdminList];
        // Deleting admin privileges
        delete organInfos.admins[_adminToRemove];

        emit remAdminEvent(msg.sender, _adminToRemove);

    }

    // ################# Norms managing functions

    function addNorm (address _normAddress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) public  returns (uint _normPosition)
    {
        // Check sender is allowed
        require(organInfos.admins[msg.sender].canAdd);

        // If the norm has an address, we check that the address has not been used before.
        if (_normAddress != 0x0000) { require(!isAddressInNorms[_normAddress]);}

        // Adding the norm
        organInfos.norms.push(organLibrary.Norm({
                name: _name,
                normAddress: _normAddress,
                ipfsHash: _ipfsHash,
                hash_function: _hash_function,
                size: _size
            }));
        // Registering norm position relative to its address
        addressPositionInNorms[_normAddress] = organInfos.norms.length -1;
        // Incrementing active norm number and total norm number trackers
        organInfos.activeNormNumber += 1;
        emit addNormEvent(msg.sender, _normAddress,  _name,  _ipfsHash,  _hash_function,  _size);

        // Registering the address as active
        isAddressInNorms[_normAddress] = true;
        return addressPositionInNorms[_normAddress] ;
    }

    function replaceNorm (uint _normNumber, address _normAddress, string _name, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) public
    {
        require((organInfos.admins[msg.sender].canDelete) && (organInfos.admins[msg.sender].canAdd));
        if (_normAddress != 0x0000) { require(!isAddressInNorms[_normAddress]);}
        isAddressInNorms[organInfos.norms[_normNumber].normAddress] = false;
        addressPositionInNorms[organInfos.norms[_normNumber].normAddress] = 0;
        emit remNormEvent(msg.sender, organInfos.norms[_normNumber].normAddress, organInfos.norms[_normNumber].name, organInfos.norms[_normNumber].ipfsHash,  organInfos.norms[_normNumber].hash_function,  organInfos.norms[_normNumber].size);

        delete organInfos.norms[_normNumber];
        organInfos.norms[_normNumber] = organLibrary.Norm({
                name: _name,
                normAddress: _normAddress,
                ipfsHash: _ipfsHash,
                hash_function: _hash_function,
                size: _size
            });
        isAddressInNorms[_normAddress] = true;
        addressPositionInNorms[_normAddress] = _normNumber;
        emit addNormEvent(msg.sender, _normAddress,  _name,  _ipfsHash,  _hash_function,  _size);

    }

    function remNorm (uint _normNumber) public
    {
        // Check sender is allowed:
        // - Sender is admin
        // - Norm number is trying to delete himself
        require(organInfos.admins[msg.sender].canDelete || (isAddressInNorms[msg.sender] && msg.sender == organInfos.norms[_normNumber].normAddress));
        // Deleting norm position from addressPositionInNorms
        delete addressPositionInNorms[organInfos.norms[_normNumber].normAddress];
        // Marking address as deactivated from isAddressInNorms
        isAddressInNorms[organInfos.norms[_normNumber].normAddress] = false;
        // Logging event
        emit remNormEvent(msg.sender, organInfos.norms[_normNumber].normAddress, organInfos.norms[_normNumber].name, organInfos.norms[_normNumber].ipfsHash,  organInfos.norms[_normNumber].hash_function,  organInfos.norms[_normNumber].size);

        // Removing norm from norms
        delete organInfos.norms[_normNumber];
        organInfos.activeNormNumber -= 1;


    }

    //////////////////////// Functions to communicate with other contracts
    // Checking individual addresses
    function isMaster (address _adressToCheck) public view returns (bool canAdd, bool canDelete) {
        return (organInfos.masters[_adressToCheck].canAdd, organInfos.masters[_adressToCheck].canDelete);
    }
    function isAdmin (address _adressToCheck) public view returns (bool canAdd, bool canDelete) {
        return (organInfos.admins[_adressToCheck].canAdd, organInfos.admins[_adressToCheck].canDelete);
    }
    function isNorm (address _adressToCheck) public view returns (bool isAddressInNorm) {
        return isAddressInNorms[_adressToCheck];
    }
    function isMoneyManager(address _adressToCheck) public view returns (bool canDeposit, bool canSpend){
        return (organInfos.admins[_adressToCheck].canDeposit, organInfos.admins[_adressToCheck].canSpend);
    }
    // Retrieve contract state info
    // Number of active norms (voter pool size for voter registering, for example)
    function getActiveNormNumber() public view returns (uint _activeNormNumber){
        return organInfos.activeNormNumber;
    }
    // Size of norm array, to list elements
    function getNormListSize() public view returns (uint normArraySize){
        return organInfos.norms.length;
    }
    function getAddressPositionInNorm(address _addressToCheck) public view returns (uint addressInNormPosition){
        return addressPositionInNorms[_addressToCheck];
    }
    function getSingleNorm(uint _desiredNormPosition) public view returns (string name, address normAddress, bytes32 ipfsHash, uint8 hash_function, uint8 size){
        return (organInfos.norms[_desiredNormPosition].name, organInfos.norms[_desiredNormPosition].normAddress, organInfos.norms[_desiredNormPosition].ipfsHash, organInfos.norms[_desiredNormPosition].hash_function, organInfos.norms[_desiredNormPosition].size);
    }

    // Retrieve lists of adresses
    function getMasterList() public view returns (address[] _masterList){
        return organInfos.masterList;
    }
    function getAdminList() public view returns (address[] _adminList){
        return organInfos.adminList;
    }
    function getKelsenVersion() public view returns(bool _isAnOrgan, bool _isAProcedure, int _versionNumber)
    {

        return (isAnOrgan, isAProcedure, kelsenVersionNumber);

    }



}

