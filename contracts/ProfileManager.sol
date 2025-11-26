// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ProfileManager {
    struct Profile {
        string username;
        string bio;
        string avatarUrl;
        bool exists;
    }

    mapping(address => Profile) public profiles;
    mapping(string => bool) public usernameTaken;

    event ProfileUpdated(address indexed user, string username);

    function setProfile(string memory _username, string memory _bio, string memory _avatarUrl) public {
        if (!profiles[msg.sender].exists) {
            require(!usernameTaken[_username], "Username taken");
            usernameTaken[_username] = true;
        } else {
            // If changing username, check availability
            if (keccak256(bytes(profiles[msg.sender].username)) != keccak256(bytes(_username))) {
                require(!usernameTaken[_username], "Username taken");
                usernameTaken[profiles[msg.sender].username] = false;
                usernameTaken[_username] = true;
            }
        }
        profiles[msg.sender] = Profile(_username, _bio, _avatarUrl, true);
        emit ProfileUpdated(msg.sender, _username);
    }

    function getProfile(address _user) public view returns (Profile memory) {
        return profiles[_user];
    }
}
