// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract CommentSystem {
    struct Comment {
        address author;
        uint256 parentId;
        string content;
        uint256 timestamp;
    }

    Comment[] public comments;

    event CommentAdded(address indexed author, uint256 parentId);
    event BatchCommentsAdded(address indexed author, uint256 count);

    function addComment(uint256 _parentId, string memory _content) public {
        comments.push(Comment(msg.sender, _parentId, _content, block.timestamp));
        emit CommentAdded(msg.sender, _parentId);
    }

    function batchAddComments(uint256[] memory _parentIds, string[] memory _contents) public {
        require(_parentIds.length == _contents.length, "Length mismatch");
        for (uint256 i = 0; i < _contents.length; i++) {
            comments.push(Comment(msg.sender, _parentIds[i], _contents[i], block.timestamp));
        }
        emit BatchCommentsAdded(msg.sender, _contents.length);
    }

    function getCommentCount() public view returns (uint256) {
        return comments.length;
    }
}
