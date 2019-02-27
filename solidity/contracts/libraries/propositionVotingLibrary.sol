pragma solidity ^0.4.24;

import "../Organ.sol";

/**

Kelsen Framework
Procedure library
This library is used to hold the logic common to all procedures

**/
library propositionVotingLibrary {
  
    struct VotingProcessInfo 
    {
        uint quorumSize;
        uint votingPeriodDuration;
        uint promulgationPeriodDuration;
        uint majoritySize;
        uint nextPropositionNumber;
        // Mapping to track user participation
        mapping(address => uint256) userParticipation;
        mapping(uint => Proposition) propositions;
    }

        // Proposition structure
    struct Proposition 
    {
        //Authorization bools
        bool canAdd;  // if true, Admin can add norms
        bool canDelete;  // if true, Admin can delete norms
        bool canSpend;
        bool canDeposit;
        // Counting bools
        bool wasVetoed;
        bool wasCounted;
        bool wasAccepted;
        bool wasEnded;
        uint8 hash_function;
        uint8 size;
        uint8 propositionType;
        bytes32 ipfsHash; // ID of proposal on IPFS
        
        uint votingPeriodEndDate;
        uint voteFor;
        // uint voteAgainst;
        uint totalVoteCount;
        uint propositionNumber;
        // Proposition details
        address targetOrgan;
        address contractToAdd;
        address contractToRemove;
    }

    // Events

    event createPropositionEvent(address _from, address _targetOrgan, uint _propositionType, uint _propositionNumber);
    event createPropositionDetails(address _contractToAdd, address _contractToRemove);
    event createMasterPropositionEvent(uint _propositionNumber, bool _canAdd, bool _canDelete);
    event createAdminPropositionEvent(uint _propositionNumber, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend);
    event createNormPropositionEvent(uint _propositionNumber, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size);
    event voteOnProposition(address _from, uint _propositionNumber);
    event vetoProposition(address _from, uint _propositionNumber);


    function initElectionParameters(VotingProcessInfo storage self, uint _quorumSize, uint _votingPeriodDuration, uint _promulgationPeriodDuration, uint _majoritySize)
    public
    {
        self.quorumSize = _quorumSize;
        self.votingPeriodDuration = _votingPeriodDuration;
        self.promulgationPeriodDuration = _promulgationPeriodDuration;
        self.majoritySize = _majoritySize;
    }

    function getBoolean(uint256 _packedBools, uint256 _boolNumber)
    public 
    pure 
    returns(bool)
    {
        uint256 flag = (_packedBools >> _boolNumber) & uint256(1);
        return (flag == 1 ? true : false);
    }

    function setBoolean(uint256 _packedBools, uint256 _boolNumber, bool _value) 
    public 
    pure 
    returns(uint256) 
    {
        if (_value)
            return _packedBools | uint256(1) << _boolNumber;
        else
            return _packedBools & ~(uint256(1) << _boolNumber);
    }

        /// Create a new ballot to choose one of `proposalNames`.
    function createPropositionLib(VotingProcessInfo storage self, address _targetOrgan, address _contractToAdd, address _contractToRemove, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend, uint8 _propositionType) 
    public 
    returns (uint propositionNumber)
    {
        // Retrieving proposition details
        propositionNumber = self.nextPropositionNumber;

        self.propositions[propositionNumber].targetOrgan = _targetOrgan;
        self.propositions[propositionNumber].contractToAdd = _contractToAdd;
        self.propositions[propositionNumber].contractToRemove = _contractToRemove;
        self.propositions[propositionNumber].ipfsHash = _ipfsHash;
        self.propositions[propositionNumber].hash_function = _hash_function;
        self.propositions[propositionNumber].size = _size;
        self.propositions[propositionNumber].canAdd = _canAdd;
        self.propositions[propositionNumber].canDelete = _canDelete;
        self.propositions[propositionNumber].canSpend = _canSpend;
        self.propositions[propositionNumber].canDeposit = _canDeposit;
        self.propositions[propositionNumber].propositionType = _propositionType;
        self.propositions[propositionNumber].votingPeriodEndDate = now + self.votingPeriodDuration;            
        self.propositions[propositionNumber].wasVetoed = false;
        self.propositions[propositionNumber].wasEnded = false;
        self.propositions[propositionNumber].wasCounted = false;
        self.propositions[propositionNumber].wasAccepted = false;
        self.propositions[propositionNumber].totalVoteCount = 0;
        self.propositions[propositionNumber].voteFor = 0;
        self.propositions[propositionNumber].propositionNumber = propositionNumber;

        self.nextPropositionNumber += 1;

        // proposition creation event
        emit createPropositionEvent(msg.sender, _targetOrgan, _propositionType, propositionNumber);
        emit createPropositionDetails(_contractToAdd, _contractToRemove);
        if (_propositionType == 0)
        {
            // Master proposition event
            emit createMasterPropositionEvent(propositionNumber, _canAdd, _canDelete);
        }
        else if (_propositionType == 1)
        {
            // Admin proposition event
            emit createAdminPropositionEvent(propositionNumber, _canAdd, _canDelete, _canDeposit, _canSpend);
        }
        else if (_propositionType == 2)
        {
            // Norm proposition event
            emit createNormPropositionEvent(propositionNumber, _ipfsHash, _hash_function, _size);
        }

    }

        /// Vote for a proposition
    function voteLib(VotingProcessInfo storage self, Proposition storage proposition, bool _acceptProposition) 
    public 
    {
        // Check if voter already voted
        require(!getBoolean(self.userParticipation[msg.sender], proposition.propositionNumber));

        // Check if vote is still active
        require(!proposition.wasCounted);

        // Check if voting period ended
        require(proposition.votingPeriodEndDate > now);

        // Adding vote
        if(_acceptProposition == true)
        {
            proposition.voteFor += 1;
        }

        // Loggin that user voted
        setBoolean(self.userParticipation[msg.sender], proposition.propositionNumber, true);

        // Adding vote count
        proposition.totalVoteCount += 1;

        // create vote event
        emit voteOnProposition(msg.sender, proposition.propositionNumber);
    }

        /// Vote for a candidate
    function vetoLib(Proposition storage proposition) 
    public 
    {        
        // Check if vote is still active
        require(!proposition.wasCounted);

        // Check if voting period ended
        require(proposition.votingPeriodEndDate > now);

        // Log that proposition was vetoed
        proposition.wasVetoed = true;

        //  Create veto event
        emit vetoProposition(msg.sender, proposition.propositionNumber);
    }
}