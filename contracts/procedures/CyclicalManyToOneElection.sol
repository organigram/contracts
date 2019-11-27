pragma solidity >=0.4.22 <0.7.0;

import "../Procedure.sol";
import "../Organ.sol";
import "../libraries/CyclicalElectionLibrary.sol";

contract CyclicalManyToOneElectionProcedure is Procedure {
    using CyclicalElectionLibrary for CyclicalElectionLibrary.CyclicalElectionData;
    using CyclicalElectionLibrary for CyclicalElectionLibrary.Candidacy;
    using CyclicalElectionLibrary for CyclicalElectionLibrary.Election;

    CyclicalElectionLibrary.CyclicalElectionData public cyclicalElectionData;
    CyclicalElectionLibrary.Election public currentElection;
    address payable public votersOrganContract;
    address payable public affectedOrganContract;
    address payable public elected;

    constructor (
        address payable _votersOrganContract, address payable _affectedOrganContract,
        uint _frequency, uint _votingDuration, uint _quorumSize, uint _mandatesMaximum,
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize
    )
        public
    {
        procedureData.init(_metadataIpfsHash, _metadataHashFunction, _metadataHashSize);
        votersOrganContract = _votersOrganContract;
        affectedOrganContract = _affectedOrganContract;
        // Candidacy duration is set to 2 times voting duration.
        // Voters to candidates ratio is set to 0 for many-to-one elections.
        cyclicalElectionData.init(_frequency, _votingDuration, _quorumSize, _mandatesMaximum, 2 * _votingDuration, 0);
    }

    // Create a new election.
    function createElection(bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize)
        public
    {
        cyclicalElectionData.createElection(currentElection, _metadataIpfsHash, _metadataHashFunction, _metadataHashSize);
    }

    // Present candidacy.
    function presentCandidacy(bytes32 _proposalIpfsHash, uint8 _proposalHashFunction, uint8 _proposalHashSize)
        public
    {
        // Check that the candidate is a member of the reference organ.
        ProcedureLibrary.checkAuthorization(votersOrganContract);
        cyclicalElectionData.presentCandidacy(currentElection, _proposalIpfsHash, _proposalHashFunction, _proposalHashSize);
    }

    // Vote for a candidate.
    function vote(address payable _candidate)
        public
    {
        ProcedureLibrary.checkAuthorization(votersOrganContract);
        cyclicalElectionData.voteManyToOne(currentElection, _candidate);
    }

    // The vote is finished and we close it. This triggers the outcome of the vote.
    function endElection()
        public returns (address electionWinner)
    {
        electionWinner = cyclicalElectionData.countManyToOne(currentElection, votersOrganContract);
        if (electionWinner != address(0)) {
            cyclicalElectionData.mandatesCounts[electionWinner] += 1;
            if (electionWinner != elected) {
                cyclicalElectionData.electCandidate(currentElection, electionWinner, elected, affectedOrganContract);
            }
            delete cyclicalElectionData.candidacies[electionWinner];
        }

        // Cleaning contract state from election but keeping index.
        uint electionIndex = currentElection.index;
        delete currentElection;
        currentElection.index = electionIndex;

        return electionWinner;
    }

    /*
        Utilities functions.
    */

    function currentCandidates()
        public view returns (address[] memory candidates)
    {
        return currentElection.candidates;
    }

    function latestElectionIVotedIn()
        public view returns (uint electionIndex)
    {
        return cyclicalElectionData.latestElectionIndexes[msg.sender];
    }

    function candidacyProposal(address _candidate)
        public view returns (bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize)
    {
        return (
            cyclicalElectionData.candidacies[_candidate].proposalIpfsHash,
            cyclicalElectionData.candidacies[_candidate].proposalHashFunction,
            cyclicalElectionData.candidacies[_candidate].proposalHashSize
        );
    }
}