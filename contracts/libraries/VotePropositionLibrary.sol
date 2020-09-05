// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

/*
    Library for a vote.
    Stores how votes, vetoes and enactment operates.
*/

library VotePropositionLibrary {
    struct Proposition {
        address payable creator;
        uint256 moveKey;
        // Creation.
        // Metadata can describe a proposition.
        // Cannot be updated after creation.
        Metadata metadata;
        bool created;
        uint256 quorumSize;
        uint256 voteDuration;
        uint256 enactmentDuration;
        uint256 majoritySize;
        // Vote.
        // Map voters' addresses to votes.
        mapping(address => Vote) votes;
        address[] voters;
        uint256 votesCount;
        // Veto.
        address payable vetoer;
        Metadata vetoMetadata;
        // Enactment.
        address payable enactor;
    }

    struct Metadata {
        bytes32 ipfsHash;
        uint8 hashFunction;
        uint8 hashSize;
    }

    struct Vote {
        bool voted;
        bool approved;
    }

    /*
        Proposition management.
    */

    function init(
        Proposition storage self,
        uint256 moveKey, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
    )
        public
    {
        self.moveKey = moveKey;
        self.metadata = Metadata({
            ipfsHash: ipfsHash,
            hashFunction: hashFunction,
            hashSize: hashSize
        });
        self.creator = msg.sender;
    }

    function vote(
        Proposition storage self,
        bool approval
    )
        public
    {
        self.votes[msg.sender] = Vote({
            voted: true,
            approved: approval
        });
        self.voters.push(msg.sender);
        self.votesCount++;
    }

    function veto(
        Proposition storage self,
        bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
    )
        public
    {
        self.vetoer = msg.sender;
        self.vetoMetadata = Metadata({
            ipfsHash: ipfsHash,
            hashFunction: hashFunction,
            hashSize: hashSize
        });
    }

    function count(Proposition storage self)
        public view returns (bool)
    {
        // @TODO : returns boolean.
        uint256 approval;
        for (uint256 i = 0; i < self.voters.length; i++) {
            if (self.votes[self.voters[i]].voted && self.votes[self.voters[i]].approved) {
                approval++;
            }
        }
        return true;
    }

    function enact(Proposition storage self)
        public
    {
        self.enactor = msg.sender;
    }
}