// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "../Organ.sol";

/*
    Organigr.am Contracts Framework - Procedure library.
    This library holds the logic common to all procedures.

    A procedure can affect an organ by :
    - Adding, removing, replacing entries.
    - Adding, removing, replacing procedures.
    - Withdrawing funds and transferring them to another organ.
    The procedure can process several operations inside one move.
*/

library ProcedureLibrary {
    struct ProcedureData {
        Metadata metadata;
        address payable admin;
        mapping (uint256 => Move) moves;
        uint256 movesLength;
    }

    struct Metadata {
        bytes32 ipfsHash;
        uint8 hashFunction;
        uint8 hashSize;
    }

    struct Move {
        address payable creator;
        Metadata metadata;
        bool locked;
        bool applied;
        bool processing;
        Operation[] operations;
    }

    struct Operation {
        uint256 index;          // index will stay after reordering.
        uint8 operationType;   // avoid reading function signature.
        // Possible masks:
        // 0: operation on procedure.
        // 1/2/3: addEntry/removeEntry/replaceEntry.
        // 4/5/6: addProcedure/removeProcedure/replaceProcedure.
        // 7: withdraw funds.
        // 8: withdraw tokens.
        bytes call;
        bool processed;
    }

    /**
        Modifiers.
    */
    modifier onlyAdmin(ProcedureData storage self) {
        require(isInOrgan(self.admin, msg.sender), "Not authorized.");
        _;
    }
    modifier onlyMoveCreator(ProcedureData storage self, uint256 moveKey) {
        require(self.moves[moveKey].creator == msg.sender, "Not authorized.");
        _;
    }
    modifier onlyNewMove(ProcedureData storage self, uint256 moveKey) {
        require(
            !self.moves[moveKey].locked &&
            !self.moves[moveKey].applied &&
            !self.moves[moveKey].processing,
            "Not authorized."
        );
        _;
    }
    modifier onlyLockedMove(ProcedureData storage self, uint256 moveKey) {
        require(
            self.moves[moveKey].locked &&
            !self.moves[moveKey].applied &&
            !self.moves[moveKey].processing,
            "Not authorized."
        );
        _;
    }

    /**
        Events.
    */

    event metadataUpdated(address from, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize);
    event adminUpdated(address from, address payable admin);
    event moveCreated(address payable creator, uint256 moveKey);
    event moveApplied(uint256 moveKey);

    /*
        Procedure management.
    */

    function init(
        ProcedureData storage self, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
    )
        public
    {
        self.metadata = Metadata({
            ipfsHash: ipfsHash,
            hashFunction: hashFunction,
            hashSize: hashSize
        });
        self.admin = msg.sender;
    }

    function updateAdmin(ProcedureData storage self, address payable admin)
        public onlyAdmin(self)
    {
        self.admin = admin;
        emit adminUpdated(msg.sender, admin);
    }

    function updateMetadata(
        ProcedureData storage self, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
    )
        public onlyAdmin(self)
    {
        self.metadata = Metadata({
            ipfsHash: ipfsHash,
            hashFunction: hashFunction,
            hashSize: hashSize
        });
        emit metadataUpdated(msg.sender, ipfsHash, hashFunction, hashSize);
    }

    /**
        Utils.
    */
    function isInOrgan(address payable organ, address payable caller)
        public view returns (bool)
    {
        return organ == caller || Organ(organ).getEntryIndexForAddress(caller) != 0;
    }

    /**
        External API.
    */

    function applyMove(ProcedureData storage self, uint256 moveKey)
        internal onlyLockedMove(self, moveKey)
    {
        // Start processing.
        Move storage move = self.moves[moveKey];
        move.processing = true;
        // Process operations.
        for (uint256 i = 0; i < move.operations.length; ++i) {
            Operation storage operation = move.operations[i];
            operation.processed = true;
        }
        move.applied = true;
        emit moveApplied(moveKey);
    }

    function createMove(
        ProcedureData storage self,
        bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
    )
        internal returns (uint256)
    {
        // Moves is a mapping, its key starts at 1.
        uint256 moveKey = self.movesLength++;
        self.moves[moveKey].creator = msg.sender;
        self.moves[moveKey].metadata = Metadata({
            ipfsHash: ipfsHash,
            hashFunction: hashFunction,
            hashSize: hashSize
        });
        return moveKey;
    }

    /**
        Move API.
    */

    function moveAddEntry(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address payable addr,
        bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize,
        bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0x1715f4de, organ, addr, ipfsHash, hashFunction, hashSize),
            operationType: 1,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveRemoveEntry(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, uint index,
        bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0x76a6411c, organ, index),
            operationType: 2,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveReplaceEntry(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, uint index,
        address payable addr, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize,
        bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        Move storage move = self.moves[moveKey];
        move.operations.push(Operation({
            index: move.operations.length,
            call: abi.encodeWithSelector(0x155a73ce, organ, index, addr, ipfsHash, hashFunction, hashSize),
            operationType: 3,
            processed: false
        }));
        if (lock) {
            move.locked = true;
            emit moveCreated(move.creator, moveKey);
        }
    }

    function moveCall(
        ProcedureData storage self, uint256 moveKey,
        bytes memory call,  bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: call,
            operationType: 0,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveAddProcedure(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address procedure, bytes2 permissions,
        bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0x90b137e9, organ, procedure, permissions),
            operationType: 4,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveRemoveProcedure(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address procedure,
        bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0x19b9404c, organ, procedure),
            operationType: 5,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveReplaceProcedure(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address oldProcedure, address newProcedure, bytes2 permissions,
        bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0x5676c77d, organ, oldProcedure, newProcedure, permissions),
            operationType: 6,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveReceiveCollectible(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address operator, address /*target*/,
        uint256 tokenId, bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0xc1075329, organ, operator, tokenId),
            operationType: 7,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveTransferCollectible(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address operator, address target,
        uint256 tokenId, bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0x5e35359e, organ, operator, target, tokenId),
            operationType: 8,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveReceiveCoins(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address operator, address target, uint256 value,
        bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0xc1075329, organ, operator, target, value),
            operationType: 7,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveTransferCoins(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address operator, address target,
        uint256 value, bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0x5e35359e, organ, operator, target, value),
            operationType: 8,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveReceiveEther(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address target, uint256 value, bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0xc1075329, organ, target, value),
            operationType: 7,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function moveTransferEther(
        ProcedureData storage self, uint256 moveKey,
        address payable organ, address target, uint256 value, bool lock
    )
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].operations.push(Operation({
            index: self.moves[moveKey].operations.length,
            call: abi.encodeWithSelector(0x5e35359e, organ, target, value),
            operationType: 8,
            processed: false
        }));
        if (lock) {
            self.moves[moveKey].locked = true;
            emit moveCreated(self.moves[moveKey].creator, moveKey);
        }
    }

    function lockMove(ProcedureData storage self, uint256 moveKey)
        internal onlyMoveCreator(self, moveKey) onlyNewMove(self, moveKey)
    {
        self.moves[moveKey].locked = true;
        emit moveCreated(msg.sender, moveKey);
    }

    /**
        Private API.
    */

    function _addEntry(
        address payable organ, address payable addr,
        bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
    )
        private returns (uint index)
    {
        return Organ(organ).addEntry(addr, ipfsHash, hashFunction, hashSize);
    }

    function _removeEntry(address payable organ, uint index)
        private
    {
        Organ(organ).removeEntry(index);
    }

    function _replaceEntry(
        address payable organ, uint index,
        address payable addr, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
    )
        private
    {
        Organ(organ).replaceEntry(index, addr, ipfsHash, hashFunction, hashSize);
    }

    function _addProcedure(
        address payable targetOrgan, address procedure, bytes2 permissions
    )
        private
    {
        Organ(targetOrgan).addProcedure(procedure, permissions);
    }

    function _removeProcedure(
        address payable organ, address procedure
    )
        private
    {
        Organ(organ).removeProcedure(procedure);
    }

    function _replaceProcedure(
        address payable organ,
        address oldProcedure, address newProcedure, bytes2 permissions
    )
        private
    {
        Organ(organ).replaceProcedure(oldProcedure, newProcedure, permissions);
    }
}