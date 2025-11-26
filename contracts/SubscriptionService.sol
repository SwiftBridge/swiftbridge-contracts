// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SubscriptionService {
    struct Plan {
        string name;
        uint256 price;
        uint256 duration;
    }

    struct Subscription {
        uint256 planId;
        uint256 expiry;
    }

    Plan[] public plans;
    mapping(address => Subscription) public subscriptions;
    address public owner;

    event PlanCreated(uint256 planId, string name, uint256 price);
    event Subscribed(address indexed user, uint256 planId, uint256 expiry);

    constructor() {
        owner = msg.sender;
    }

    function createPlan(string memory _name, uint256 _price, uint256 _duration) public {
        require(msg.sender == owner, "Only owner");
        plans.push(Plan(_name, _price, _duration));
        emit PlanCreated(plans.length - 1, _name, _price);
    }

    function subscribe(uint256 _planId) public payable {
        require(_planId < plans.length, "Invalid plan");
        require(msg.value >= plans[_planId].price, "Insufficient funds");

        uint256 currentExpiry = subscriptions[msg.sender].expiry;
        if (currentExpiry < block.timestamp) {
            currentExpiry = block.timestamp;
        }

        subscriptions[msg.sender] = Subscription(_planId, currentExpiry + plans[_planId].duration);
        emit Subscribed(msg.sender, _planId, subscriptions[msg.sender].expiry);
    }

    function isSubscribed(address _user) public view returns (bool) {
        return subscriptions[_user].expiry > block.timestamp;
    }
}
