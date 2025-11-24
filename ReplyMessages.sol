// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ReplyMessages {
    struct Message {
        address sender;
        uint256 replyTo;
        string content;
        uint256 timestamp;
    }

    Message[] public messages;

    event MessageSent(address indexed sender, uint256 replyTo);
    event BatchMessagesSent(address indexed sender, uint256 count);

    function sendMessage(uint256 _replyTo, string memory _content) public {
        messages.push(Message(msg.sender, _replyTo, _content, block.timestamp));
        emit MessageSent(msg.sender, _replyTo);
    }

    function batchSendMessages(uint256[] memory _replyTos, string[] memory _contents) public {
        require(_replyTos.length == _contents.length, "Length mismatch");
        for (uint256 i = 0; i < _contents.length; i++) {
            messages.push(Message(msg.sender, _replyTos[i], _contents[i], block.timestamp));
        }
        emit BatchMessagesSent(msg.sender, _contents.length);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
