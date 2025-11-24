// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract GroupChat {
    struct ChatMessage {
        address sender;
        uint256 groupId;
        string message;
        uint256 timestamp;
    }

    ChatMessage[] public messages;
    mapping(address => bool) public members;

    event MessageSent(address indexed sender, uint256 groupId);
    event BatchMessagesSent(address indexed sender, uint256 count);

    function joinGroup() public {
        members[msg.sender] = true;
    }

    function sendMessage(uint256 _groupId, string memory _message) public {
        require(members[msg.sender], "Not a member");
        messages.push(ChatMessage(msg.sender, _groupId, _message, block.timestamp));
        emit MessageSent(msg.sender, _groupId);
    }

    function batchSendMessages(uint256[] memory _groupIds, string[] memory _messages) public {
        require(members[msg.sender], "Not a member");
        require(_groupIds.length == _messages.length, "Length mismatch");
        for (uint256 i = 0; i < _messages.length; i++) {
            messages.push(ChatMessage(msg.sender, _groupIds[i], _messages[i], block.timestamp));
        }
        emit BatchMessagesSent(msg.sender, _messages.length);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
