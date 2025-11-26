// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract DAOVoting {
    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 endTime;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(uint256 indexed proposalId, address voter);

    function createProposal(string memory _description, uint256 _duration) public {
        proposals.push(Proposal(_description, 0, block.timestamp + _duration, false));
        emit ProposalCreated(proposals.length - 1, _description);
    }

    function vote(uint256 _proposalId) public {
        require(_proposalId < proposals.length, "Invalid proposal");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.endTime, "Voting ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        hasVoted[_proposalId][msg.sender] = true;
        p.voteCount++;
        emit Voted(_proposalId, msg.sender);
    }
}
