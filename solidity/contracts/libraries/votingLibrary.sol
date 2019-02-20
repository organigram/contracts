pragma solidity ^0.4.24;

import "../Organ.sol";

/**

Kelsen Framework
Procedure library
This library is used to hold the logic common to all procedures

**/
library votingLibrary {
  
    struct VotingProcessInfo 
    {
        uint startDate;
        uint votingPeriodEndDate;
        bool wasVetoed;
        bool wasCounted;
        bool wasAccepted;
        bool wasEnded;
        uint voteFor;
        uint totalVoteCount;
        mapping(address => bool) hasUserVoted;
    }

    struct RecurringElectionInfo 
    {
        uint ballotFrequency;
        // Max parallel election running
        uint nextElectionDate;
        // Time to vote
        uint ballotDuration;
        // Time to declare as a candidate
        uint candidacyDuration;
        // Maximum time someone can be candidate
        uint reelectionMaximum;
        // Minimum participation to validate election
        uint quorumSize;
        // A mapping of candidacy status and number of candidacies per member
        mapping(address => uint) cumulatedCandidacies;
        // // Is blank vote accepted
        // bool neutralVoteAccepted;
    }

    // Candidacies structure, to keep track of candidacies for an election
    struct Candidacy 
    {
        address candidateAddress;
        bytes32 ipfsHash; // ID of proposal on IPFS
        uint8 hash_function;
        uint8 size;
        uint voteNumber;
    }

    struct ElectionBallot 
    {
        bytes32 name;   // short name (up to 32 bytes)
        uint startDate;
        uint candidacyEndDate;
        uint electionEndDate;
        bool wasEnded;
        uint totalVoteCount;
        address[] candidateList;
        mapping(address => bool) hasUserVoted;
        mapping(address => Candidacy) candidacies;
    }

    // Events
    event ballotCreationEvent(address _from, bytes32 _name, uint _startDate, uint _candidacyEndDate, uint _endDate, uint _ballotNumber);
    event presentCandidacyEvent(uint _ballotNumber, address _candidateAddress, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size);
    event votedOnElectionEvent(address _from, uint _ballotNumber);
    event ballotWasCounted(uint _ballotNumber, address[] _candidateList, address _winningCandidate, uint _totalVoteCount);
    event ballotResultException(uint _ballotNumber);
    event ballotWasEnforced(address _winningCandidate, uint _ballotNumber);

    function initElectionParameters(RecurringElectionInfo storage self, uint _ballotFrequency, uint _ballotDuration, uint _quorumSize, uint _reelectionMaximum, uint _candidacyDuration)
    public
    {
        self.ballotFrequency = _ballotFrequency;
        self.nextElectionDate = now;
        self.ballotDuration = _ballotDuration;
        self.quorumSize = _quorumSize;
        self.reelectionMaximum = _reelectionMaximum;
        self.candidacyDuration = _candidacyDuration;
    }

    function createRecurrentBallotManyToOne(RecurringElectionInfo storage self, ElectionBallot[] storage ballots, bytes32 _ballotName) 
    public 
    returns (uint ballotNumber)
    {
        // Checking that election date has passed
        require (now > self.nextElectionDate);
        // Checking if previous ballot was counted
        if (ballots.length > 0) 
        {
            require(ballots[ballots.length - 1].wasEnded);
        }

        ElectionBallot memory newBallot;
        newBallot.name = _ballotName;
        newBallot.startDate = now;
        newBallot.candidacyEndDate = now + self.candidacyDuration;
        newBallot.electionEndDate = now + self.candidacyDuration+self.ballotDuration;
        newBallot.wasEnded = false;
        ballots.push(newBallot);

        ballotNumber = ballots.length - 1;

        // openBallotList.push(ballotNumber);
        // currentBallot = ballotNumber;
        self.nextElectionDate = now + self.ballotFrequency;

        // Ballot creation event
        emit ballotCreationEvent(msg.sender, newBallot.name, newBallot.startDate, newBallot.candidacyEndDate, newBallot.electionEndDate, ballotNumber);

        return ballotNumber;
    }

    function presentCandidacyLib(RecurringElectionInfo storage self, ElectionBallot storage ballot, uint _ballotNumber, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) 
    public 
    {
        // Check that the ballot is still active
        require(!ballot.wasEnded);

        // Check that the ballot candidacy period is still open
        require(ballot.candidacyEndDate > now);

        // Check that sender is not over the mandate limit
        require(self.cumulatedCandidacies[msg.sender] < self.reelectionMaximum);

        // Check if the candidate is already candidate
        require(ballot.candidacies[msg.sender].candidateAddress != msg.sender);

        ballot.candidateList.push(msg.sender);

        ballot.candidacies[msg.sender].candidateAddress = msg.sender;

        ballot.candidacies[msg.sender].ipfsHash = _ipfsHash;
        ballot.candidacies[msg.sender].hash_function = _hash_function;
        ballot.candidacies[msg.sender].size = _size;
        ballot.candidacies[msg.sender].voteNumber = 0;
         // Candidacy event is turned off for now
        emit presentCandidacyEvent(_ballotNumber, msg.sender, _ipfsHash, _hash_function, _size);
    }

    function voteManyToOne(ElectionBallot storage self, uint _ballotNumber, address _candidateAddress) 
    public 
    {        
        // Check if voter already votred
        require(!self.hasUserVoted[msg.sender]);

        // Check if vote is still active
        require(!self.wasEnded);

        // Check if candidacy period is over
        require(self.candidacyEndDate < now);

        // Check if voting period ended
        require(self.electionEndDate > now);

        // Check if candidate for whom we voted for is declared
        if(self.candidacies[_candidateAddress].candidateAddress != 0x0000)
        {self.candidacies[_candidateAddress].voteNumber += 1;}
        else
            // If candidate does not exist, this is a neutral vote
        {self.candidacies[0x0000].voteNumber += 1;}

        self.hasUserVoted[msg.sender] = true;
        
        self.totalVoteCount += 1;

        // Event
        emit votedOnElectionEvent(msg.sender, _ballotNumber);
    }

    function countManyToOne(RecurringElectionInfo storage self, ElectionBallot storage ballot, address _votersOrgan, uint _ballotNumber) 
    public 
    returns (address nextPresident)
    {
        // We check if the vote was already closed
        require(!ballot.wasEnded);

        // Checking that the vote can be closed
        require(ballot.electionEndDate < now);

        // Checking that there was enough participation
        if ((ballot.candidateList.length == 0) || ballot.totalVoteCount == 0)
        {
                ballot.wasEnded = true;
                emit ballotResultException(_ballotNumber);
                self.nextElectionDate = now -1;
                return 0x0000;
        }

        // Checking if the election is still valid
        if (now > ballot.startDate + self.ballotFrequency)
        {
            emit ballotResultException(_ballotNumber);
            ballot.wasEnded = true;  
            return 0x0000;                
        }




        // ############## Going through candidates to check the vote count
        uint winningVoteCount = 0;
        bool isADraw = false;
        bool quorumIsObtained = false;

        Organ voterRegistryOrgan = Organ(_votersOrgan);

        // Check if quorum is obtained. We avoiding divisions here, since Solidity is not good to calculate divisions
        ( ,uint voterNumber) = voterRegistryOrgan.organInfos();
        if (ballot.totalVoteCount*100 >= self.quorumSize*voterNumber)
        {
            quorumIsObtained = true;
        }

        delete voterRegistryOrgan;

        // Going through candidates list
        for (uint p = 0; p < ballot.candidateList.length; p++) 
        {
            address _candidateAddress = ballot.candidateList[p];
            if (ballot.candidacies[_candidateAddress].voteNumber > winningVoteCount) 
            {
                winningVoteCount = ballot.candidacies[_candidateAddress].voteNumber ;
                nextPresident = ballot.candidateList[p];
                isADraw = false;
            }

            else if (ballot.candidacies[_candidateAddress].voteNumber == winningVoteCount)
            {
                isADraw = true;
            }
        }

        // ############## Updating ballot values if vote concluded
        ballot.wasEnded = true;

        if (!isADraw && quorumIsObtained)
            // The ballot completed succesfully
        {
            emit ballotWasCounted(_ballotNumber, ballot.candidateList, nextPresident, ballot.totalVoteCount);
        }

        else // The ballot did not conclude correctly. We reboot the election process.
        {
            nextPresident = 0x0000;
            emit ballotResultException(_ballotNumber);
            self.nextElectionDate = now -1;
            ballot.wasEnded = true;
        }

        return nextPresident;    
    }

    function givePowerToNewPresident(ElectionBallot storage ballot, address _newPresident, address _currentPresident, address _presidentialOrganAddress, uint _ballotNumber)
    public
    {
        Organ presidentialOrgan = Organ(_presidentialOrganAddress);
        presidentialOrgan.addNorm(_newPresident, ballot.candidacies[_newPresident].ipfsHash, ballot.candidacies[_newPresident].hash_function, ballot.candidacies[_newPresident].size);
        if (_ballotNumber > 0)
        {
            presidentialOrgan.remNorm(presidentialOrgan.getAddressPositionInNorm(_currentPresident));
        }
        
        emit ballotWasEnforced(_newPresident, _ballotNumber);
    }

}