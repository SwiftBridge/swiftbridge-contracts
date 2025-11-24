// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract AnonymousBoard {
    struct Post {
        bytes32 hashedAuthor;
        string content;
        uint256 timestamp;
    }

    Post[] public posts;

    event PostCreated(bytes32 indexed hashedAuthor);
    event BatchPostsCreated(bytes32 indexed hashedAuthor, uint256 count);

    function createPost(string memory _content, string memory _secret) public {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _secret));
        posts.push(Post(hash, _content, block.timestamp));
        emit PostCreated(hash);
    }

    function batchCreatePosts(string[] memory _contents, string memory _secret) public {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _secret));
        for (uint256 i = 0; i < _contents.length; i++) {
            posts.push(Post(hash, _contents[i], block.timestamp));
        }
        emit BatchPostsCreated(hash, _contents.length);
    }

    function getPostCount() public view returns (uint256) {
        return posts.length;
    }
}
