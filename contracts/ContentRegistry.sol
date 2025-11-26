// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ContentRegistry {
    struct Content {
        string contentHash;
        address owner;
        uint256 timestamp;
    }

    mapping(string => Content) public contents;

    event ContentRegistered(string indexed contentHash, address owner);

    function registerContent(string memory _contentHash) public {
        require(contents[_contentHash].timestamp == 0, "Content already registered");
        contents[_contentHash] = Content(_contentHash, msg.sender, block.timestamp);
        emit ContentRegistered(_contentHash, msg.sender);
    }

    function verifyOwner(string memory _contentHash) public view returns (address) {
        return contents[_contentHash].owner;
    }
}
