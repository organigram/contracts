pragma solidity >=0.4.22 <0.6.0;

// Standard contract for a presidential election procedure

import "../standardProcedure.sol";
import "../Organ.sol";
import "../libraries/votingLibrary.sol";


contract cyclicalManyToOneElectionProcedure is Procedure
{
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

    // ############## Variable to set up when declaring the procedure
    // ####### Vote creation process

    // current President address
    address public currentPresident;

    // A dynamically-sized array of `Ballot` structs.
    votingLibrary.ElectionBallot[] public ballots;

    // Events
    event ballotResultException(uint _ballotNumber);

    constructor(address _referenceOrganContract, address _affectedOrganContract, uint _ballotFrequency, uint _ballotDuration, uint _quorumSize, uint _reelectionMaximum, bytes32 _name) 
    public 
    {
        procedureInfo.initProcedure(1, _name, 2);
        linkedOrgans.initTwoRegisteredOrgans(_referenceOrganContract, _affectedOrganContract);
        electionParameters.initElectionParameters(_ballotFrequency, _ballotDuration, _quorumSize, _reelectionMaximum, 2*_ballotDuration);
    }

    /// Create a new ballot to choose one of `proposalNames`.
    function createBallot(bytes32 _ballotName) 
    public 
    returns (uint ballotNumber)
    {

        return electionParameters.createRecurrentBallotManyToOne(ballots, _ballotName);
    }

    function presentCandidacy(uint _ballotNumber, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) 
    public 
    {

        // Check the candidate is a member of the reference organ
        linkedOrgans.firstOrganAddress.isAllowed();
        electionParameters.presentCandidacyLib(ballots[_ballotNumber], _ballotNumber, _ipfsHash, _hash_function, _size);
    }


    /// Vote for a candidate
    function vote(uint _ballotNumber, address _candidateAddress) 
    public 
    {
        linkedOrgans.firstOrganAddress.isAllowed();
        ballots[_ballotNumber].voteManyToOne(_ballotNumber, _candidateAddress);
    }

    // The vote is finished and we close it. This triggers the outcome of the vote.

    function endBallot(uint _ballotNumber) 
    public 
    returns (address electionWinner)
    {
        electionWinner = electionParameters.countManyToOne(ballots[_ballotNumber], linkedOrgans.firstOrganAddress, _ballotNumber);   

        if (electionWinner == 0x0000)
        {
            emit ballotResultException(_ballotNumber); 
        }  

        else  
        {
            electionParameters.cumulatedCandidacies[electionWinner] += 1;

            if (electionWinner != currentPresident)
            {
                ballots[_ballotNumber].givePowerToNewPresident(electionWinner, currentPresident, linkedOrgans.secondOrganAddress, _ballotNumber);
                // Modifying procedure variable to count new president
                currentPresident = electionWinner;
            }
        }
            
        return electionWinner;          
    }
        
    // ######### Functions to retrieve procedure infos

    function getCandidateList(uint _ballotNumber) 
    public 
    view 
    returns (address[] _candidateList)
    {
        return ballots[_ballotNumber].candidateList;
    }

    function haveIVoted(uint _ballotNumber) 
    public 
    view 
    returns (bool IHaveVoted)
    {
        return ballots[_ballotNumber].hasUserVoted[msg.sender];
    }

    function getCandidateVoteNumber(uint _ballotNumber, address _candidateAddress) 
    public 
    view 
    returns (uint voteReceived)
    {
        require(ballots[_ballotNumber].wasEnded);
        return ballots[_ballotNumber].candidacies[_candidateAddress].voteNumber;
    }

    function getCandidacyInfo(uint _ballotNumber, address _candidateAddress) 
    public 
    view
    returns (bytes32 _ipfsHash, uint8 _hash_function, uint8 _size)
    {
        require(ballots[_ballotNumber].wasEnded);
        return (ballots[_ballotNumber].candidacies[_candidateAddress].ipfsHash, ballots[_ballotNumber].candidacies[_candidateAddress].hash_function , ballots[_ballotNumber].candidacies[_candidateAddress].size);
    }
}

