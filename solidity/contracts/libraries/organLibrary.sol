pragma solidity ^0.4.24;



/**

Kelsen Framework
Organ library
This library is used to hold all the logic to manage a simple organ.

**/
library organLibrary {
  
    struct Master {
        string name; // Master name
        bool canAdd;  // if true, master can add admins
        bool canDelete;  // if true, master can delete admins
        uint rankInMasterList; // Rank in dynamic array masterList
    }

    struct Admin {
        string name; // Admin name
        bool canAdd;  // if true, Admin can add norms
        bool canDelete;  // if true, Admin can delete norms
        bool canSpend;
        bool canDeposit;
        uint rankInAdminList; // Rank in dynamic array adminList
    }

    struct Norm {
        string name; // Master name
        address normAddress; // Address if norm is a member or a contract
        bytes32 ipfsHash; // ID of proposal on IPFS
        uint8 hash_function;
        uint8 size;
    }

    struct OrganInfo {
        string organName;
        uint256 activeNormNumber;
        address[] masterList;
        address[] adminList;
        Norm[] norms;
        mapping(address => Master) masters;
        mapping(address => Admin) admins;
    }


}