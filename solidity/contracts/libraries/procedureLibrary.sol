pragma solidity ^0.4.24;

import "../Organ.sol";

/**

Kelsen Framework
Procedure library
This library is used to hold the logic common to all procedures

**/
library procedureLibrary {
  
    struct ProcedureData 
    {
        int procedureTypeNumber;
        string procedureName;
        uint linkedOrgans;
    }

    struct oneRegisteredOrgan
    {
        address firstOrganAddress;
    }

    struct twoRegisteredOrgans
    {
        address firstOrganAddress;
        address secondOrganAddress;
    }

    struct threeRegisteredOrgans
    {
        address firstOrganAddress;
        address secondOrganAddress;
        address thirdOrganAddress;
    }

    struct fourRegisteredOrgans
    {
        address firstOrganAddress;
        address secondOrganAddress;
        address thirdOrganAddress;
        address fourthOrganAddress;
    }

    function initProcedure(ProcedureData storage self, int _procedureTypeNumber, string _procedureName, uint _linkedOrgans)
    public
    {
        self.procedureTypeNumber = _procedureTypeNumber;
        self.procedureName = _procedureName;
        self.linkedOrgans = _linkedOrgans;
    }

    function initOneRegisteredOrgan(oneRegisteredOrgan storage self, address _firstOrganAddress)
    public
    {
        self.firstOrganAddress = _firstOrganAddress;
    }

    function initTwoRegisteredOrgans(twoRegisteredOrgans storage self, address _firstOrganAddress, address _secondOrganAddress)
    public
    {
        self.firstOrganAddress = _firstOrganAddress;
        self.secondOrganAddress = _secondOrganAddress;
    }

    function initThreeRegisteredOrgans(threeRegisteredOrgans storage self, address _firstOrganAddress, address _secondOrganAddress, address _thirdOrganAddress)
    public
    {
        self.firstOrganAddress = _firstOrganAddress;
        self.secondOrganAddress = _secondOrganAddress;
        self.thirdOrganAddress = _thirdOrganAddress;
    }

    function initFourRegisteredOrgans(fourRegisteredOrgans storage self, address _firstOrganAddress, address _secondOrganAddress, address _thirdOrganAddress, address _fourthOrganAddress)
    public
    {
        self.firstOrganAddress = _firstOrganAddress;
        self.secondOrganAddress = _secondOrganAddress;
        self.thirdOrganAddress = _thirdOrganAddress;
        self.fourthOrganAddress = _fourthOrganAddress;
    }

    function isAllowed(address _organAddress)
    public
    view
    {
      // Verifying the evaluator is an admin
      Organ authorizedUsersOrgan = Organ(_organAddress);

      require(authorizedUsersOrgan.getAddressPositionInNorm(msg.sender) != 0);
      delete _organAddress;
    }

}