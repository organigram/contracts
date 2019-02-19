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

    struct BallotResults
        {
            address winningCandidate;
            uint totalVoteCount;
        }

    // A dynamically-sized array of `Ballot` structs.
    votingLibrary.ElectionBallot[] public ballots;
    BallotResults[] public ballotResults;

    // A mapping of candidacy status and number of candidacies per member
    mapping(address => uint) public cumulatedCandidacies;

    // Events
    event ballotCreationEvent(address _from, bytes32 _name, uint _startDate, uint _candidacyEndDate, uint _endDate, uint _ballotNumber);
    event presentCandidacyEvent(uint _ballotNumber, address _candidateAddress, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size);
    event votedOnElectionEvent(address _from, uint _ballotNumber);
    event ballotWasCounted(uint _ballotNumber, address[] _candidateList, address _winningCandidate, uint _totalVoteCount);
    event ballotResultException(uint _ballotNumber, bool _wasRebooted);
    event ballotWasEnforced(address _winningCandidate, uint _ballotNumber);

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

        // Checking that election date has passed
        require (now > electionParameters.nextElectionDate);
        // Checking if previous ballot was counted
        if (ballots.length > 0) {
            require(ballots[ballots.length - 1].wasEnded);
        }

        votingLibrary.ElectionBallot memory newBallot;
        newBallot.name = _ballotName;
        newBallot.startDate = now;
        newBallot.candidacyEndDate = now + electionParameters.candidacyDuration;
        newBallot.electionEndDate = now + electionParameters.candidacyDuration+electionParameters.ballotDuration;
        newBallot.wasEnded = false;
        ballots.push(newBallot);

        ballotNumber = ballots.length - 1;

        BallotResults memory newBallotResults;
        ballotResults.push(newBallotResults);
        // openBallotList.push(ballotNumber);
        // currentBallot = ballotNumber;
        electionParameters.nextElectionDate = now + electionParameters.ballotFrequency;

        // Ballot creation event
        emit ballotCreationEvent(msg.sender, newBallot.name, newBallot.startDate, newBallot.candidacyEndDate, newBallot.electionEndDate, ballotNumber);
    }

    function presentCandidacy(uint _ballotNumber, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) 
    public 
    {

        // Check the candidate is a member of the reference organ
        linkedOrgans.firstOrganAddress.isAllowed();


        // Check that the ballot is still active
        require(!ballots[_ballotNumber].wasEnded);

        // Check that the ballot candidacy period is still open
        require(ballots[_ballotNumber].candidacyEndDate > now);

        // Check that sender is not over the mandate limit
        require(cumulatedCandidacies[msg.sender] < electionParameters.reelectionMaximum);

        // Check if the candidate is already candidate
        require(ballots[_ballotNumber].candidacies[msg.sender].candidateAddress != msg.sender);

        ballots[_ballotNumber].candidateList.push(msg.sender);

        ballots[_ballotNumber].candidacies[msg.sender].candidateAddress = msg.sender;

        ballots[_ballotNumber].candidacies[msg.sender].ipfsHash = _ipfsHash;
        ballots[_ballotNumber].candidacies[msg.sender].hash_function = _hash_function;
        ballots[_ballotNumber].candidacies[msg.sender].size = _size;
        ballots[_ballotNumber].candidacies[msg.sender].voteNumber = 0;
         // Candidacy event is turned off for now
        emit presentCandidacyEvent(_ballotNumber, msg.sender, _ipfsHash, _hash_function, _size);
    }


    /// Vote for a candidate
    function vote(uint _ballotNumber, address _candidateAddress) 
    public 
    {

        linkedOrgans.firstOrganAddress.isAllowed();
        
        // Check if voter already votred
        require(!ballots[_ballotNumber].hasUserVoted[msg.sender]);

        // Check if vote is still active
        require(!ballots[_ballotNumber].wasEnded);

        // Check if candidacy period is over
        require(ballots[_ballotNumber].candidacyEndDate < now);

        // Check if voting period ended
        require(ballots[_ballotNumber].electionEndDate > now);

        // Check if candidate for whom we voted for is declared
        if(ballots[_ballotNumber].candidacies[_candidateAddress].candidateAddress != 0x0000)
        {ballots[_ballotNumber].candidacies[_candidateAddress].voteNumber += 1;}
        else
            // If candidate does not exist, this is a neutral vote
        {ballots[_ballotNumber].candidacies[0x0000].voteNumber += 1;}

        ballots[_ballotNumber].hasUserVoted[msg.sender] = true;
        
        ballots[_ballotNumber].totalVoteCount += 1;

        // Event
        emit votedOnElectionEvent(msg.sender, _ballotNumber);
                        

    }

    // The vote is finished and we close it. This triggers the outcome of the vote.

    function endBallot(uint _ballotNumber) 
    public 
    returns (uint winningCandidate)
    {
        // We check if the vote was already closed
        require(!ballots[_ballotNumber].wasEnded);

        // Checking that the vote can be closed
        require(ballots[_ballotNumber].electionEndDate < now);

        // Checking that the vote can be closed
        if ((ballots[_ballotNumber].candidateList.length == 0) || ballots[_ballotNumber].totalVoteCount == 0)
        {
                ballots[_ballotNumber].wasEnforced = true;
                ballots[_ballotNumber].wasEnded = true;
                emit ballotResultException(_ballotNumber, true);
                electionParameters.nextElectionDate = now -1;
                createBallot(ballots[_ballotNumber].name);
                return 0;
        }


        // ############## Going through candidates to check the vote count
        uint winningVoteCount = 0;
        bool isADraw = false;
        bool quorumIsObtained = false;

        Organ voterRegistryOrgan = Organ(linkedOrgans.firstOrganAddress);

        // Check if quorum is obtained. We avoiding divisions here, since Solidity is not good to calculate divisions
        ( ,uint voterNumber) = voterRegistryOrgan.organInfos();
        if (ballots[_ballotNumber].totalVoteCount*100 >= electionParameters.quorumSize*voterNumber)
        {quorumIsObtained = true;}

        // Going through candidates list
        for (uint p = 0; p < ballots[_ballotNumber].candidateList.length; p++) {
            address _candidateAddress = ballots[_ballotNumber].candidateList[p];
            if (ballots[_ballotNumber].candidacies[_candidateAddress].voteNumber > winningVoteCount) {
                winningVoteCount = ballots[_ballotNumber].candidacies[_candidateAddress].voteNumber ;
                winningCandidate = p;
                isADraw = false;
            }
            else if (ballots[_ballotNumber].candidacies[_candidateAddress].voteNumber == winningVoteCount){
                isADraw = true;
            }

        }

        // ############## Updating ballot values if vote concluded
        ballots[_ballotNumber].wasEnded = true;

        if (!isADraw && quorumIsObtained)
            // The ballot completed succesfully
        {


        ballotResults[_ballotNumber].winningCandidate = ballots[_ballotNumber].candidateList[winningCandidate];
        emit ballotWasCounted(_ballotNumber, ballots[_ballotNumber].candidateList, ballotResults[_ballotNumber].winningCandidate, ballots[_ballotNumber].totalVoteCount);

            }
            else
                // The ballot did not conclude correctly. We reboot the election process.
            {
                ballots[_ballotNumber].wasEnforced = true;
                emit ballotResultException(_ballotNumber, true);
                electionParameters.nextElectionDate = now -1;
                ballots[_ballotNumber].wasEnded = true;
                createBallot(ballots[_ballotNumber].name);
            }
                    
    }
    
    function enforceBallot(uint _ballotNumber) public {
        // Checking if ballot was already enforced
        require(!ballots[_ballotNumber].wasEnforced );
        // Checking the ballot was closed
        require(ballots[_ballotNumber].wasEnded);
        // Checking that the enforcing date is not later than the end of his supposed mandate
        if (now > ballots[_ballotNumber].startDate + electionParameters.ballotFrequency)
        {
            ballots[_ballotNumber].wasEnforced = true;
            // TODO add event to log this  
            emit ballotResultException(_ballotNumber, false);                  
            return;
        }

        // We initiate the Organ interface to add a presidential norm

        Organ presidentialOrgan = Organ(linkedOrgans.secondOrganAddress);
        address newPresidentAddress = ballotResults[_ballotNumber].winningCandidate;

        // Adding new president first
            // function addNorm (string _name, address _normAdress, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size) public  returns (bool success);
        if (newPresidentAddress != currentPresident)
            {
            votingLibrary.Candidacy memory newPresident = ballots[_ballotNumber].candidacies[newPresidentAddress];
            presidentialOrgan.addNorm(newPresidentAddress, newPresident.ipfsHash, newPresident.hash_function, newPresident.size );

            

            // Removing former president, only if a former election was conducted.
            if (ballots.length > 0){
            presidentialOrgan.remNorm(presidentialOrgan.getAddressPositionInNorm(currentPresident));
                }


            // Modifying procedure variable to count new president
            currentPresident = newPresidentAddress;

            }
        cumulatedCandidacies[newPresidentAddress] += 1;
        ballots[_ballotNumber].wasEnforced = true;
        // delete openBallotList[_ballotNumber];
        // currentBallot = 0;

        // Adjusting mandate duration
        // nextElectionDate = now + ballotFrequency - candidacyDuration - ballotDuration;
        emit ballotWasEnforced( newPresidentAddress, _ballotNumber);
         }
        //////////////////////// Functions to communicate with other contracts
    

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

