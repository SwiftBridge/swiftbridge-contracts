// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract AchievementSystem {
    struct Achievement {
        string name;
        string description;
        uint256 points;
    }

    Achievement[] public achievements;
    mapping(address => mapping(uint256 => bool)) public userAchievements;
    mapping(address => uint256) public userPoints;

    event AchievementUnlocked(address indexed user, uint256 achievementId);

    function createAchievement(string memory _name, string memory _description, uint256 _points) public {
        achievements.push(Achievement(_name, _description, _points));
    }

    function unlockAchievement(address _user, uint256 _achievementId) public {
        // In a real system, this would be restricted to authorized contracts
        require(_achievementId < achievements.length, "Invalid achievement");
        require(!userAchievements[_user][_achievementId], "Already unlocked");

        userAchievements[_user][_achievementId] = true;
        userPoints[_user] += achievements[_achievementId].points;
        emit AchievementUnlocked(_user, _achievementId);
    }
}
