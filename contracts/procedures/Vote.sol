// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "../Procedure.sol";
import "../libraries/VotePropositionLibrary.sol";

/*
    Vote Procedure.
    A Vote Procedure will apply an effect based on the decision of a vote.
    Votes can be vetoed, and enacted.

    @TODO : Add propositions getter.
*/

contract VoteProcedure is Procedure {
    using VotePropositionLibrary for VotePropositionLibrary.Proposition;
    address payable public votersOrgan;
    address payable public vetoersOrgan;
    address payable public enactorsOrgan;

    mapping (uint256 => VotePropositionLibrary.Proposition) internal propositions;
    uint256 internal propositionsCount;

    constructor (
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize,
        address payable _votersOrgan, address payable _vetoersOrgan, address payable _enactorsOrgan
    ) Procedure (_metadataIpfsHash, _metadataHashFunction, _metadataHashSize)
        public
    {
        votersOrgan = _votersOrgan;
        vetoersOrgan = _vetoersOrgan;
        enactorsOrgan = _enactorsOrgan;
    }

    function propose(
        uint256 effectKey, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize
    )
        public returns (uint256 propositionKey)
    {
        propositionKey = propositionsCount + 1; // keys start at 1.
        require(propositionKey > propositionsCount, "Out of bound.");
        propositions[propositionKey].init(effectKey, ipfsHash, hashFunction, hashSize);
        return propositionsCount++;
    }

    function vote(uint256 propositionKey, bool approval)
        public onlyInOrgan(votersOrgan)
    {
        propositions[propositionKey].vote(approval);
    }

    // A veto accepts arguments which defines a motivation as a IPFS multihash.
    function veto(uint256 propositionKey, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
        public onlyInOrgan(vetoersOrgan)
    {
        propositions[propositionKey].veto(ipfsHash, hashFunction, hashSize);
    }

    function count(uint256 propositionKey)
        public view returns (bool)
    {
        return propositions[propositionKey].count();
    }

    function enact(uint256 propositionKey)
        public onlyInOrgan(enactorsOrgan)
    {
        // proposition.count() returns true if enactment is possible.
        require (propositions[propositionKey].count(), "Not authorized");
        Procedure.applyMove(propositions[propositionKey].moveKey);
        propositions[propositionKey].enact();
    }
}