// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract StakingRewards {
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakingTime;
    
    uint256 public rewardRate = 10; // 10% per time unit (simplified)

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    function stake() public payable {
        require(msg.value > 0, "Cannot stake 0");
        if (stakedBalance[msg.sender] > 0) {
            claimReward();
        }
        stakedBalance[msg.sender] += msg.value;
        stakingTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, msg.value);
    }

    function calculateReward(address _user) public view returns (uint256) {
        if (stakedBalance[_user] == 0) return 0;
        uint256 timeElapsed = block.timestamp - stakingTime[_user];
        return (stakedBalance[_user] * rewardRate * timeElapsed) / (100 * 1 days);
    }

    function claimReward() internal {
        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            payable(msg.sender).transfer(reward);
        }
        stakingTime[msg.sender] = block.timestamp;
    }

    function withdraw() public {
        require(stakedBalance[msg.sender] > 0, "No stake");
        uint256 reward = calculateReward(msg.sender);
        uint256 amount = stakedBalance[msg.sender];
        
        stakedBalance[msg.sender] = 0;
        stakingTime[msg.sender] = 0;
        
        payable(msg.sender).transfer(amount + reward);
        emit Withdrawn(msg.sender, amount, reward);
    }
    
    receive() external payable {}
}
