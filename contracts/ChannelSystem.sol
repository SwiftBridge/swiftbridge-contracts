// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ChannelSystem {
    struct Channel {
        string name;
        address owner;
        string description;
        uint256 subscriberCount;
    }

    struct Broadcast {
        uint256 channelId;
        string content;
        uint256 timestamp;
    }

    Channel[] public channels;
    Broadcast[] public broadcasts;
    mapping(uint256 => mapping(address => bool)) public subscribers;

    event ChannelCreated(uint256 indexed channelId, string name, address owner);
    event Subscribed(uint256 indexed channelId, address subscriber);
    event BroadcastSent(uint256 indexed channelId, uint256 broadcastId);

    function createChannel(string memory _name, string memory _description) public {
        channels.push(Channel(_name, msg.sender, _description, 0));
        emit ChannelCreated(channels.length - 1, _name, msg.sender);
    }

    function subscribe(uint256 _channelId) public {
        require(_channelId < channels.length, "Invalid channel ID");
        require(!subscribers[_channelId][msg.sender], "Already subscribed");
        subscribers[_channelId][msg.sender] = true;
        channels[_channelId].subscriberCount++;
        emit Subscribed(_channelId, msg.sender);
    }

    function broadcast(uint256 _channelId, string memory _content) public {
        require(_channelId < channels.length, "Invalid channel ID");
        require(channels[_channelId].owner == msg.sender, "Not channel owner");
        broadcasts.push(Broadcast(_channelId, _content, block.timestamp));
        emit BroadcastSent(_channelId, broadcasts.length - 1);
    }
}
