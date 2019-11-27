pragma solidity >=0.4.22 <0.7.0;

/// @title Standard contract for an admin and master nomination.

import "../Procedure.sol";
import "../Organ.sol";

contract SimpleAdminAndMasterNominationProcedure is Procedure {

    address payable public authorizedNominatersOrgan;

    constructor (
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize,
        address payable _authorizedNominatersOrgan
    )
        public
    {
        procedureData.init(_metadataIpfsHash, _metadataHashFunction, _metadataHashSize);
        authorizedNominatersOrgan = _authorizedNominatersOrgan;
        // Set members of authorizedNominatersOrgan as admins.
        procedureData.updateAdmin(_authorizedNominatersOrgan);
    }

    function addAdmin(
        address payable _organToReform, address _newAdmin,
        bool _canAdd, bool _canRemove, bool _canDeposit, bool _canWithdraw
    )
        public
    {
        // Checking if caller is an admin.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the required command to the desired organ.
        Organ organToReformInstance = Organ(_organToReform);
        organToReformInstance.addAdmin(_newAdmin, _canAdd, _canRemove, _canDeposit, _canWithdraw);
    }

    function removeAdmin(address payable _organToReform, address _oldAdmin)
        public
    {
        // Checking if caller is an admin.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the required command to the desired organ.
        Organ organToReformInstance = Organ(_organToReform);
        organToReformInstance.removeAdmin(_oldAdmin);
    }

    function replaceAdmin(
        address payable _organToReform, address _oldAdmin, address _newAdmin,
        bool _canAdd, bool _canRemove, bool _canDeposit, bool _canWithdraw
    )
        public
    {
        // Checking if caller is an admin.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the required command to the desired organ.
        Organ organToReformInstance = Organ(_organToReform);
        organToReformInstance.replaceAdmin(_oldAdmin, _newAdmin, _canAdd, _canRemove, _canDeposit, _canWithdraw);
    }

    function addMaster(address payable _organToReform, address _newMaster, bool _canAdd, bool _canRemove)
        public
    {
        // Checking if caller is an admin.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the required command to the desired organ.
        Organ organToReformInstance = Organ(_organToReform);
        organToReformInstance.addMaster(_newMaster, _canAdd, _canRemove);
    }

    function removeMaster(address payable _organToReform, address _oldMaster)
        public
    {

        // Checking if caller is an admin.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the required command to the desired organ.
        Organ organToReformInstance = Organ(_organToReform);
        organToReformInstance.removeMaster(_oldMaster);
    }

    function replaceMaster(address payable _organToReform, address _oldMaster, address _newMaster, bool _canAdd, bool _canRemove)
        public
    {
        // Checking if caller is an admin.
        ProcedureLibrary.checkAuthorization(authorizedNominatersOrgan);

        // Sending the required command to the desired organ.
        Organ organToReformInstance = Organ(_organToReform);
        organToReformInstance.replaceMaster(_oldMaster, _newMaster, _canAdd, _canRemove);
    }

}