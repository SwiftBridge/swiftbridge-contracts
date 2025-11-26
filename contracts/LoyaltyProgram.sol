// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract LoyaltyProgram {
    mapping(address => uint256) public points;
    address public owner;

    event PointsEarned(address indexed user, uint256 amount);
    event PointsSpent(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function awardPoints(address _user, uint256 _amount) public {
        require(msg.sender == owner, "Only owner");
        points[_user] += _amount;
        emit PointsEarned(_user, _amount);
    }

    function spendPoints(uint256 _amount) public {
        require(points[msg.sender] >= _amount, "Insufficient points");
        points[msg.sender] -= _amount;
        emit PointsSpent(msg.sender, _amount);
    }
}
