// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ReputationSystem {
    mapping(address => uint256) public reputation;
    mapping(address => mapping(address => bool)) public hasEndorsed;

    event ReputationChanged(address indexed user, uint256 newScore);

    function endorse(address _user) public {
        require(msg.sender != _user, "Cannot endorse self");
        require(!hasEndorsed[msg.sender][_user], "Already endorsed");
        
        hasEndorsed[msg.sender][_user] = true;
        reputation[_user]++;
        emit ReputationChanged(_user, reputation[_user]);
    }

    function revokeEndorsement(address _user) public {
        require(hasEndorsed[msg.sender][_user], "Not endorsed");
        
        hasEndorsed[msg.sender][_user] = false;
        if (reputation[_user] > 0) {
            reputation[_user]--;
        }
        emit ReputationChanged(_user, reputation[_user]);
    }

    function getReputation(address _user) public view returns (uint256) {
        return reputation[_user];
    }
}
