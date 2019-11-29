pragma solidity >=0.4.22 <0.7.0;

import "../Organ.sol";

/*
    Kelsen Framework - Cyclical Voting library.
    This library holds logic common to all cyclical voting procedures.
*/

// @ FIXME : Enforce methods seem susceptible to re-entrancy.
// https://solidity.readthedocs.io/en/v0.5.13/security-considerations.html#re-entrancy
// @ FIXME : Votes count seem susceptible to out-of-gas exceptions.
// https://solidity.readthedocs.io/en/v0.5.13/security-considerations.html#gas-limit-and-loops

library CyclicalElectionLibrary {

    struct CyclicalElectionData {
        uint frequency;
        uint votingDuration;
        uint candidacyDuration;
        uint nextElectionDate;
        uint mandatesMaximum;
        uint quorumSize;                                        // Minimum participation for a valid election.
        uint votersToCandidatesRatio;                           // For many-to-many elections.
        address payable votersOrganContract;
        address payable affectedOrganContract;
        mapping(address => uint) mandatesCounts;
        mapping(address => uint) latestElectionIndexes;
        mapping(address => Candidacy) candidacies;              // Reset before each election.
    }

    struct Candidacy {
        address payable candidate;
        bytes32 proposalIpfsHash;
        uint8 proposalHashFunction;
        uint8 proposalHashSize;
        uint votes;
    }

    struct Election {
        uint index;                         // Starts at 1.
        uint startDate;
        uint endDate;
        uint candidacyEndDate;
        bool hasQuorum;
        bool isEnded;
        uint votesTotal;
        uint votersTotal;
        uint electedCandidatesMaximum;      // Number of winners in many-to-many elections.
        address payable[] candidates;
        address payable[] winningCandidates;
        uint minimumVotesToBeWinning;
        bytes32 metadataIpfsHash;
        uint8 metadataHashFunction;
        uint8 metadataHashSize;
    }

    /*
        Events.
    */

    event electionCreated(
        uint _electionIndex, address _from, uint _startDate, uint _candidacyEndDate, uint _endDate,
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize
    );
    event candidacyPresented(
        uint _electionIndex, address _candidate,
        bytes32 _proposalIpfsHash, uint8 _proposalHashFunction, uint8 _proposalHashSize
    );
    event voted(uint _electionIndex, address _from);
    event electionFailed(uint _electionIndex);
    event electionSucceeded(uint _electionIndex, address payable[] _winningCandidates);

    /*
        Constructor.
    */

    function init(
        CyclicalElectionData storage self,
        address payable _votersOrganContract, address payable _affectedOrganContract,
        uint _frequency, uint _votingDuration, uint _quorumSize, uint _mandatesMaximum, uint _candidacyDuration, uint _votersToCandidatesRatio
    )
        public
    {
        self.frequency = _frequency;
        self.nextElectionDate = now;
        self.votingDuration = _votingDuration;
        self.quorumSize = _quorumSize;
        self.mandatesMaximum = _mandatesMaximum;
        self.candidacyDuration = _candidacyDuration;
        self.votersToCandidatesRatio = _votersToCandidatesRatio;
        self.votersOrganContract = _votersOrganContract;
        self.affectedOrganContract = _affectedOrganContract;
    }

    function createElection(
        CyclicalElectionData storage self, Election storage election,
        bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize
    )
        public
    {
        // Checking that election date has passed.
        require (now > self.nextElectionDate, "Election date not reached.");
        // Checking if previous election was counted.
        require(election.startDate == 0, "Previous election was not counted.");
        election.index = election.index + 1;
        election.metadataIpfsHash = _metadataIpfsHash;
        election.metadataHashFunction = _metadataHashFunction;
        election.metadataHashSize = _metadataHashSize;
        election.startDate = now;
        election.candidacyEndDate = now + self.candidacyDuration;
        election.endDate = now + self.candidacyDuration + self.votingDuration;
        
        // Retrieving size of electorate.
        Organ votersRegistryOrgan = Organ(self.votersOrganContract);
        (,,,, uint normsCount) = votersRegistryOrgan.organData();
        delete votersRegistryOrgan;

        election.electedCandidatesMaximum = normsCount / uint(self.votersToCandidatesRatio);
        if (election.electedCandidatesMaximum == 0) {
            election.electedCandidatesMaximum = 1;
        }

        self.nextElectionDate = now + self.frequency;

        emit electionCreated(
            election.index, msg.sender, election.startDate, election.candidacyEndDate, election.endDate,
            election.metadataIpfsHash, election.metadataHashFunction, election.metadataHashSize
        );
   }

    function presentCandidacy(
        CyclicalElectionData storage self, Election storage election,
        bytes32 _proposalIpfsHash, uint8 _proposalHashFunction, uint8 _proposalHashSize
    )
        public
    {
        // Check that the user is a voter.
        requireVoter(self);
        // Check that the election is still active.
        require(!election.isEnded, "A election is still ongoing.");
        // Check that the election candidacy period is still open.
        require(election.candidacyEndDate > now, "Candidacies period is closed.");
        // Check that sender is not over the mandate limit.
        require(self.mandatesCounts[msg.sender] < self.mandatesMaximum, "Reached maximum number of mandates.");
        // Check if the candidate is not already candidate.
        require(self.candidacies[msg.sender].candidate != msg.sender, "Duplicate record.");

        election.candidates.push(msg.sender);
        self.candidacies[msg.sender].candidate = msg.sender;
        self.candidacies[msg.sender].proposalIpfsHash = _proposalIpfsHash;
        self.candidacies[msg.sender].proposalHashFunction = _proposalHashFunction;
        self.candidacies[msg.sender].proposalHashSize = _proposalHashSize;

        emit candidacyPresented(election.index, msg.sender, _proposalIpfsHash, _proposalHashFunction, _proposalHashSize);
    }

    function voteManyToOne(CyclicalElectionData storage self, Election storage election, address payable _candidate)
        public
    {
        // Check that the user is a voter.
        requireVoter(self);
        // Check if voter didn't already vote.
        require(self.latestElectionIndexes[msg.sender] < election.index, "Duplicate record.");
        // Check if candidacy period is over.
        require(election.candidacyEndDate < now, "Candidacy period is not over.");
        // Check if voting period ended.
        require(!election.isEnded && election.endDate > now, "Voting period is over.");

        // Check if candidate for whom we voted for is declared
        if (self.candidacies[_candidate].candidate != address(0)) {
            self.candidacies[_candidate].votes += 1;

            // Track winning candidate.
            // If nobody is winning, we compute if current candidate is winning.
            if (self.candidacies[_candidate].votes > election.minimumVotesToBeWinning && election.winningCandidates.length == 0) {
                election.winningCandidates.push(_candidate);
                election.minimumVotesToBeWinning = self.candidacies[_candidate].votes;
            }
            // In case of tie, we remove the current winner.
            else if (self.candidacies[_candidate].votes == election.minimumVotesToBeWinning && election.winningCandidates.length == 1) {
                delete election.winningCandidates[0];
            }
        }
        // If candidate does not exist, this is a neutral vote.
        else {
            self.candidacies[address(0)].votes += 1;
        }

        self.latestElectionIndexes[msg.sender] == election.index;
        election.votesTotal += 1;

        // Vote is done.
        emit voted(election.index, msg.sender);
    }

    function endElection(CyclicalElectionData storage self, Election storage election)
        public returns (address payable[] memory electedCandidates)
    {
        // Check that voting has ended.
        require(
            election.endDate != 0 &&
            !election.isEnded &&
            election.endDate < now,
            "Voting period not ended."
        );

        election.isEnded = true;


        // End and fail if the time has come for a new election.
        if (now > (election.startDate + self.frequency)) {
            emit electionFailed(election.index);
            return electedCandidates;
        }

        // Compute quorum.
        Organ votersOrgan = Organ(self.votersOrganContract);
        (,,,, uint normsCount) = votersOrgan.organData();
        delete votersOrgan;
        election.hasQuorum = (election.votesTotal * 100) >= (self.quorumSize * normsCount);

        // End and fail if there are no winners, no votes or no quorum.
        if (
            election.winningCandidates.length == 0 ||
            election.votesTotal == 0 ||
            !election.hasQuorum
        ) {
            emit electionFailed(election.index);
            self.nextElectionDate = now - 1;
            return electedCandidates;
        }

        // Else we elect the winners.
        electCandidates(self, election);
        emit electionSucceeded(election.index, election.winningCandidates);
        // Clean up.
        for (uint i = 0; i < election.candidates.length; ++i) {
            delete self.candidacies[election.candidates[i]];
        }
        return election.winningCandidates;
    }

    function electCandidates(CyclicalElectionData storage self, Election storage election)
        public
    {
        Organ affectedOrgan = Organ(self.affectedOrganContract);

        // Remove all old norms.
        (,,,, uint normsCount) = affectedOrgan.organData();
        for (uint i = 0; i < normsCount; ++i) {
            affectedOrgan.removeNorm(0);
        }

        // Loop through winning candidates.
        for (uint i = 0; i < election.winningCandidates.length; ++i) {
            address candidate = election.winningCandidates[i];
            self.mandatesCounts[candidate] += 1;
            affectedOrgan.addNorm(
                self.candidacies[candidate].candidate,
                self.candidacies[candidate].proposalIpfsHash,
                self.candidacies[candidate].proposalHashFunction,
                self.candidacies[candidate].proposalHashSize
            );
        }
    }

    function requireVoter(CyclicalElectionData storage self)
        internal view
    {
        // Verifying the evaluator is an admin.
        Organ votersOrgan = Organ(self.votersOrganContract);
        require(votersOrgan.getNormIndexForAddress(msg.sender) != 0, "Not authorized.");
        delete votersOrgan;
    }
}