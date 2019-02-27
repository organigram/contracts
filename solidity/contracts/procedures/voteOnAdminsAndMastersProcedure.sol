pragma solidity >=0.4.22 <0.6.0;

// Standard contract for promulgation of a norm

import "../standardProcedure.sol";
import "../Organ.sol";
import "../libraries/propositionVotingLibrary.sol";


contract voteOnAdminsAndMastersProcedure is Procedure{
    // 1: Cyclical many to one election (Presidential Election)
    // 2: Cyclical many to many election (Moderators Election)
    // 3: Simple norm nomination 
    // 4: Simple admins and master nomination
    // 5: Vote on Norms 
    // 6: Vote on masters and admins 
    // 7: Cooptation

    using procedureLibrary for procedureLibrary.threeRegisteredOrgans;
    using propositionVotingLibrary for propositionVotingLibrary.Proposition;
    using propositionVotingLibrary for propositionVotingLibrary.VotingProcessInfo;

    // First stakeholder address is votersOrganContract
    // Second stakeholder address is membersWithVetoOrganContract
    // Third stakeholder address is finalPromulgatorsOrganContract
    procedureLibrary.threeRegisteredOrgans public linkedOrgans;
    propositionVotingLibrary.VotingProcessInfo public votingProcedureInfo;

    // Minimum participation to validate election. This is a percentage value; for 40% quorum, quorumSize = 40
    uint public quorumSize;

    // Time for participant to vote
    uint public votingPeriodDuration;

    // Time for president to promulgat
    uint public promulgationPeriodDuration;

    // Minimum proportion of votes to win election. This is a percentage value; for 50% majority, majoritySize = 50
    uint public majoritySize;


    // ######################


    // A dynamically-sized array of `Proposition` structs.
    propositionVotingLibrary.Proposition[] propositions;

    // Events

    event createPropositionEvent(address _from, address _targetOrgan, uint _propositionType, uint _propositionNumber);
    event createPropositionDetails(address _contractToAdd, address _contractToRemove);
    event createMasterPropositionEvent(uint _propositionNumber, bool _canAdd, bool _canDelete);
    event createAdminPropositionEvent(uint _propositionNumber, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend);
    event createNormPropositionEvent(uint _propositionNumber, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size);

    event voteOnProposition(address _from, uint _propositionNumber);
    event vetoProposition(address _from, uint _propositionNumber);
    event countVotes(address _from, uint _propositionNumber);
    event promulgatePropositionEvent(address _from, uint _propositionNumber, bool _promulgate);

    constructor(address _votersOrganContract, address _membersWithVetoOrganContract, address _finalPromulgatorsOrganContract, uint _quorumSize, uint _votingPeriodDuration, uint _promulgationPeriodDuration, uint _majoritySize, bytes32 _name) 
    public 
    {

    procedureInfo.initProcedure(6, _name, 3);
    linkedOrgans.initThreeRegisteredOrgans(_votersOrganContract, _membersWithVetoOrganContract, _finalPromulgatorsOrganContract);
    votingProcedureInfo.initElectionParameters(_quorumSize, _votingPeriodDuration, _promulgationPeriodDuration, _majoritySize);
    }

    /// Create a new ballot to choose one of `proposalNames`.
    function createProposition(address _targetOrgan, address _contractToAdd, address _contractToRemove, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend, uint _propositionType) public returns (uint propositionNumber){

            // Check the proposition creator is able to make a proposition
            linkedOrgans.firstOrganAddress.isAllowed();

            // Retrieving proposition details
            propositionVotingLibrary.Proposition memory newProposition;
            newProposition.targetOrgan = _targetOrgan;
            newProposition.contractToAdd = _contractToAdd;
            newProposition.contractToRemove = _contractToRemove;
            newProposition.ipfsHash = _ipfsHash;
            newProposition.hash_function = _hash_function;
            newProposition.size = _size;
            newProposition.canAdd = _canAdd;
            newProposition.canDelete = _canDelete;
            newProposition.canSpend = _canSpend;
            newProposition.canDeposit = _canDeposit;
            newProposition.propositionType = _propositionType;

            // Instanciating proposition

            newProposition.votingPeriodEndDate = now + votingProcedureInfo.votingPeriodDuration;            
            newProposition.wasVetoed = false;
            newProposition.wasEnded = false;
            newProposition.wasCounted = false;
            newProposition.wasAccepted = false;
            newProposition.totalVoteCount = 0;
            newProposition.voteFor = 0;
            // newProposition.voteAgainst = 0;
            propositions.push(newProposition);
            delete newProposition;

            propositionNumber = propositions.length - 1;

            // proposition creation event
            emit createPropositionEvent(msg.sender, propositions[propositionNumber].targetOrgan, _propositionType, propositionNumber);
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
    function vote(uint _propositionNumber, bool _acceptProposition) public {
        // Check the voter is able to vote on a proposition
        linkedOrgans.firstOrganAddress.isAllowed();

        // Check if voter already voted
        require(!propositionVotingLibrary.getBoolean(votingProcedureInfo.userParticipation[msg.sender], _propositionNumber));

        // Check if vote is still active
        require(!propositions[_propositionNumber].wasCounted);

        // Check if voting period ended
        require(propositions[_propositionNumber].votingPeriodEndDate > now);

        // Adding vote
        if(_acceptProposition == true)
        {propositions[_propositionNumber].voteFor += 1;}

        // Loggin that user voted
        propositionVotingLibrary.setBoolean(votingProcedureInfo.userParticipation[msg.sender], _propositionNumber, true);

        // Adding vote count
        propositions[_propositionNumber].totalVoteCount += 1;

        // create vote event
        emit voteOnProposition(msg.sender, _propositionNumber);
    }

        /// Vote for a candidate
    function veto(uint _propositionNumber) public {

        // Check the voter is able to veto the proposition
        linkedOrgans.secondOrganAddress.isAllowed();
        
        // Check if vote is still active
        require(!propositions[_propositionNumber].wasCounted);

        // Check if voting period ended
        require(propositions[_propositionNumber].votingPeriodEndDate > now);

        // Log that proposition was vetoed
        propositions[_propositionNumber].wasVetoed = true;

        //  Create veto event
        emit vetoProposition(msg.sender, _propositionNumber);

    }

    // The vote is finished and we close it. This triggers the outcome of the vote.

    function endPropositionVote(uint _propositionNumber) public returns (bool hasBeenAccepted) {
        // We check if the vote was already counted
        require(!propositions[_propositionNumber].wasCounted);

        // Checking that the vote can be closed
        require(propositions[_propositionNumber].votingPeriodEndDate < now);

        Organ voterRegistryOrgan = Organ(linkedOrgans.firstOrganAddress);
        ( ,uint voterNumber) = voterRegistryOrgan.organInfos();

        // We check that Quorum was obtained and that a majority of votes were cast in favor of the proposition
        if (propositions[_propositionNumber].wasVetoed )
            {hasBeenAccepted=false;
                propositions[_propositionNumber].wasEnded = true;}
        else if
            ((propositions[_propositionNumber].totalVoteCount*100 >= quorumSize*voterNumber) && (propositions[_propositionNumber].voteFor*100 > propositions[_propositionNumber].totalVoteCount*majoritySize))
            {hasBeenAccepted = true;}
        else 
            {hasBeenAccepted=false;
            propositions[_propositionNumber].wasEnded = true;}


        // ############## Updating ballot values if vote concluded
        propositions[_propositionNumber].wasCounted = true;
        propositions[_propositionNumber].wasAccepted = hasBeenAccepted;

        emit countVotes(msg.sender, _propositionNumber);
    }

    function promulgateProposition(uint _propositionNumber, bool _promulgate) public {
        // Checking if ballot was already enforced
        require(!propositions[_propositionNumber].wasEnded );

        // Checking the ballot was counted
        require(propositions[_propositionNumber].wasCounted);

        // If promulgation is happening before endOfVote + promulgationPeriodDuration, check caller is an official promulgator
        if (now < propositions[_propositionNumber].votingPeriodEndDate + promulgationPeriodDuration)
            {        
            // Check the voter is able to promulgate the proposition
            linkedOrgans.thirdOrganAddress.isAllowed();
            }
        else { // If Promulgator did not promulgate, the only option is validating
            require(_promulgate);
            }

        // Checking the ballot was accepted
        require(propositions[_propositionNumber].wasAccepted);

        if ((!_promulgate)||((propositions[_propositionNumber].contractToAdd == 0x0000) && (propositions[_propositionNumber].contractToRemove == 0x0000)) )
        {
            // The promulgator choses to invalidate the promulgation
            propositions[_propositionNumber].wasEnded = true;
        }
        else
        {
            // We initiate the Organ interface to add an Admin

            Organ affectedOrgan = Organ(propositions[_propositionNumber].targetOrgan);

            if(propositions[_propositionNumber].contractToAdd != 0x0000)
            {
                if (propositions[_propositionNumber].contractToRemove != 0x0000)
                    { 
                        // Replacing
                        if (propositions[_propositionNumber].propositionType == 0)
                        {
                        affectedOrgan.replaceMaster(propositions[_propositionNumber].contractToRemove, propositions[_propositionNumber].contractToAdd, propositions[_propositionNumber].canAdd, propositions[_propositionNumber].canDelete);
                        }
                        else if (propositions[_propositionNumber].propositionType == 1)
                        {
                        // Replacing an Admin
                        affectedOrgan.replaceAdmin(propositions[_propositionNumber].contractToRemove, propositions[_propositionNumber].contractToAdd, propositions[_propositionNumber].canAdd, propositions[_propositionNumber].canDelete, propositions[_propositionNumber].canDeposit, propositions[_propositionNumber].canSpend);
                        }
                        else if (propositions[_propositionNumber].propositionType == 2)
                        {
                        affectedOrgan.replaceNorm(affectedOrgan.getAddressPositionInNorm(propositions[_propositionNumber].contractToRemove) , propositions[_propositionNumber].contractToAdd , propositions[_propositionNumber].ipfsHash, propositions[_propositionNumber].hash_function, propositions[_propositionNumber].size);
                        }

                    }
                else
                {
                    // Adding
                        if (propositions[_propositionNumber].propositionType == 0)
                        {
                        affectedOrgan.addMaster(propositions[_propositionNumber].contractToAdd, propositions[_propositionNumber].canAdd, propositions[_propositionNumber].canDelete);
                        }
                        else if (propositions[_propositionNumber].propositionType == 1)
                        {
                        // Adding an Admin
                        affectedOrgan.addAdmin(propositions[_propositionNumber].contractToAdd, propositions[_propositionNumber].canAdd, propositions[_propositionNumber].canDelete, propositions[_propositionNumber].canDeposit, propositions[_propositionNumber].canSpend);
                        }
                        else if (propositions[_propositionNumber].propositionType == 2)
                        {
                        affectedOrgan.addNorm(propositions[_propositionNumber].contractToAdd, propositions[_propositionNumber].ipfsHash, propositions[_propositionNumber].hash_function, propositions[_propositionNumber].size );

                        }
                }
            }
            else 
            {
                // Removing
                if (propositions[_propositionNumber].propositionType == 0)
                {
                affectedOrgan.remMaster(propositions[_propositionNumber].contractToRemove);
                }
                else if (propositions[_propositionNumber].propositionType == 1)
                {
                // Removing an Admin
                affectedOrgan.remAdmin(propositions[_propositionNumber].contractToRemove);
                }
                else if (propositions[_propositionNumber].propositionType == 2)
                {
                // Removing a norm
                affectedOrgan.remNorm(affectedOrgan.getAddressPositionInNorm(propositions[_propositionNumber].contractToRemove));
                }
                
            }        
            
        }
        propositions[_propositionNumber].wasEnded = true;

        // promulgation event
        emit promulgatePropositionEvent(msg.sender, _propositionNumber, _promulgate);

    }

    function archiveDefunctProposition(uint _propositionNumber) public {
        // If a proposition contains an instruction that can not be executed (eg "add an admin" without having canAdd enabled), this proposition can be closed

        Organ targetOrganContract = Organ(propositions[_propositionNumber].targetOrgan);
        bool canAdd;
        bool canDelete;
        if (propositions[_propositionNumber].propositionType < 2){
            (canAdd, canDelete) = targetOrganContract.isMaster(address(this));
        }
        else {
            (canAdd, canDelete, , ) = targetOrganContract.isAdmin(address(this));
        }
        
        if ((!canAdd && (propositions[_propositionNumber].contractToAdd != 0x0000)) || (!canDelete && (propositions[_propositionNumber].contractToRemove != 0x0000)) )
        {
            propositions[_propositionNumber].wasEnded = true;
        }
        emit promulgatePropositionEvent(msg.sender, _propositionNumber, false);

    }


    //////////////////////// Functions to communicate with other contracts

    function getPropositionDetails(uint _propositionNumber) public view returns (address _addressToAdd, address _addressToRemove, bool _canAdd, bool _canDelete, bool _canDeposit, bool _canSpend){
        return (propositions[_propositionNumber].contractToAdd, propositions[_propositionNumber].contractToRemove, propositions[_propositionNumber].canAdd, propositions[_propositionNumber].canDelete, propositions[_propositionNumber].canDeposit, propositions[_propositionNumber].canSpend);
    }
    function getPropositionDocumentation(uint _propositionNumber) public view returns (address _addressToAdd, address _addressToRemove, bytes32 _ipfsHash, uint8 _hash_function, uint8 _size, uint _propositionType){
        return (propositions[_propositionNumber].contractToAdd, propositions[_propositionNumber].contractToRemove, propositions[_propositionNumber].ipfsHash, propositions[_propositionNumber].hash_function, propositions[_propositionNumber].size, propositions[_propositionNumber].propositionType);
    }
    function getPropositionDates(uint _propositionNumber) public view returns (uint _votingPeriodEndDate, uint _promulgatorWindowEndDate){
        return (propositions[_propositionNumber].votingPeriodEndDate, propositions[_propositionNumber].votingPeriodEndDate + promulgationPeriodDuration);
    }
    function getPropositionStatus(uint _propositionNumber) public view returns (bool _wasCounted, bool _wasEnded){
        return (propositions[_propositionNumber].wasCounted, propositions[_propositionNumber].wasEnded);
    }
    function getVotedPropositionResults(uint _propositionNumber) public view returns (bool _wasVetoed, bool _wasAccepted){
        require(propositions[_propositionNumber].wasCounted);
        return (propositions[_propositionNumber].wasVetoed, propositions[_propositionNumber].wasAccepted);
        }
    function getVotedPropositionStats(uint _propositionNumber) public view returns (uint _totalVoters, uint _totalVoteCount, uint _voteFor)
        {require(propositions[_propositionNumber].wasCounted);
        return (propositions[_propositionNumber].totalVoteCount, propositions[_propositionNumber].totalVoteCount, propositions[_propositionNumber].voteFor);}

    function haveIVoted(uint _propositionNumber) 
    public 
    view 
    returns (bool IHaveVoted)
    {return propositionVotingLibrary.getBoolean(votingProcedureInfo.userParticipation[msg.sender], _propositionNumber);}
    // function getLinkedOrgans() public view returns (address[] _linkedOrgans)
    // {return linkedOrgans;}


}

