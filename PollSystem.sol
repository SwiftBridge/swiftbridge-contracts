// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract PollSystem {
    struct Poll {
        address creator;
        string question;
        string[] options;
        mapping(uint256 => uint256) votes;
        uint256 timestamp;
    }

    Poll[] public polls;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event PollCreated(address indexed creator, uint256 pollId);

    function createPoll(string memory _question, string[] memory _options) public {
        Poll storage newPoll = polls.push();
        newPoll.creator = msg.sender;
        newPoll.question = _question;
        newPoll.options = _options;
        newPoll.timestamp = block.timestamp;
        emit PollCreated(msg.sender, polls.length - 1);
    }

    function vote(uint256 pollId, uint256 optionId) public {
        require(pollId < polls.length, "Invalid poll");
        require(optionId < polls[pollId].options.length, "Invalid option");
        require(!hasVoted[pollId][msg.sender], "Already voted");
        polls[pollId].votes[optionId]++;
        hasVoted[pollId][msg.sender] = true;
    }

    function getPollCount() public view returns (uint256) {
        return polls.length;
    }

    function getVotes(uint256 pollId, uint256 optionId) public view returns (uint256) {
        require(pollId < polls.length, "Invalid poll");
        return polls[pollId].votes[optionId];
    }
}
