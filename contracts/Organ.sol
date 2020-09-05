// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "./Kelsen.sol";
import "./libraries/OrganLibrary.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
    An organ contains a list of entries and a set of procedures.
    A procedure is a contract that can effect changes on organs.
    An entry can be a document and/or an address (a wallet or a contract).
*/

contract Organ is
    Kelsen(true,false),
    IERC777Recipient,
    IERC777Sender,
    IERC721Receiver
{
    using OrganLibrary for OrganLibrary.OrganData;

    OrganLibrary.OrganData internal organData;

    /**
        Modifiers.
    */

    // modifier onlyRole(bytes32 role) {
    //     require(hasRole(role, msg.sender), "Not authorized.");
    //     _;
    // }

    /**
        Organ API.
    */

    constructor(address payable admin, bytes32 metadataIpfsHash, uint8 metadataHashFunction, uint8 metadataHashSize)
        public
    {
        organData.init(admin, metadataIpfsHash, metadataHashFunction, metadataHashSize);
    }

    // Assets.

    receive() external payable {
        organData.receiveEther(msg.value);
    }

    // @TODO : Protect ether transfers against re-entrancy attacks.
    function transfer(address payable to, uint256 value)
        public // onlyRole(OrganLibrary.PROCEDURE_ADDER)
    {
        organData.transferEther(to, value);
    }

    // Implementing ERC-777 receiver interface.
    function tokensReceived(
        address operator, address from, address to, uint256 amount,
        bytes calldata /*data*/, bytes calldata /*operatorData*/
    )
        external override // onlyRole(OrganLibrary.ERC777_RECEIVER)
    {
        organData.receiveCoins(operator, from, to, amount);
    }
    function tokensToSend(
        address operator, address from, address to, uint256 amount,
        bytes calldata /*userData*/, bytes calldata /*operatorData*/
    )
        external override // onlyRole(OrganLibrary.ERC777_TRANSFERRER)
    {
        organData.transferCoins(operator, from, to, amount);
    }
    function transferCoins(address operator, address from, address to, uint256 amount)
        external // onlyRole(OrganLibrary.ERC721_TRANSFERRER)
    {
        organData.transferCoins(operator, from, to, amount);
    }

    // Implementing ERC-721 receiver interface.
    function onERC721Received(
        address operator, address from, uint256 tokenId, bytes memory /*data*/
    )
        public override
        returns(bytes4)
    {
        organData.receiveCollectible(operator, from, tokenId);
        return this.onERC721Received.selector;
    }

    function updateMetadata(bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
        public // onlyRole(OrganLibrary.METADATA_UPDATER)
    {
        organData.updateMetadata(ipfsHash, hashFunction, hashSize);
    }

    /*
        API for Procedure contract.
    */

    function addEntry(address payable addr, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
        public // onlyRole(OrganLibrary.ENTRY_ADDER)
        returns (uint index)
    {
        return organData.addEntry(addr, ipfsHash, hashFunction, hashSize);
    }

    function removeEntry(uint index)
        public // onlyRole(OrganLibrary.ENTRY_REMOVER)
    {
       organData.removeEntry(index);
    }

    function replaceEntry(uint index, address payable addr, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
        public
    {
       organData.replaceEntry(index, addr, ipfsHash, hashFunction, hashSize);
    }

    function addProcedure(address procedure, bytes2 permissions)
        public // onlyRole(OrganLibrary.PROCEDURE_ADDER)
    {
        organData.addProcedure(procedure, permissions);
    }

    function removeProcedure(address procedure)
        public // onlyRole(OrganLibrary.PROCEDURE_REMOVER)
    {
        organData.removeProcedure(procedure);
    }

    function replaceProcedure(address oldProcedure, address newProcedure, bytes2 permissions)
        public
        // onlyRole(OrganLibrary.PROCEDURE_REMOVER)
    {
        organData.replaceProcedure(oldProcedure, newProcedure, permissions);
    }

    /*
        Accessors.
    */

    // function getPermissions(address addr)
    //     public view returns (
    //         bytes2 permissions,
    //         bool canRemoveProcedures,
    //         bool canAddProcedures,
    //         bool canRemoveEntries,
    //         bool canAddEntries,
    //         bool canTransferCollectibles,
    //         bool canReceiveCollectibles,
    //         bool canTransferCoins,
    //         bool canReceiveCoins,
    //         bool canTransferEther,
    //         bool canReceiveEther
    //     )
    // {
    //     const Roles
    //     // ;
    //     // permissions = organData.permissions[addr];
    //     (canRemoveProcedures,,,,,,,,) = organData.getRoles()
    //     return (
    //         permissions,
    //     );
    // }

    function getEntriesLength()
        public view returns (uint length)
    {
        return organData.entries.length;
    }

    function getEntryIndexForAddress(address addr)
        public view returns (uint index)
    {
        return organData.addressIndexInEntries[addr];
    }

    function getEntry(uint index)
        public view returns (
            address addr,
            bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
        )
    {
        return (
            organData.entries[index].addr,
            organData.entries[index].ipfsHash,
            organData.entries[index].hashFunction,
            organData.entries[index].hashSize
        );
    }

    function getProceduresLength()
        public view returns (uint256 length)
    {
        return organData.getProceduresLength();
    }

    function getProcedure(uint256 index)
        public view returns (address procedure, bytes2 permissions)
    {
        return organData.getProcedure(index);
    }

    function getPermissions(address procedure)
        public view returns (bytes2 permissions)
    {
        return organData.getPermissions(procedure);
    }

    function getMetadata()
        public view returns (bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
    {
        return organData.getMetadata();
    }
}