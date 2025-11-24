// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title UserRegistry
 * @notice Maps Telegram usernames to wallet addresses for P2P transfers
 * @dev Implements username registration with cooldown period for updates
 */
contract UserRegistry is Ownable, Pausable {
    // Mapping from username to address
    mapping(string => address) public usernameToAddress;
    
    // Mapping from address to username
    mapping(address => string) public addressToUsername;
    
    // Mapping to track last update time for cooldown
    mapping(address => uint256) public lastUpdateTime;
    
    // Cooldown period before username can be updated (7 days)
    uint256 public constant UPDATE_COOLDOWN = 7 days;
    
    // Events
    event UsernameRegistered(address indexed user, string username, uint256 timestamp);
    event UsernameUpdated(address indexed user, string oldUsername, string newUsername, uint256 timestamp);
    event UsernameRemoved(address indexed user, string username, uint256 timestamp);
    
    // Errors
    error InvalidUsername();
    error UsernameAlreadyTaken();
    error UpdateCooldownActive(uint256 remainingTime);
    error NoUsernameRegistered();
    error UsernameNotRegistered();
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @notice Register a Telegram username to the caller's address
     * @param username The Telegram username (without @)
     */
    function registerUsername(string memory username) external whenNotPaused {
        // Validate username
        if (!_isValidUsername(username)) {
            revert InvalidUsername();
        }
        
        // Check if username is already taken
        if (usernameToAddress[username] != address(0)) {
            revert UsernameAlreadyTaken();
        }
        
        // Check if user already has a username
        string memory currentUsername = addressToUsername[msg.sender];
        if (bytes(currentUsername).length > 0) {
            // Remove old mapping
            delete usernameToAddress[currentUsername];
        }
        
        // Create new mappings
        usernameToAddress[username] = msg.sender;
        addressToUsername[msg.sender] = username;
        lastUpdateTime[msg.sender] = block.timestamp;
        
        emit UsernameRegistered(msg.sender, username, block.timestamp);
    }
    
    /**
     * @notice Update registered username (subject to cooldown)
     * @param newUsername The new Telegram username
     */
    function updateUsername(string memory newUsername) external whenNotPaused {
        // Validate new username
        if (!_isValidUsername(newUsername)) {
            revert InvalidUsername();
        }
        
        // Check if new username is available
        if (usernameToAddress[newUsername] != address(0)) {
            revert UsernameAlreadyTaken();
        }
        
        // Get current username
        string memory oldUsername = addressToUsername[msg.sender];
        if (bytes(oldUsername).length == 0) {
            revert NoUsernameRegistered();
        }
        
        // Check cooldown period
        uint256 timeSinceLastUpdate = block.timestamp - lastUpdateTime[msg.sender];
        if (timeSinceLastUpdate < UPDATE_COOLDOWN) {
            revert UpdateCooldownActive(UPDATE_COOLDOWN - timeSinceLastUpdate);
        }
        
        // Remove old mapping
        delete usernameToAddress[oldUsername];
        
        // Create new mappings
        usernameToAddress[newUsername] = msg.sender;
        addressToUsername[msg.sender] = newUsername;
        lastUpdateTime[msg.sender] = block.timestamp;
        
        emit UsernameUpdated(msg.sender, oldUsername, newUsername, block.timestamp);
    }
    
    /**
     * @notice Remove username registration
     */
    function removeUsername() external {
        string memory username = addressToUsername[msg.sender];
        if (bytes(username).length == 0) {
            revert NoUsernameRegistered();
        }
        
        delete usernameToAddress[username];
        delete addressToUsername[msg.sender];
        
        emit UsernameRemoved(msg.sender, username, block.timestamp);
    }
    
    /**
     * @notice Get address by username
     * @param username The Telegram username
     * @return The address associated with the username
     */
    function getAddressByUsername(string memory username) external view returns (address) {
        address userAddress = usernameToAddress[username];
        if (userAddress == address(0)) {
            revert UsernameNotRegistered();
        }
        return userAddress;
    }
    
    /**
     * @notice Get username by address
     * @param user The wallet address
     * @return The username associated with the address
     */
    function getUsernameByAddress(address user) external view returns (string memory) {
        string memory username = addressToUsername[user];
        if (bytes(username).length == 0) {
            revert NoUsernameRegistered();
        }
        return username;
    }
    
    /**
     * @notice Check if a username is registered
     * @param username The Telegram username
     * @return True if registered, false otherwise
     */
    function isUsernameRegistered(string memory username) external view returns (bool) {
        return usernameToAddress[username] != address(0);
    }
    
    /**
     * @notice Check if an address has a registered username
     * @param user The wallet address
     * @return True if user has a username, false otherwise
     */
    function hasUsername(address user) external view returns (bool) {
        return bytes(addressToUsername[user]).length > 0;
    }
    
    /**
     * @notice Get remaining cooldown time
     * @param user The wallet address
     * @return Remaining seconds until update is allowed
     */
    function getRemainingCooldown(address user) external view returns (uint256) {
        uint256 timeSinceLastUpdate = block.timestamp - lastUpdateTime[user];
        if (timeSinceLastUpdate >= UPDATE_COOLDOWN) {
            return 0;
        }
        return UPDATE_COOLDOWN - timeSinceLastUpdate;
    }
    
    /**
     * @dev Validate username format
     * @param username The username to validate
     * @return True if valid, false otherwise
     */
    function _isValidUsername(string memory username) internal pure returns (bool) {
        bytes memory usernameBytes = bytes(username);
        uint256 length = usernameBytes.length;
        
        // Check length (5-32 characters for Telegram usernames)
        if (length < 5 || length > 32) {
            return false;
        }
        
        // Check each character
        for (uint256 i = 0; i < length; i++) {
            bytes1 char = usernameBytes[i];
            
            // Allow: a-z, A-Z, 0-9, underscore
            bool isLowerCase = char >= 0x61 && char <= 0x7A; // a-z
            bool isUpperCase = char >= 0x41 && char <= 0x5A; // A-Z
            bool isDigit = char >= 0x30 && char <= 0x39; // 0-9
            bool isUnderscore = char == 0x5F; // _
            
            if (!isLowerCase && !isUpperCase && !isDigit && !isUnderscore) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @notice Pause the contract (owner only)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Unpause the contract (owner only)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}