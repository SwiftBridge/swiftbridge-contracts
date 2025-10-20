// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IP2PTransfer
 * @notice Interface for P2PTransfer contract
 */
interface IP2PTransfer {
    // Structs
    struct Transfer {
        uint256 id;
        address from;
        string toUsername;
        address toAddress;
        address token;
        uint256 amount;
        uint256 timestamp;
        bool claimed;
        string message;
    }
    
    // Events
    event TransferSent(
        uint256 indexed transferId,
        address indexed from,
        string toUsername,
        address indexed toAddress,
        address token,
        uint256 amount,
        string message
    );
    event TransferClaimed(uint256 indexed transferId, address indexed claimedBy);
    event BatchTransferSent(address indexed from, uint256[] transferIds);
    event FeeUpdated(uint256 newFeeBps);
    event FeeCollectorUpdated(address indexed newFeeCollector);
    
    // Errors
    error InvalidUserRegistry();
    error InvalidAmount();
    error InvalidAddress();
    error UsernameNotRegistered();
    error TransferAlreadyClaimed();
    error UnauthorizedClaim();
    error InvalidFee();
    error NoPendingTransfers();
    
    // Functions
    function sendToUsername(
        string memory toUsername,
        address token,
        uint256 amount,
        string memory message
    ) external returns (uint256);
    
    function batchSendToUsername(
        string[] memory recipients,
        address token,
        uint256[] memory amounts,
        string[] memory messages
    ) external returns (uint256[] memory);
    
    function claimPendingTransfers() external returns (uint256[] memory);
    function getPendingTransfers(string memory username) external view returns (Transfer[] memory);
    function getPendingTransferCount(string memory username) external view returns (uint256);
    function getSentTransfers(address user) external view returns (Transfer[] memory);
    function getReceivedTransfers(address user) external view returns (Transfer[] memory);
    function getTransfer(uint256 transferId) external view returns (Transfer memory);
    
    // Admin functions
    function setUserRegistry(address _userRegistry) external;
    function setFee(uint256 newFeeBps) external;
    function setFeeCollector(address newFeeCollector) external;
    
    // State variables
    function userRegistry() external view returns (address);
    function transfers(uint256 transferId) external view returns (
        uint256 id,
        address from,
        string memory toUsername,
        address toAddress,
        address token,
        uint256 amount,
        uint256 timestamp,
        bool claimed,
        string memory message
    );
    function transferCounter() external view returns (uint256);
    function feeCollector() external view returns (address);
    function feeBps() external view returns (uint256);
}