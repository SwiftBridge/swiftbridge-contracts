// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ReferralSystem {
    mapping(address => address) public referrers;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public rewards;

    event ReferralRegistered(address indexed user, address indexed referrer);
    event RewardClaimed(address indexed user, uint256 amount);

    function registerReferrer(address _referrer) public {
        require(referrers[msg.sender] == address(0), "Already registered");
        require(_referrer != msg.sender, "Cannot refer self");
        
        referrers[msg.sender] = _referrer;
        referralCount[_referrer]++;
        rewards[_referrer] += 100; // Mock reward points
        emit ReferralRegistered(msg.sender, _referrer);
    }

    function claimRewards() public {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards");
        
        rewards[msg.sender] = 0;
        // Logic to transfer tokens or ETH would go here
        emit RewardClaimed(msg.sender, reward);
    }
}
