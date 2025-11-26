// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract DirectMessage {
    struct Message {
        address sender;
        address receiver;
        string content;
        uint256 timestamp;
        bool read;
    }

    Message[] public messages;
    mapping(address => uint256[]) public userMessages;

    event MessageSent(address indexed sender, address indexed receiver, uint256 messageId);
    event MessageRead(uint256 indexed messageId);

    function sendMessage(address _receiver, string memory _content) public {
        messages.push(Message(msg.sender, _receiver, _content, block.timestamp, false));
        uint256 messageId = messages.length - 1;
        userMessages[msg.sender].push(messageId);
        userMessages[_receiver].push(messageId);
        emit MessageSent(msg.sender, _receiver, messageId);
    }

    function markAsRead(uint256 _messageId) public {
        require(_messageId < messages.length, "Invalid message ID");
        require(messages[_messageId].receiver == msg.sender, "Not the receiver");
        messages[_messageId].read = true;
        emit MessageRead(_messageId);
    }

    function getMessage(uint256 _messageId) public view returns (Message memory) {
        require(_messageId < messages.length, "Invalid message ID");
        return messages[_messageId];
    }
}
