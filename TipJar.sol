// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract TipJar {
    struct Message {
        address sender;
        string content;
        uint256 tipAmount;
        uint256 timestamp;
    }

    Message[] public messages;

    event MessageWithTip(address indexed sender, uint256 tipAmount);
    event BatchMessagesWithTips(address indexed sender, uint256 count);

    function sendMessageWithTip(string memory _content) public payable {
        messages.push(Message(msg.sender, _content, msg.value, block.timestamp));
        emit MessageWithTip(msg.sender, msg.value);
    }

    function batchSendMessagesWithTips(string[] memory _contents) public payable {
        uint256 tipPerMessage = msg.value / _contents.length;
        for (uint256 i = 0; i < _contents.length; i++) {
            messages.push(Message(msg.sender, _contents[i], tipPerMessage, block.timestamp));
        }
        emit BatchMessagesWithTips(msg.sender, _contents.length);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }

    function getTotalTips() public view returns (uint256) {
        return address(this).balance;
    }
}
