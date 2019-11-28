pragma solidity >=0.4.22 <0.7.0;

import "../Procedure.sol";
import "../Organ.sol";
import "../libraries/CyclicalElectionLibrary.sol";

contract CyclicalManyToManyBordaElectionProcedure is Procedure {
    using CyclicalElectionLibrary for CyclicalElectionLibrary.CyclicalElectionData;
    using CyclicalElectionLibrary for CyclicalElectionLibrary.Candidacy;
    using CyclicalElectionLibrary for CyclicalElectionLibrary.Election;

    CyclicalElectionLibrary.CyclicalElectionData public cyclicalElectionData;
    CyclicalElectionLibrary.Election public currentElection;
    address payable public votersOrganContract;
    address payable public affectedOrganContract;

    // Keeping track of current moderators, next moderators and which election is the next to be enforced.
    address[] public currentModerators;
    address[] public nextModerators;
    uint public nextElectionToEnforce;

    constructor (
        address payable _votersOrganContract, address payable _affectedOrganContract,
        uint _frequency, uint _votingDuration, uint _quorumSize, uint _mandatesMaximum, uint _votersToCandidatesRatio,
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize
    ) Procedure (_metadataIpfsHash, _metadataHashFunction, _metadataHashSize)
        public
    {
        votersOrganContract = _votersOrganContract;
        affectedOrganContract = _affectedOrganContract;
        // Candidacy duration is set to 2 times voting duration.
        cyclicalElectionData.init(_frequency, _votingDuration, _quorumSize, _mandatesMaximum, 2 * _votingDuration, _votersToCandidatesRatio);
    }

    /// Create a new election.
    function createElection(bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize)
        public
    {
        cyclicalElectionData.createElection(currentElection, _metadataIpfsHash, _metadataHashFunction, _metadataHashSize);
        // Retrieving size of electorate.
        Organ votersRegistryOrgan = Organ(votersOrganContract);
        (,,,, uint normsCount) = votersRegistryOrgan.organData();
        delete votersRegistryOrgan;

        currentElection.electedCandidatesMaximum = normsCount / uint(cyclicalElectionData.votersToCandidatesRatio);
        if (currentElection.electedCandidatesMaximum == 0) {
            currentElection.electedCandidatesMaximum = 1;
        }
    }

    // Present candidacy.
    function presentCandidacy(bytes32 _proposalIpfsHash, uint8 _proposalHashFunction, uint8 _proposalHashSize)
        public
    {
        ProcedureLibrary.checkAuthorization(votersOrganContract);
        cyclicalElectionData.presentCandidacy(currentElection, _proposalIpfsHash, _proposalHashFunction, _proposalHashSize);
    }

    /// Vote for a candidate.
    function vote(address[] memory _candidatees)
        public
    {
        ProcedureLibrary.checkAuthorization(votersOrganContract);
        cyclicalElectionData.voteManyToManyBorda(currentElection, _candidatees);
    }

    // Close the vote.
    function endElection()
        public
    {
        cyclicalElectionData.countManyToManyBorda(currentElection, nextModerators, votersOrganContract);
    }

    // Elect the winner.
    function enforceElection()
        public
    {
        // Checking the ballot is indeed the next one to be enforced
        require(currentElection.index >= nextElectionToEnforce, "A previous election needs to be enforced.");

        cyclicalElectionData.enforceManyToManyBorda(currentElection, nextModerators, currentModerators, affectedOrganContract);

        nextElectionToEnforce = currentElection.index + 1;

        delete currentElection;
        currentElection.index = nextElectionToEnforce;
        // Removing data of nextModerators
        delete nextModerators;
    }

    /*
        Utilities functions.
    */

    function getCandidates()
        public view returns (address[] memory candidates)
    {
        return currentElection.candidates;
    }

    function getLatestElectionIVotedIn()
        public view returns (uint electionIndex)
    {
        return cyclicalElectionData.latestElectionIndexes[msg.sender];
    }

    function getCandidacyProposal(address _candidate)
        public view returns (bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
    {
        return (
            cyclicalElectionData.candidacies[_candidate].proposalIpfsHash,
            cyclicalElectionData.candidacies[_candidate].proposalHashFunction,
            cyclicalElectionData.candidacies[_candidate].proposalHashSize
        );
    }
}

contract CyclicalManyToManyBordaElectionProcedureFactory is ProcedureFactory {
    function createProcedure(
        address payable _votersOrganContract, address payable _affectedOrganContract,
        uint _frequency, uint _votingDuration, uint _quorumSize, uint _mandatesMaximum, uint _votersToCandidatesRatio,
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize
    )
        public returns (address)
    {
        // @TODO : Add check that gas can cover deployment.
        address _contractAddress = address(new CyclicalManyToManyBordaElectionProcedure(
            _votersOrganContract, _affectedOrganContract,
            _frequency, _votingDuration, _quorumSize, _mandatesMaximum, _votersToCandidatesRatio,
            _metadataIpfsHash, _metadataHashFunction, _metadataHashSize
        ));
        // Call ProcedureFactory.registerProcedure to register the new contract and returns an address.
        return registerProcedure(_contractAddress);
    }
}