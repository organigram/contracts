pragma solidity >=0.4.22 <0.7.0;

/// @title Standard contract for a norm nomination.

import "../Procedure.sol";
import "../Organ.sol";

contract SimpleNormNominationProcedure is Procedure {

    address payable public authorizedNominatersOrgan;

    constructor (
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize,
        address payable _authorizedNominatersOrgan
    ) Procedure (_metadataIpfsHash, _metadataHashFunction, _metadataHashSize)
        public
    {
        authorizedNominatersOrgan = _authorizedNominatersOrgan;
        // Set members of authorizedNominatersOrgan as admins.
        procedureData.updateAdmin(_authorizedNominatersOrgan);
    }

    function addNorm(
        address payable _targetOrgan, address payable _normAdress,
        bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize
    )
        public returns (uint normIndex)
    {
        // Checking if caller is authorized.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the addNorm command to the desired organ.
        Organ targetOrganInstance = Organ(_targetOrgan);
        return targetOrganInstance.addNorm(_normAdress, _ipfsHash, _hashFunction, _hashSize);
    }

    function removeNorm(address payable _targetOrgan, uint _normIndex)
        public
    {
        // Checking if caller is authorized.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the addNorm command to the desired organ.
        Organ targetOrganInstance = Organ(_targetOrgan);
        targetOrganInstance.removeNorm(_normIndex);
    }

    function replaceNorm(
        address payable _targetOrgan, uint _oldNormIndex,
        address payable _newNormAdress, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _hashSize
    )
        public
    {
        // Checking if caller is authorized.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the replaceNorm command to the desired organ.
        Organ targetOrganInstance = Organ(_targetOrgan);
        targetOrganInstance.replaceNorm(_oldNormIndex, _newNormAdress, _ipfsHash, _hashFunction, _hashSize);
    }
}

contract SimpleNormNominationProcedureFactory is ProcedureFactory {
    function createProcedure(
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize,
        address payable _authorizedNominatersOrgan
    )
        public returns (address)
    {
        // @TODO : Add check that gas can cover deployment.
        address _contractAddress = address(new SimpleNormNominationProcedure(
            _metadataIpfsHash, _metadataHashFunction, _metadataHashSize,
            _authorizedNominatersOrgan
        ));
        // Call ProcedureFactory.registerProcedure to register the new contract and returns an address.
        return registerProcedure(_contractAddress);
    }
}