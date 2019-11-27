pragma solidity >=0.4.22 <0.7.0;

/*
    Kelsen Framework - Organ library.
    This library holds the logic to manage a simple organ.
*/

library OrganLibrary {
    /*
        Masters can edit admins.
    */
    struct Master {
        bool canAdd;        // if true, master can add admins.
        bool canRemove;     // if true, master can delete admins.
    }

    /*
        Admins can edit norms.
    */
    struct Admin {
        bool canAdd;        // if true, Admin can add norms.
        bool canRemove;     // if true, Admin can delete norms.
        bool canWithdraw;   // if true, Admin can spend funds.
        bool canDeposit;    // if true, Admin can deposit funds.
    }

    /*
        Norms are sets of addresses, contracts or references.
    */
    struct Norm {
        address payable normAddress;    // Address if norm is a member or a contract.
        bytes32 ipfsHash;              // ID of proposal on IPFS.
        uint8 hashFunction;
        uint8 hashSize;
    }

    struct OrganData {
        bytes32 metadataIpfsHash;
        uint8 metadataHashFunction;
        uint8 metadataHashSize;
        uint256 normsCount;
        mapping(address => Master) masters;
        mapping(address => Admin) admins;
        Norm[] norms;
        mapping(address => uint) addressPositionInNorms;
    }

    /*
        Events.
    */

    event metadataUpdated(address _from, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize);
    event fundsWithdrawn(address _from, address _to, uint256 _amount);
    event fundsDeposited(address _from, uint256 _amount);
    event masterAdded(address _from, address _newMaster, bool _canAdd, bool _canRemove);
    event masterRemoved(address _from, address _masterToRemove);
    event adminAdded(address _from, address _newAdmin, bool _canAdd, bool _canRemove, bool _canDeposit, bool _canWithdraw);
    event adminRemoved(address _from, address _adminToRemove);
    event normAdded(address _from, address _normAddress, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize);
    event normRemoved(address _from, address _normAddress, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize);

    /*
        Constructor.
    */

    function init(
        OrganData storage self,
        bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize
    )
        public
    {
        // Initializing with deployer as master.
        self.masters[msg.sender].canAdd = true;
        self.masters[msg.sender].canRemove = true;
        self.metadataIpfsHash = _ipfsHash;
        self.metadataHashFunction = _hashFunction;
        self.metadataHashSize = _hashSize;
        Norm memory initNorm;
        self.norms.push(initNorm);
    }

    function updateMetadata(
        OrganData storage self,
        bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize
    )
        public
    {
        // Check sender is allowed.
        require(self.masters[msg.sender].canAdd && self.masters[msg.sender].canRemove, "Not authorized.");
        self.metadataIpfsHash = _ipfsHash;
        self.metadataHashFunction = _hashFunction;
        self.metadataHashSize = _hashSize;
        emit metadataUpdated(msg.sender, _ipfsHash, _hashFunction, _hashSize);
    }

    /*
        Funds management.
    */

    function deposit(OrganData storage self)
        public
    {
        require(self.admins[msg.sender].canDeposit, "Not authorized to deposit.");
        emit fundsDeposited(msg.sender, msg.value);
    }

    function withdraw(OrganData storage self, address payable _to, uint _value)
        public
    {
        require(self.admins[msg.sender].canWithdraw, "Not authorized to withdraw.");
        _to.transfer(_value);
        emit fundsWithdrawn(msg.sender, _to, _value);
    }

    /*
        Masters management.
    */

    function addMaster(OrganData storage self, address _newMasterAddress, bool _canAdd, bool _canRemove)
        public
    {
        // Check that the sender is allowed.
        require((self.masters[msg.sender].canAdd), "Not authorized to add.");
        // Check new master is not already a master.
        require((!self.masters[_newMasterAddress].canAdd) && (!self.masters[_newMasterAddress].canRemove), "Duplicate record.");

        // Check new master has at least one permission activated.
        require(_canAdd || _canRemove, "Wrong permissions set.");

        // Creating master privileges.
        self.masters[_newMasterAddress].canAdd = _canAdd;
        self.masters[_newMasterAddress].canRemove = _canRemove;
        emit masterAdded(msg.sender, _newMasterAddress, _canAdd, _canRemove);
    }

    function removeMaster(OrganData storage self, address _masterToRemove)
        public
    {
        // Check sender is allowed.
        require((self.masters[msg.sender].canRemove), "Not authorized to remove.");
        // Check affected account is a master.
        require((self.masters[_masterToRemove].canRemove) || (self.masters[_masterToRemove].canAdd), "Record not found.");
        // Deleting master privileges.
        delete self.masters[_masterToRemove];
        emit masterRemoved(msg.sender, _masterToRemove);
    }

    function replaceMaster(
        OrganData storage self, address _masterToRemove, address _masterToAdd,
        bool _canAdd, bool _canRemove
    )
        public
    {
        // Check sender is allowed.
        require((self.masters[msg.sender].canAdd) && (self.masters[msg.sender].canRemove), "Not authorized to replace.");
        // Check new master has at least one permission activated.
        require(_canAdd || _canRemove, "Wrong permissions set.");

        // Check if we are replacing a master with another, or updating permissions.
        if (_masterToRemove != _masterToAdd) {
            // Replacing a master
            addMaster(self, _masterToAdd, _canAdd, _canRemove);
            removeMaster(self, _masterToRemove);
        }
        else {
            //Modifying permissions.
            self.masters[_masterToRemove].canAdd = _canAdd;
            self.masters[_masterToRemove].canRemove = _canRemove;

            // Triggering events.
            emit masterRemoved(msg.sender, _masterToRemove);
            emit masterAdded(msg.sender, _masterToAdd, _canAdd, _canRemove);
        }
    }

    /*
        Admins Management.
    */

    function addAdmin(
        OrganData storage self, address _newAdminAddress,
        bool _canAdd, bool _canRemove, bool _canDeposit, bool _canWithdraw
    )
        public
    {
        // Check the sender is allowed.
        require((self.masters[msg.sender].canAdd), "Not authorized to add.");
        // Check new admin is not already an admin.
        require(
            !self.admins[_newAdminAddress].canAdd &&
            !self.admins[_newAdminAddress].canRemove &&
            !self.admins[_newAdminAddress].canDeposit &&
            !self.admins[_newAdminAddress].canWithdraw,
            "Duplicate record."
        );

        // Check new admin has at least one permission activated.
        require(_canAdd || _canRemove || _canDeposit || _canWithdraw, "Wrong permissions set.");

        // Creating master privileges.
        self.admins[_newAdminAddress].canAdd = _canAdd;
        self.admins[_newAdminAddress].canRemove = _canRemove;
        self.admins[_newAdminAddress].canDeposit = _canDeposit;
        self.admins[_newAdminAddress].canWithdraw = _canWithdraw;
        emit adminAdded(msg.sender, _newAdminAddress,  _canAdd,  _canRemove,  _canDeposit,  _canWithdraw);
    }

    function removeAdmin(OrganData storage self, address _adminToRemove)
        public
    {
        // Check sender is allowed.
        require((self.masters[msg.sender].canRemove), "Not authorized to remove.");
        // Check affected account is admin.
        require(
            self.admins[_adminToRemove].canRemove ||
            self.admins[_adminToRemove].canAdd ||
            self.admins[_adminToRemove].canDeposit ||
            self.admins[_adminToRemove].canWithdraw,
            "Record not found."
        );

        // Deleting admin privileges.
        delete self.admins[_adminToRemove];
        emit adminRemoved(msg.sender, _adminToRemove);
    }

    function replaceAdmin(
        OrganData storage self, address _adminToRemove, address _adminToAdd,
        bool _canAdd, bool _canRemove, bool _canDeposit, bool _canWithdraw
    )
        public
    {
        // Check sender is allowed.
        require((self.masters[msg.sender].canAdd) && (self.masters[msg.sender].canRemove), "Not authorized to replace.");
        // Check new admin has at least one permission activated.
        require(_canAdd || _canRemove || _canDeposit || _canWithdraw, "Wrong permissions set.");

        removeAdmin(self, _adminToRemove);
        addAdmin(self, _adminToAdd, _canAdd, _canRemove, _canDeposit, _canWithdraw);
    }

    function addNorm(OrganData storage self, address payable _normAddress, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize)
        public returns (uint _normPosition)
    {
        // Check sender is allowed.
        require(self.admins[msg.sender].canAdd, "Not authorized to add.");

        // If the norm has an address, we check that the address has not been used before.
        if (_normAddress != address(0)) {
            require(self.addressPositionInNorms[_normAddress] == 0, "Duplicate record.");
        }

        // Adding the norm.
        self.norms.push(Norm({
            normAddress: _normAddress,
            ipfsHash: _ipfsHash,
            hashFunction: _hashFunction,
            hashSize: _hashSize
        }));
        // Registering norm position relative to its address.
        self.addressPositionInNorms[_normAddress] = self.norms.length - 1;
        // Incrementing norms counter.
        self.normsCount += 1;
        emit normAdded(msg.sender, _normAddress,  _ipfsHash,  _hashFunction,  _hashSize);

        // Registering the address as active
        return self.addressPositionInNorms[_normAddress] ;
    }

    function removeNorm(OrganData storage self, uint _normIndex)
        public
    {
        // Check sender is allowed:
        // - Sender is admin.
        // - Norm number is trying to delete himself.
        require(
            self.admins[msg.sender].canRemove ||
            (
                self.addressPositionInNorms[self.norms[_normIndex].normAddress] != 0 &&
                msg.sender == self.norms[_normIndex].normAddress
            ),
            "Not authorized."
        );
        // Deleting norm position from addressPositionInNorms.
        delete self.addressPositionInNorms[self.norms[_normIndex].normAddress];
        // Logging event.
        emit normRemoved(
            msg.sender, self.norms[_normIndex].normAddress,
            self.norms[_normIndex].ipfsHash,  self.norms[_normIndex].hashFunction,  self.norms[_normIndex].hashSize
        );

        // Removing norm from norms.
        delete self.norms[_normIndex];
        self.normsCount -= 1;
    }

    function replaceNorm(
        OrganData storage self, uint _normIndex, address payable _normAddress,
        bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize
    )
        public
    {
        require(self.admins[msg.sender].canRemove && self.admins[msg.sender].canAdd, "Not authorized to replace.");
        if (_normAddress != address(0)) {
            require(self.addressPositionInNorms[_normAddress] != 0, "Record not found.");
        }

        self.addressPositionInNorms[self.norms[_normIndex].normAddress] = 0;
        emit normRemoved(
            msg.sender, self.norms[_normIndex].normAddress,
            self.norms[_normIndex].ipfsHash,  self.norms[_normIndex].hashFunction,  self.norms[_normIndex].hashSize
        );

        delete self.norms[_normIndex];
        self.norms[_normIndex] = Norm({
            normAddress: _normAddress,
            ipfsHash: _ipfsHash,
            hashFunction: _hashFunction,
            hashSize: _hashSize
        });

        self.addressPositionInNorms[_normAddress] = _normIndex;
        emit normAdded(msg.sender, _normAddress,  _ipfsHash,  _hashFunction,  _hashSize);
    }
}