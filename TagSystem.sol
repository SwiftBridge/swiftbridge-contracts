// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract TagSystem {
    struct TaggedMessage {
        address sender;
        string content;
        string[] tags;
        uint256 timestamp;
    }

    TaggedMessage[] public messages;

    event MessageTagged(address indexed sender, uint256 messageId);
    event BatchMessagesTagged(address indexed sender, uint256 count);

    function sendTaggedMessage(string memory _content, string[] memory _tags) public {
        TaggedMessage storage newMsg = messages.push();
        newMsg.sender = msg.sender;
        newMsg.content = _content;
        newMsg.tags = _tags;
        newMsg.timestamp = block.timestamp;
        emit MessageTagged(msg.sender, messages.length - 1);
    }

    function batchSendTaggedMessages(string[] memory _contents, string[][] memory _tagArrays) public {
        require(_contents.length == _tagArrays.length, "Length mismatch");
        for (uint256 i = 0; i < _contents.length; i++) {
            TaggedMessage storage newMsg = messages.push();
            newMsg.sender = msg.sender;
            newMsg.content = _contents[i];
            newMsg.tags = _tagArrays[i];
            newMsg.timestamp = block.timestamp;
        }
        emit BatchMessagesTagged(msg.sender, _contents.length);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }

    function getMessageTags(uint256 messageId) public view returns (string[] memory) {
        require(messageId < messages.length, "Invalid message");
        return messages[messageId].tags;
    }
}
