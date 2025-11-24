// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SocialFeed {
    struct Post {
        address author;
        string content;
        string tag;
        uint256 timestamp;
        uint256 likes;
    }

    Post[] public posts;
    mapping(uint256 => mapping(address => bool)) public hasLiked;

    event PostCreated(address indexed author, string tag);
    event BatchPostsCreated(address indexed author, uint256 count);

    function createPost(string memory _content, string memory _tag) public {
        posts.push(Post(msg.sender, _content, _tag, block.timestamp, 0));
        emit PostCreated(msg.sender, _tag);
    }

    function batchCreatePosts(string[] memory _contents, string[] memory _tags) public {
        require(_contents.length == _tags.length, "Length mismatch");
        for (uint256 i = 0; i < _contents.length; i++) {
            posts.push(Post(msg.sender, _contents[i], _tags[i], block.timestamp, 0));
        }
        emit BatchPostsCreated(msg.sender, _contents.length);
    }

    function likePost(uint256 postId) public {
        require(postId < posts.length, "Invalid post");
        require(!hasLiked[postId][msg.sender], "Already liked");
        posts[postId].likes++;
        hasLiked[postId][msg.sender] = true;
    }

    function getPostCount() public view returns (uint256) {
        return posts.length;
    }
}
