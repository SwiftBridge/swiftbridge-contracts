// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract BatchMessenger {
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    Message[] public messages;

    event MessageSent(address indexed sender, string content);
    event BatchMessagesSent(address indexed sender, uint256 count);

    function sendMessage(string memory _content) public {
        messages.push(Message(msg.sender, _content, block.timestamp));
        emit MessageSent(msg.sender, _content);
    }

    function batchSendMessages(string[] memory _contents) public {
        for (uint256 i = 0; i < _contents.length; i++) {
            messages.push(Message(msg.sender, _contents[i], block.timestamp));
        }
        emit BatchMessagesSent(msg.sender, _contents.length);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }

    function getMessage(uint256 index) public view returns (address, string memory, uint256) {
        Message memory m = messages[index];
        return (m.sender, m.content, m.timestamp);
    }
}
