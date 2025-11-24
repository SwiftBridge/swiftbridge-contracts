// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ReviewBoard {
    struct Review {
        address reviewer;
        string content;
        uint8 rating;
        uint256 timestamp;
    }

    Review[] public reviews;

    event ReviewSubmitted(address indexed reviewer, uint8 rating);
    event BatchReviewsSubmitted(address indexed reviewer, uint256 count);

    function submitReview(string memory _content, uint8 _rating) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be 1-5");
        reviews.push(Review(msg.sender, _content, _rating, block.timestamp));
        emit ReviewSubmitted(msg.sender, _rating);
    }

    function batchSubmitReviews(string[] memory _contents, uint8[] memory _ratings) public {
        require(_contents.length == _ratings.length, "Length mismatch");
        for (uint256 i = 0; i < _contents.length; i++) {
            require(_ratings[i] >= 1 && _ratings[i] <= 5, "Rating must be 1-5");
            reviews.push(Review(msg.sender, _contents[i], _ratings[i], block.timestamp));
        }
        emit BatchReviewsSubmitted(msg.sender, _contents.length);
    }

    function getReviewCount() public view returns (uint256) {
        return reviews.length;
    }
}
