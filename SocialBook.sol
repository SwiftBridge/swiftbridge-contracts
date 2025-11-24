// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SocialBook {
    struct Message {
        address sender;
        string message;
        string name;
        uint256 timestamp;
        uint256 likes;
        bool isDeleted;
    }

    struct UserProfile {
        string username;
        string bio;
        uint256 messageCount;
        uint256 followerCount;
        uint256 followingCount;
    }

    Message[] public messages;
    address public owner;

    // User profile mapping
    mapping(address => UserProfile) public profiles;

    // Track who liked which message
    mapping(uint256 => mapping(address => bool)) public messageLikes;

    // Following system
    mapping(address => mapping(address => bool)) public isFollowing;
    mapping(address => address[]) private followers;
    mapping(address => address[]) private following;

    event NewMessage(address indexed sender, string name, string message, uint256 indexed messageId);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 totalLikes);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker, uint256 totalLikes);
    event MessageEdited(uint256 indexed messageId, string newMessage);
    event MessageDeleted(uint256 indexed messageId, address indexed deletedBy);
    event ProfileUpdated(address indexed user, string username, string bio);
    event UserFollowed(address indexed follower, address indexed followee);
    event UserUnfollowed(address indexed follower, address indexed followee);

    constructor() {
        owner = msg.sender;
    }

    // Original functionality - Post a message
    function postMessage(string memory _name, string memory _message) public {
        require(bytes(_message).length > 0, "Message cannot be empty");
        require(bytes(_name).length > 0, "Name cannot be empty");

        messages.push(Message({
            sender: msg.sender,
            message: _message,
            name: _name,
            timestamp: block.timestamp,
            likes: 0,
            isDeleted: false
        }));

        profiles[msg.sender].messageCount++;

        emit NewMessage(msg.sender, _name, _message, messages.length - 1);
    }

    // NEW FEATURE 1: Like/Unlike messages
    function likeMessage(uint256 messageId) public {
        require(messageId < messages.length, "Invalid message ID");
        require(!messages[messageId].isDeleted, "Message has been deleted");
        require(!messageLikes[messageId][msg.sender], "Already liked this message");

        messageLikes[messageId][msg.sender] = true;
        messages[messageId].likes++;

        emit MessageLiked(messageId, msg.sender, messages[messageId].likes);
    }

    function unlikeMessage(uint256 messageId) public {
        require(messageId < messages.length, "Invalid message ID");
        require(!messages[messageId].isDeleted, "Message has been deleted");
        require(messageLikes[messageId][msg.sender], "Haven't liked this message");

        messageLikes[messageId][msg.sender] = false;
        messages[messageId].likes--;

        emit MessageUnliked(messageId, msg.sender, messages[messageId].likes);
    }

    // NEW FEATURE 2: User Profiles
    function updateProfile(string memory _username, string memory _bio) public {
        require(bytes(_username).length > 0, "Username cannot be empty");

        profiles[msg.sender].username = _username;
        profiles[msg.sender].bio = _bio;

        emit ProfileUpdated(msg.sender, _username, _bio);
    }

    function getProfile(address user) public view returns (
        string memory username,
        string memory bio,
        uint256 messageCount,
        uint256 followerCount,
        uint256 followingCount
    ) {
        UserProfile memory profile = profiles[user];
        return (
            profile.username,
            profile.bio,
            profile.messageCount,
            profile.followerCount,
            profile.followingCount
        );
    }

    // NEW FEATURE 3: Following System
    function followUser(address userToFollow) public {
        require(userToFollow != msg.sender, "Cannot follow yourself");
        require(!isFollowing[msg.sender][userToFollow], "Already following this user");

        isFollowing[msg.sender][userToFollow] = true;
        followers[userToFollow].push(msg.sender);
        following[msg.sender].push(userToFollow);

        profiles[userToFollow].followerCount++;
        profiles[msg.sender].followingCount++;

        emit UserFollowed(msg.sender, userToFollow);
    }

    function unfollowUser(address userToUnfollow) public {
        require(isFollowing[msg.sender][userToUnfollow], "Not following this user");

        isFollowing[msg.sender][userToUnfollow] = false;

        // Remove from followers array
        _removeFromArray(followers[userToUnfollow], msg.sender);
        _removeFromArray(following[msg.sender], userToUnfollow);

        profiles[userToUnfollow].followerCount--;
        profiles[msg.sender].followingCount--;

        emit UserUnfollowed(msg.sender, userToUnfollow);
    }

    function getFollowers(address user) public view returns (address[] memory) {
        return followers[user];
    }

    function getFollowing(address user) public view returns (address[] memory) {
        return following[user];
    }

    // NEW FEATURE 4: Edit Messages
    function editMessage(uint256 messageId, string memory newMessage) public {
        require(messageId < messages.length, "Invalid message ID");
        require(messages[messageId].sender == msg.sender, "Not your message");
        require(!messages[messageId].isDeleted, "Message has been deleted");
        require(bytes(newMessage).length > 0, "Message cannot be empty");

        messages[messageId].message = newMessage;

        emit MessageEdited(messageId, newMessage);
    }

    // NEW FEATURE 5: Delete Messages
    function deleteMessage(uint256 messageId) public {
        require(messageId < messages.length, "Invalid message ID");
        require(
            messages[messageId].sender == msg.sender || msg.sender == owner,
            "Not authorized to delete this message"
        );
        require(!messages[messageId].isDeleted, "Message already deleted");

        messages[messageId].isDeleted = true;

        emit MessageDeleted(messageId, msg.sender);
    }

    // Helper function to remove address from array
    function _removeFromArray(address[] storage array, address element) private {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }

    // Original functionality - Get total messages
    function getTotalMessages() public view returns (uint256) {
        return messages.length;
    }

    // Original functionality - Get a specific message
    function getMessage(uint256 index) public view returns (
        address sender,
        string memory name,
        string memory message,
        uint256 timestamp,
        uint256 likes,
        bool isDeleted
    ) {
        require(index < messages.length, "Invalid index");
        Message memory m = messages[index];
        return (m.sender, m.name, m.message, m.timestamp, m.likes, m.isDeleted);
    }

    // Original functionality - Get all messages (including deleted ones)
    function getAllMessages() public view returns (Message[] memory) {
        return messages;
    }

    // Get all active (non-deleted) messages
    function getActiveMessages() public view returns (Message[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < messages.length; i++) {
            if (!messages[i].isDeleted) {
                activeCount++;
            }
        }

        Message[] memory activeMessages = new Message[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < messages.length; i++) {
            if (!messages[i].isDeleted) {
                activeMessages[currentIndex] = messages[i];
                currentIndex++;
            }
        }

        return activeMessages;
    }

    // Get messages by a specific user
    function getMessagesByUser(address user) public view returns (uint256[] memory) {
        uint256 userMessageCount = 0;
        for (uint256 i = 0; i < messages.length; i++) {
            if (messages[i].sender == user && !messages[i].isDeleted) {
                userMessageCount++;
            }
        }

        uint256[] memory userMessageIds = new uint256[](userMessageCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < messages.length; i++) {
            if (messages[i].sender == user && !messages[i].isDeleted) {
                userMessageIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return userMessageIds;
    }

    // Check if user has liked a message
    function hasLikedMessage(uint256 messageId, address user) public view returns (bool) {
        require(messageId < messages.length, "Invalid message ID");
        return messageLikes[messageId][user];
    }
}
