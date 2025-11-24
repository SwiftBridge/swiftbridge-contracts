// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract MultiSigMessages {
    struct Message {
        address creator;
        string content;
        uint256 approvals;
        bool executed;
        uint256 timestamp;
    }

    Message[] public messages;
    mapping(uint256 => mapping(address => bool)) public hasApproved;
    uint256 public requiredApprovals = 2;

    event MessageCreated(address indexed creator, uint256 messageId);
    event BatchMessagesCreated(address indexed creator, uint256 count);

    function createMessage(string memory _content) public {
        messages.push(Message(msg.sender, _content, 0, false, block.timestamp));
        emit MessageCreated(msg.sender, messages.length - 1);
    }

    function batchCreateMessages(string[] memory _contents) public {
        for (uint256 i = 0; i < _contents.length; i++) {
            messages.push(Message(msg.sender, _contents[i], 0, false, block.timestamp));
        }
        emit BatchMessagesCreated(msg.sender, _contents.length);
    }

    function approveMessage(uint256 messageId) public {
        require(messageId < messages.length, "Invalid message");
        require(!hasApproved[messageId][msg.sender], "Already approved");
        messages[messageId].approvals++;
        hasApproved[messageId][msg.sender] = true;

        if (messages[messageId].approvals >= requiredApprovals) {
            messages[messageId].executed = true;
        }
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
