// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract VotingMessages {
    struct VoteMessage {
        address creator;
        string content;
        uint256 upvotes;
        uint256 downvotes;
        uint256 timestamp;
    }

    VoteMessage[] public messages;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event MessageCreated(address indexed creator);
    event BatchMessagesCreated(address indexed creator, uint256 count);

    function createMessage(string memory _content) public {
        messages.push(VoteMessage(msg.sender, _content, 0, 0, block.timestamp));
        emit MessageCreated(msg.sender);
    }

    function batchCreateMessages(string[] memory _contents) public {
        for (uint256 i = 0; i < _contents.length; i++) {
            messages.push(VoteMessage(msg.sender, _contents[i], 0, 0, block.timestamp));
        }
        emit BatchMessagesCreated(msg.sender, _contents.length);
    }

    function vote(uint256 messageId, bool upvote) public {
        require(messageId < messages.length, "Invalid message");
        require(!hasVoted[messageId][msg.sender], "Already voted");
        if (upvote) {
            messages[messageId].upvotes++;
        } else {
            messages[messageId].downvotes++;
        }
        hasVoted[messageId][msg.sender] = true;
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
