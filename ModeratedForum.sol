// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ModeratedForum {
    struct Post {
        address author;
        string content;
        bool approved;
        uint256 timestamp;
    }

    Post[] public posts;
    address public moderator;

    event PostSubmitted(address indexed author, uint256 postId);
    event BatchPostsSubmitted(address indexed author, uint256 count);

    constructor() {
        moderator = msg.sender;
    }

    function submitPost(string memory _content) public {
        posts.push(Post(msg.sender, _content, false, block.timestamp));
        emit PostSubmitted(msg.sender, posts.length - 1);
    }

    function batchSubmitPosts(string[] memory _contents) public {
        for (uint256 i = 0; i < _contents.length; i++) {
            posts.push(Post(msg.sender, _contents[i], false, block.timestamp));
        }
        emit BatchPostsSubmitted(msg.sender, _contents.length);
    }

    function approvePost(uint256 postId) public {
        require(msg.sender == moderator, "Not moderator");
        require(postId < posts.length, "Invalid post");
        posts[postId].approved = true;
    }

    function getPostCount() public view returns (uint256) {
        return posts.length;
    }
}
