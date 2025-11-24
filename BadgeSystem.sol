// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract BadgeSystem {
    struct Message {
        address sender;
        string content;
        string badge;
        uint256 timestamp;
    }

    Message[] public messages;
    mapping(address => string) public userBadges;

    event MessageSent(address indexed sender, string badge);
    event BatchMessagesSent(address indexed sender, uint256 count);

    function setBadge(string memory _badge) public {
        userBadges[msg.sender] = _badge;
    }

    function sendMessage(string memory _content) public {
        messages.push(Message(msg.sender, _content, userBadges[msg.sender], block.timestamp));
        emit MessageSent(msg.sender, userBadges[msg.sender]);
    }

    function batchSendMessages(string[] memory _contents) public {
        string memory badge = userBadges[msg.sender];
        for (uint256 i = 0; i < _contents.length; i++) {
            messages.push(Message(msg.sender, _contents[i], badge, block.timestamp));
        }
        emit BatchMessagesSent(msg.sender, _contents.length);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
