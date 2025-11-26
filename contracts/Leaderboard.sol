// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Leaderboard {
    struct Score {
        address user;
        uint256 score;
    }

    mapping(address => uint256) public scores;
    address[] public users;

    event ScoreUpdated(address indexed user, uint256 newScore);

    function updateScore(address _user, uint256 _points) public {
        if (scores[_user] == 0) {
            users.push(_user);
        }
        scores[_user] += _points;
        emit ScoreUpdated(_user, scores[_user]);
    }

    function getTopUsers(uint256 k) public view returns (address[] memory, uint256[] memory) {
        // Naive implementation for demonstration
        // In production, sorting on-chain is expensive; use off-chain indexing
        uint256 count = k > users.length ? users.length : k;
        address[] memory topUsers = new address[](count);
        uint256[] memory topScores = new uint256[](count);
        
        // This is just a placeholder for returning data, not sorted
        for (uint256 i = 0; i < count; i++) {
            topUsers[i] = users[i];
            topScores[i] = scores[users[i]];
        }
        return (topUsers, topScores);
    }
}
