pragma solidity >=0.4.22 <0.7.0;

import "../Organ.sol";

/*
    Kelsen Framework - Procedure library.
    This library holds the logic common to all procedures
*/

library ProcedureLibrary {
    struct ProcedureData {
        bytes32 metadataIpfsHash;
        uint8 metadataHashFunction;
        uint8 metadataHashSize;
        address payable admin;
    }

    /*
        Events.
    */

    event metadataUpdated(address _from, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize);
    event adminUpdated(address _from, address payable _admin);

    /*
        Procedure management.
    */

    function init(
        ProcedureData storage self,
        bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize
    )
        public
    {
        self.metadataIpfsHash = _ipfsHash;
        self.metadataHashFunction = _hashFunction;
        self.metadataHashSize = _hashSize;
        self.admin = msg.sender;
    }

    function updateAdmin(
        ProcedureData storage self,
        address payable _admin
    )
        public
    {
        // Only the procedure's admin can update admin.
        Organ authorizedUsersOrgan = Organ(self.admin);
        require(msg.sender == self.admin || authorizedUsersOrgan.getNormIndexByAddress(msg.sender) != 0, "Not authorized.");
        delete authorizedUsersOrgan;

        self.admin = _admin;
        emit adminUpdated(msg.sender, _admin);
    }

    function updateMetadata(
        ProcedureData storage self,
        bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize
    )
        public
    {
        // Only the procedure's admin can update metadata.
        Organ authorizedUsersOrgan = Organ(self.admin);
        require(msg.sender == self.admin || authorizedUsersOrgan.getNormIndexByAddress(msg.sender) != 0, "Not authorized.");
        delete authorizedUsersOrgan;

        self.metadataIpfsHash = _ipfsHash;
        self.metadataHashFunction = _hashFunction;
        self.metadataHashSize = _hashSize;
        emit metadataUpdated(msg.sender, _ipfsHash, _hashFunction, _hashSize);
    }

    function checkAuthorization(address payable _organAddress)
        internal view
    {
        // Verifying the evaluator is an admin.
        Organ authorizedUsersOrgan = Organ(_organAddress);
        require(authorizedUsersOrgan.getNormIndexByAddress(msg.sender) != 0, "Not authorized.");
        delete authorizedUsersOrgan;
    }

}