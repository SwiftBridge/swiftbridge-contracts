// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract StreamMessages {
    struct Stream {
        address streamer;
        string content;
        uint256 viewCount;
        uint256 timestamp;
    }

    Stream[] public streams;

    event StreamCreated(address indexed streamer);
    event BatchStreamsCreated(address indexed streamer, uint256 count);

    function createStream(string memory _content) public {
        streams.push(Stream(msg.sender, _content, 0, block.timestamp));
        emit StreamCreated(msg.sender);
    }

    function batchCreateStreams(string[] memory _contents) public {
        for (uint256 i = 0; i < _contents.length; i++) {
            streams.push(Stream(msg.sender, _contents[i], 0, block.timestamp));
        }
        emit BatchStreamsCreated(msg.sender, _contents.length);
    }

    function incrementView(uint256 streamId) public {
        require(streamId < streams.length, "Invalid stream");
        streams[streamId].viewCount++;
    }

    function getStreamCount() public view returns (uint256) {
        return streams.length;
    }
}
