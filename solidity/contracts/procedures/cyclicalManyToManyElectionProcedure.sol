pragma solidity >=0.4.22 <0.6.0;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../Organ.sol";
import "../libraries/votingLibrary.sol";


contract cyclicalManyToManyElectionProcedure is Procedure{
    // 1: Cyclical many to one election (Presidential Election)
    // 2: Cyclical many to many election (Moderators Election)
    // 3: Simple norm nomination 
    // 4: Simple admins and master nomination
    // 5: Vote on Norms 
    // 6: Vote on masters and admins 
    // 7: Cooptation

    using procedureLibrary for procedureLibrary.twoRegisteredOrgans;
    using votingLibrary for votingLibrary.RecurringElectionInfo;
    using votingLibrary for votingLibrary.Candidacy;
    using votingLibrary for votingLibrary.ElectionBallot;

    // First stakeholder address is referenceOrganContract
    // Second stakeholder address is affectedOrganContract
    procedureLibrary.twoRegisteredOrgans public linkedOrgans;
    votingLibrary.RecurringElectionInfo public electionParameters;

    // Keeping track of current moderators, next moderators and which ballot is the next to be enforced
    address[] public currentModerators;
    address[] public nextModerators;
    uint public nextBallotToEnforce;

    // Ballot structure, instanciated once for every election cycle
    struct BallotExtra 
    {
        address[] winningCandidates;
    }

    // A dynamically-sized array of `Ballot` structs.
    //Ballot[] public ballots;
    votingLibrary.ElectionBallot[] public ballots;

    // Events
    event votedOnElectionEvent(address _from, uint _ballotNumber);
    event ballotWasCounted(uint _ballotNumber, address[] _candidateList, address[] _winningCandidates, uint _totalVoteCount);
    event ballotResultException(uint _ballotNumber, bool _wasRebooted);
    event ballotWasEnforced(address[] _winningCandidates, uint _ballotNumber);


    constructor(address _referenceOrganContract, address _affectedOrganContract, uint _ballotFrequency, uint _ballotDuration, uint _quorumSize, uint _reelectionMaximum, uint _voterToCandidateRatio, bytes32 _name) 
   
    public 
    {
        procedureInfo.initProcedure(2, _name, 2);
        linkedOrgans.initTwoRegisteredOrgans(_referenceOrganContract, _affectedOrganContract);
        electionParameters.initElectionParameters(_ballotFrequency, _ballotDuration, _quorumSize, _reelectionMaximum, 2*_ballotDuration, _voterToCandidateRatio);
    }

    /// Create a new ballot to choose one of `proposalNames`.
    function createBallot(bytes32 _ballotName) 
    public 
    returns (uint ballotNumber)
    {

        ballotNumber = electionParameters.createRecurrentBallotManyToOne(ballots, _ballotName);
        // Retrieving size of electorate
        Organ voterRegistryOrgan = Organ(linkedOrgans.firstOrganAddress);
        ( ,uint voterNumber) = voterRegistryOrgan.organInfos();

        ballots[ballotNumber].electedOfficialSlotNumber = voterNumber/uint(electionParameters.voterToCandidateRatio);
        if ( ballots[ballotNumber].electedOfficialSlotNumber == 0) 
        {
            ballots[ballotNumber].electedOfficialSlotNumber = 1;
        }
        delete voterRegistryOrgan;

        return ballotNumber;
    }

    function presentCandidacy(uint _ballotNumber, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) 
    public 
    {
        // Check the candidate is a member of the reference organ
        linkedOrgans.firstOrganAddress.isAllowed();

        // Check that the ballot is still active
        electionParameters.presentCandidacyLib(ballots[_ballotNumber], _ballotNumber, _ipfsHash, _hash_function, _size);    
    }

    /// Vote for a candidate
    function vote(uint _ballotNumber, address[] _candidateAddresses) 
    public 
    {
        linkedOrgans.firstOrganAddress.isAllowed();
        electionParameters.voteManyToMany(ballots[_ballotNumber], _ballotNumber, _candidateAddresses);
    }

    // The vote is finished and we close it. This triggers the outcome of the vote.

    function endBallot(uint _ballotNumber) 
    public 
    {
        electionParameters.countManyToMany(ballots[_ballotNumber], nextModerators, linkedOrgans.firstOrganAddress, _ballotNumber);
    }
    
    function enforceBallot(uint _ballotNumber) 
    public 
    {

        // Checking the ballot is indeed the next one to be enforced
        require(_ballotNumber >= nextBallotToEnforce);

        electionParameters.enforceManyToMany(ballots[_ballotNumber], nextModerators, currentModerators, linkedOrgans.secondOrganAddress, _ballotNumber);

        nextBallotToEnforce = _ballotNumber + 1;
        delete ballots[_ballotNumber];
        // Removing data of nextModerators
        delete nextModerators;
    }

    //////////////////////// Functions to communicate with other contracts
    function getCandidateList(uint _ballotNumber) 
    public 
    view 
    returns (address[] _candidateList)
    {
        return ballots[_ballotNumber].candidateList;
    }
    
    function nextElectionICanVoteIn() 
    public 
    view 
    returns (uint lastElectionIParticipatedIn)
    {
        return electionParameters.nextElectionUserCanVoteIn[msg.sender];
    }

    function getCandidacyInfo(address _candidateAddress) 
    public 
    view
    returns (bytes32 _ipfsHash, uint8 _hash_function, uint8 _size)
    {
        return (electionParameters.candidacies[_candidateAddress].ipfsHash, electionParameters.candidacies[_candidateAddress].hash_function , electionParameters.candidacies[_candidateAddress].size);
    }


}
