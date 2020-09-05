// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "./Kelsen.sol";
import "./libraries/ProcedureLibrary.sol";

/*
    A procedure defines a set of operations compiled in a move.
    The procedure dictates the way the move can be applied.

    @TODO : Add moves getters.
*/

contract Procedure is Kelsen(false, true) {
    using ProcedureLibrary for ProcedureLibrary.ProcedureData;
    ProcedureLibrary.ProcedureData private procedureData;

    /**
        Modifiers.
    */

    modifier onlyInOrgan(address payable organAddress) {
        require(ProcedureLibrary.isInOrgan(organAddress, msg.sender), "Not authorized");
        _;
    }

    /**
        Procedure constructor.
    */

    constructor (bytes32 metadataIpfsHash, uint8 metadataHashFunction, uint8 metadataHashSize)
        public
    {
        procedureData.init(metadataIpfsHash, metadataHashFunction, metadataHashSize);
    }

    /**
        Internal API.
        A procedure must call this method itself.
    */

    function applyMove(uint256 moveKey)
        internal
    {
        procedureData.applyMove(moveKey);
    }

    /**
        Public API : Procedure Metadata and Admin.
    */

    function updateMetadata(bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
        public
    {
        procedureData.updateMetadata(ipfsHash, hashFunction, hashSize);
    }

    function updateAdmin(address payable admin)
        public
    {
        procedureData.updateAdmin(admin);
    }

    /**
        Public API : Moves creation and update.
    */

    function createMove(bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
        public returns (uint256)
    {
        return procedureData.createMove(ipfsHash, hashFunction, hashSize);
    }

    function moveAddEntry(
        uint256 moveKey, address payable organ, address payable addr,
        bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize, bool lock
    )
        public
    {
        procedureData.moveAddEntry(moveKey, organ, addr, ipfsHash, hashFunction, hashSize, lock);
    }

    function moveRemoveEntry(
        uint256 moveKey, address payable organ, uint index, bool lock
    )
        public
    {
        procedureData.moveRemoveEntry(moveKey, organ, index, lock);
    }

    function moveReplaceEntry(
        uint256 moveKey, address payable organ, uint index, address payable addr,
        bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize, bool lock
    )
        public
    {
        procedureData.moveReplaceEntry(moveKey, organ, index, addr, ipfsHash, hashFunction, hashSize, lock);
    }

    function moveAddProcedure(
        uint256 moveKey, address payable organ, address procedure, bytes2 permissions, bool lock
    )
        public
    {
        procedureData.moveAddProcedure(moveKey, organ, procedure, permissions, lock);
    }

    function moveRemoveProcedure(
        uint256 moveKey, address payable organ, address procedure, bool lock
    )
        public
    {
        procedureData.moveRemoveProcedure(moveKey, organ, procedure, lock);
    }

    function moveReplaceProcedure(
        uint256 moveKey, address payable organ,
        address oldProcedure, address newProcedure, bytes2 permissions, bool lock
    )
        public
    {
        procedureData.moveReplaceProcedure(moveKey, organ, oldProcedure, newProcedure, permissions, lock);
    }

    function moveCall(
        uint256 moveKey, bytes memory call,  bool lock
    )
        public
    {
        procedureData.moveCall(moveKey, call, lock);
    }

    function moveReceiveCollectible(
        uint256 moveKey, address payable organ, address operator, address target, uint256 token_id, bool lock
    )
        public
    {
        procedureData.moveReceiveCollectible(moveKey, organ, operator, target, token_id, lock);
    }

    function moveTransferCollectible(
        uint256 moveKey, address payable organ, address operator, address target, uint256 token_id, bool lock
    )
        public
    {
        procedureData.moveTransferCollectible(moveKey, organ, operator, target, token_id, lock);
    }

    function moveReceiveCoins(
        uint256 moveKey, address payable organ, address operator, address target, uint256 value, bool lock
    )
        public
    {
        procedureData.moveReceiveCoins(moveKey, organ, operator, target, value, lock);
    }

    function moveTransferCoins(
        uint256 moveKey, address payable organ, address operator, address target, uint256 value, bool lock
    )
        public
    {
        procedureData.moveTransferCoins(moveKey, organ, operator, target, value, lock);
    }

    function moveReceiveEther(
        uint256 moveKey, address payable organ, address target, uint256 value, bool lock
    )
        public
    {
        procedureData.moveReceiveEther(moveKey, organ, target, value, lock);
    }

    function moveTransferEther(
        uint256 moveKey, address payable organ, address target, uint256 value, bool lock
    )
        public
    {
        procedureData.moveTransferEther(moveKey, organ, target, value, lock);
    }

    function lockMove(uint256 moveKey)
        public
    {
        procedureData.lockMove(moveKey);
    }
}