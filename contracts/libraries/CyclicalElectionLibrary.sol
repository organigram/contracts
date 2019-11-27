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
        bool isEnded;
        uint votesTotal;
        uint votersTotal;
        uint electedCandidatesMaximum;      // Number of winners in many-to-many elections.
        address[] candidates;
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
    event electionCounted(uint _electionIndex, address _winningCandidate, uint _votesTotal);
    event electionFailed(uint _electionIndex);
    event electionEnforced(uint _electionIndex, address _winningCandidate);
    event candidateVotesCounted(uint _electionIndex, address _candidate, uint _votes);
    event manyToManyBordaElectionCounted(uint _electionIndex, uint _votesTotal);
    event manyToManyBordaElectionEnforced(uint _electionIndex, address[] _winningCandidates);

    /*
        Constructor.
    */

    function init(
        CyclicalElectionData storage self, uint _frequency, uint _votingDuration,
        uint _quorumSize, uint _mandatesMaximum, uint _candidacyDuration, uint _votersToCandidatesRatio
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
        // Check if voter didn't already vote.
        require(self.latestElectionIndexes[msg.sender] < election.index, "Duplicate record.");

        // Check if candidacy period is over.
        require(election.candidacyEndDate < now, "Candidacy period is not over.");

        // Check if voting period ended.
        require(!election.isEnded && election.endDate > now, "Voting period is over.");

        // Check if candidate for whom we voted for is declared
        if (self.candidacies[_candidate].candidate != address(0)) {
            self.candidacies[_candidate].votes += 1;
        }
        // If candidate does not exist, this is a neutral vote.
        else {
            self.candidacies[address(0)].votes += 1;
        }

        self.latestElectionIndexes[msg.sender] == election.index;
        election.votesTotal += 1;

        // Event
        emit voted(election.index, msg.sender);
    }

    function countManyToOne(CyclicalElectionData storage self, Election storage election, address payable _votersOrganAddress)
        public returns (address electedCandidate)
    {
        // Check that voting has ended.
        require(
            election.endDate != 0 &&
            !election.isEnded &&
            election.endDate < now,
            "Voting period not ended."
        );

        // End and fail if there are no candidates or no votes.
        if (election.candidates.length == 0 || election.votesTotal == 0) {
            election.isEnded = true;
            emit electionFailed(election.index);
            self.nextElectionDate = now - 1;
            return address(0);
        }

        // End and fail if the time has come for a new election.
        if (now > (election.startDate + self.frequency))
        {
            emit electionFailed(election.index);
            election.isEnded = true;
            return address(0);
        }

        // Going through candidates to check the vote count.
        uint winningVoteCount = 0;
        bool isADraw = false;
        bool quorumIsObtained = false;

        Organ voterRegistryOrgan = Organ(_votersOrganAddress);

        // Check if quorum is obtained.
        (,,, uint normsCount) = voterRegistryOrgan.organData();
        delete voterRegistryOrgan;
        if ((election.votesTotal * 100) >= (self.quorumSize * normsCount)) {
            quorumIsObtained = true;
        }

        // For each candidate...
        for (uint p = 0; p < election.candidates.length; p++) {
            address _candidate = election.candidates[p];

            // Log how many votes this candidate received
            emit candidateVotesCounted(election.index, _candidate, self.candidacies[_candidate].votes);

            // In case of clear win.
            if (self.candidacies[_candidate].votes > winningVoteCount) {
                winningVoteCount = self.candidacies[_candidate].votes;
                delete self.candidacies[electedCandidate];
                electedCandidate = _candidate;
                isADraw = false;
            }
            // In case of draw.
            else if (self.candidacies[_candidate].votes == winningVoteCount) {
                isADraw = true;
                delete self.candidacies[electedCandidate];
                delete self.candidacies[_candidate];
            }
            // Remove loser from candidacies.
            else {
                delete self.candidacies[_candidate];
            }
        }

        election.isEnded = true;

        // Fail if election is a draw or failed to reach quorum.
        if (isADraw || !quorumIsObtained) {
            emit electionFailed(election.index);
            self.nextElectionDate = now - 1;
            return address(0);
        }

        // The election completed succesfully.
        emit electionCounted(election.index, electedCandidate, election.votesTotal);

        return electedCandidate;
    }

    function voteManyToManyBorda(CyclicalElectionData storage self, Election storage election, address[] memory _candidates)
        public
    {
        // Check if voter didn't vote yet.
        require(self.latestElectionIndexes[msg.sender] < election.index, "Duplicate record.");
        // Check that election is ended.
        require(
            election.isEnded &&
            election.endDate > now &&
            election.candidacyEndDate < now,
            "Election not ended."
        );
        // Check the vote is for a valid number of candidates.
        require(
            _candidates.length > 0 &&
            _candidates.length <= election.electedCandidatesMaximum,
            "Invalid number of candidates."
        );

        // Going through the list of selected candidates
        for (uint i = 0; i < _candidates.length; i++) {
            if (self.candidacies[_candidates[i]].candidate != address(0)) {
                self.candidacies[_candidates[i]].votes += election.electedCandidatesMaximum - i;
                election.votesTotal += election.electedCandidatesMaximum - i;
            }
            // If candidate does not exist, this is a neutral vote.
            else {
                self.candidacies[address(0)].votes += 1;
            }
        }
        self.latestElectionIndexes[msg.sender] == election.index;
        election.votersTotal += 1;

        emit voted(election.index, msg.sender);
    }

    function countManyToManyBorda(
        CyclicalElectionData storage self, Election storage election,
        address[] storage nextModerators, address payable _votersOrganAddress
    )
        public
    {
        // We check if the vote was already closed
        require(!election.isEnded && election.endDate < now, "Election is not over.");

        // Checking the election has been initialised
        require(election.endDate != 0, "Election not initialised.");

        // Checking that the vote can be closed
        if ((election.candidates.length == 0) || election.votesTotal == 0) {
            self.nextElectionDate = now - 1;
            election.isEnded = true;
            emit electionFailed(election.index);
            return;
        }

        // Checking that the enforcing date is not later than the end of his supposed mandate
        if (now > (election.startDate + self.frequency)) {
            self.nextElectionDate = now - 1;
            election.isEnded = true;
            emit electionFailed(election.index);
            return;
        }

        Organ voterRegistryOrgan = Organ(_votersOrganAddress);
        (,,, uint normsCount) = voterRegistryOrgan.organData();
        delete voterRegistryOrgan;

        // Check if quorum is obtained.
        if ((election.votersTotal * 100) < (self.quorumSize * normsCount)) {
            self.nextElectionDate = now - 1;
            election.isEnded = true;
            emit electionFailed(election.index);
            return;
        }

        // Checking that there are enough candidates
        if (election.candidates.length < election.electedCandidatesMaximum) {
            election.electedCandidatesMaximum = election.candidates.length;
        }

        uint previousThresholdCount = uint(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        uint winningVoteCount = 0;
        uint isADraw = 0;
        uint roundWinningCandidate = 0;

        // Going through candidate lists to check all elected moderators.
        // @ FIXME : Avoid O(mn) complexities potentially causing out-of-gas exceptions.
        for (uint i = 0; i < election.electedCandidatesMaximum; i++) {
            winningVoteCount = 0;
            roundWinningCandidate = 0;
            // Going through candidate list once to find best suitor.
            for (uint p = 0; p < election.candidates.length; p++) {
                address _candidate = election.candidates[p];
                if (self.candidacies[_candidate].votes < previousThresholdCount) {
                    if (self.candidacies[_candidate].votes > winningVoteCount) {
                        winningVoteCount = self.candidacies[_candidate].votes;
                        roundWinningCandidate = p;
                        isADraw = 0;
                    }
                    else if (self.candidacies[_candidate].votes == winningVoteCount) {
                        isADraw += 1;
                    }
                }

            }

            // Checking if various candidates tied
            if (winningVoteCount > 0) {
                if (isADraw > 0) {
                    // Going through list one more time to add all tied up candidates
                    for (uint q = 0; q < election.candidates.length; q++) {
                        // Detecting ties
                        if (i < election.electedCandidatesMaximum && self.candidacies[election.candidates[q]].votes == winningVoteCount) {
                            nextModerators.push(election.candidates[q]);
                            i += 1;
                        }
                    }
                }
                // Adding candidate to winning candidate list
                else {
                    nextModerators.push(election.candidates[roundWinningCandidate]);
                }
            }

            previousThresholdCount = winningVoteCount;
        }

        election.isEnded = true;

        emit manyToManyBordaElectionCounted(election.index, election.votesTotal);
    }

    function enforceManyToManyBorda(
        CyclicalElectionData storage self, Election storage election,
        address[] storage nextModerators,address[] storage currentModerators, address payable _moderatorsOrganAddress
    )
        public
    {
        // Checking the election was closed
        require(election.isEnded, "Election is not ended.");
        // Checking there are new moderators to add
        require(nextModerators.length > 0, "There are no new moderators to add.");

        // We initiate the Organ interface to add a moderator norm
        Organ moderatorsOrgan = Organ(_moderatorsOrganAddress);

        // Removing current moderators, if this is not a first election
        if (election.index > 1) {
            for (uint i = 0; i < currentModerators.length; i++) {
                moderatorsOrgan.removeNorm(moderatorsOrgan.getNormIndexForAddress(currentModerators[i]));
                delete currentModerators[i];
            }
        }

        // Adding new moderators
        for (uint p = 0; p < nextModerators.length; p++) {
            Candidacy memory newModerator = self.candidacies[nextModerators[p]];
            moderatorsOrgan.addNorm(
                newModerator.candidate,
                newModerator.proposalIpfsHash, newModerator.proposalHashFunction, newModerator.proposalHashSize
            );
            self.mandatesCounts[nextModerators[p]] += 1;
            if (p < currentModerators.length) {
                currentModerators[p] = newModerator.candidate;
            }
            else {
                currentModerators.push(newModerator.candidate);
            }
            delete newModerator;
        }

        delete moderatorsOrgan;

        // Cleaning candidate lists and candidatures.
        for (uint k = 0; k < election.candidates.length; k++) {
            delete self.candidacies[election.candidates[k]];
        }

        emit manyToManyBordaElectionEnforced(election.index, nextModerators);
    }

    function electCandidate(
        CyclicalElectionData storage self, Election storage election,
        address _candidate, address _currentElected, address payable _organAddress
    )
        public
    {
        Organ targetOrgan = Organ(_organAddress);
        targetOrgan.addNorm(
            self.candidacies[_candidate].candidate,
            self.candidacies[_candidate].proposalIpfsHash, self.candidacies[_candidate].proposalHashFunction, self.candidacies[_candidate].proposalHashSize
        );
        if (election.index > 1) {
            targetOrgan.removeNorm(targetOrgan.getNormIndexForAddress(_currentElected));
        }

        emit electionEnforced(election.index, _candidate);
    }
}