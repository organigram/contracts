pragma solidity >=0.4.22 <0.7.0;

/// @title Standard Kelsen Procedure contract.

import "./Kelsen.sol";
import "./libraries/procedureLibrary.sol";

contract Procedure is Kelsen(false,true) {
    using ProcedureLibrary for address;
    using ProcedureLibrary for ProcedureLibrary.ProcedureData;
    ProcedureLibrary.ProcedureData public procedureData;

    // Stores factory that created the procedure.
    address public factory;

    constructor (bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize)
        public
    {
        factory = msg.sender;
        procedureData.init(_metadataIpfsHash, _metadataHashFunction, _metadataHashSize);
    }

    function updateMetadata(bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize)
        public
    {
        procedureData.updateMetadata(_ipfsHash, _hashFunction, _hashSize);
    }

    function updateAdmin(address payable _admin)
        public
    {
        procedureData.updateAdmin(_admin);
    }
}