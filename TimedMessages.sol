// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract TimedMessages {
    struct Message {
        address sender;
        string content;
        uint256 expiresAt;
        uint256 timestamp;
    }

    Message[] public messages;

    event MessageSent(address indexed sender, uint256 expiresAt);
    event BatchMessagesSent(address indexed sender, uint256 count);

    function sendMessage(string memory _content, uint256 _duration) public {
        uint256 expiresAt = block.timestamp + _duration;
        messages.push(Message(msg.sender, _content, expiresAt, block.timestamp));
        emit MessageSent(msg.sender, expiresAt);
    }

    function batchSendMessages(string[] memory _contents, uint256[] memory _durations) public {
        require(_contents.length == _durations.length, "Length mismatch");
        for (uint256 i = 0; i < _contents.length; i++) {
            uint256 expiresAt = block.timestamp + _durations[i];
            messages.push(Message(msg.sender, _contents[i], expiresAt, block.timestamp));
        }
        emit BatchMessagesSent(msg.sender, _contents.length);
    }

    function isExpired(uint256 messageId) public view returns (bool) {
        require(messageId < messages.length, "Invalid message");
        return block.timestamp > messages[messageId].expiresAt;
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
