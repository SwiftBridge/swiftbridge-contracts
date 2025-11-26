// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Crowdfund {
    struct Campaign {
        string title;
        address creator;
        uint256 goal;
        uint256 pledged;
        uint256 deadline;
        bool claimed;
    }

    Campaign[] public campaigns;
    mapping(uint256 => mapping(address => uint256)) public pledges;

    event CampaignCreated(uint256 indexed campaignId, string title, uint256 goal);
    event Pledged(uint256 indexed campaignId, address contributor, uint256 amount);
    event Claimed(uint256 indexed campaignId, uint256 amount);

    function createCampaign(string memory _title, uint256 _goal, uint256 _duration) public {
        campaigns.push(Campaign(_title, msg.sender, _goal, 0, block.timestamp + _duration, false));
        emit CampaignCreated(campaigns.length - 1, _title, _goal);
    }

    function pledge(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign ended");
        
        campaign.pledged += msg.value;
        pledges[_campaignId][msg.sender] += msg.value;
        emit Pledged(_campaignId, msg.sender, msg.value);
    }

    function claim(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Not creator");
        require(block.timestamp >= campaign.deadline, "Campaign not ended");
        require(campaign.pledged >= campaign.goal, "Goal not reached");
        require(!campaign.claimed, "Already claimed");

        campaign.claimed = true;
        payable(campaign.creator).transfer(campaign.pledged);
        emit Claimed(_campaignId, campaign.pledged);
    }

    function refund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign not ended");
        require(campaign.pledged < campaign.goal, "Goal reached");

        uint256 amount = pledges[_campaignId][msg.sender];
        require(amount > 0, "No pledge");

        pledges[_campaignId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
