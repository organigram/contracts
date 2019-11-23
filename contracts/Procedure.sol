pragma solidity >=0.4.22 <0.7.0;

/// @title Standard Kelsen Procedure contract.

import "./Kelsen.sol";
import "./libraries/procedureLibrary.sol";

contract Procedure is Kelsen {
    using ProcedureLibrary for address;
    using ProcedureLibrary for ProcedureLibrary.ProcedureData;
    ProcedureLibrary.ProcedureData public procedureData;

    // Identifiers to adapt procedure interface
    bool public isOrgan = false;
    bool public isProcedure = true;

    constructor (bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize)
        public
    {
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
