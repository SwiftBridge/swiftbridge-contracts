// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract DisputeResolution {
    struct Dispute {
        address creator;
        string description;
        uint256 stake;
        bool resolved;
        bool outcome;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct Vote {
        address voter;
        uint256 disputeId;
        bool support;
    }

    Dispute[] public disputes;
    Vote[] public votes;
    mapping(address => bool) public arbitrators;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    address public admin;

    event DisputeCreated(uint256 indexed disputeId, address creator, string description);
    event VoteCast(uint256 indexed disputeId, address voter, bool support);
    event DisputeResolved(uint256 indexed disputeId, bool outcome);
    event ArbitratorAdded(address indexed arbitrator);

    constructor() {
        admin = msg.sender;
        arbitrators[msg.sender] = true;
    }

    function addArbitrator(address _arbitrator) public {
        require(msg.sender == admin, "Only admin");
        arbitrators[_arbitrator] = true;
        emit ArbitratorAdded(_arbitrator);
    }

    function createDispute(string memory _description) public payable {
        require(msg.value > 0, "Stake required");
        disputes.push(Dispute(msg.sender, _description, msg.value, false, false, 0, 0));
        emit DisputeCreated(disputes.length - 1, msg.sender, _description);
    }

    function vote(uint256 _disputeId, bool _support) public {
        require(arbitrators[msg.sender], "Not an arbitrator");
        require(_disputeId < disputes.length, "Invalid dispute");
        require(!hasVoted[_disputeId][msg.sender], "Already voted");
        require(!disputes[_disputeId].resolved, "Already resolved");

        Dispute storage dispute = disputes[_disputeId];
        hasVoted[_disputeId][msg.sender] = true;

        if (_support) {
            dispute.votesFor++;
        } else {
            dispute.votesAgainst++;
        }

        votes.push(Vote(msg.sender, _disputeId, _support));
        emit VoteCast(_disputeId, msg.sender, _support);
    }

    function resolveDispute(uint256 _disputeId) public {
        require(_disputeId < disputes.length, "Invalid dispute");
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "Already resolved");
        require(dispute.votesFor + dispute.votesAgainst >= 3, "Need at least 3 votes");

        dispute.resolved = true;
        dispute.outcome = dispute.votesFor > dispute.votesAgainst;

        if (dispute.outcome) {
            payable(dispute.creator).transfer(dispute.stake);
        }

        emit DisputeResolved(_disputeId, dispute.outcome);
    }
}
