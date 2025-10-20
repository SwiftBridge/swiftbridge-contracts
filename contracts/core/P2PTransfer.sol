// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUserRegistry {
    function getAddressByUsername(string memory username) external view returns (address);
    function getUsernameByAddress(address user) external view returns (string memory);
    function isUsernameRegistered(string memory username) external view returns (bool);
}

/**
 * @title P2PTransfer
 * @notice Enables peer-to-peer transfers using Telegram usernames
 * @dev Supports pending transfers that can be claimed after username registration
 */
contract P2PTransfer is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
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
    
    // State variables
    IUserRegistry public userRegistry;
    
    mapping(uint256 => Transfer) public transfers;
    mapping(string => uint256[]) public pendingTransfersByUsername;
    mapping(address => uint256[]) public sentTransfers;
    mapping(address => uint256[]) public receivedTransfers;
    
    uint256 public transferCounter;
    address public feeCollector;
    uint256 public feeBps = 25; // 0.25% fee in basis points
    
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
    
    constructor(address _userRegistry, address _feeCollector) Ownable(msg.sender) {
        if (_userRegistry == address(0) || _feeCollector == address(0)) {
            revert InvalidAddress();
        }
        userRegistry = IUserRegistry(_userRegistry);
        feeCollector = _feeCollector;
    }
    
    /**
     * @notice Send tokens to a Telegram username
     * @param toUsername Recipient's Telegram username
     * @param token Token address
     * @param amount Amount to send
     * @param message Optional message
     * @return transferId The created transfer ID
     */
    function sendToUsername(
        string memory toUsername,
        address token,
        uint256 amount,
        string memory message
    ) external whenNotPaused nonReentrant returns (uint256) {
        if (token == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();
        
        // Calculate fee
        uint256 fee = (amount * feeBps) / 10000;
        uint256 amountAfterFee = amount - fee;
        
        // Transfer tokens from sender
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Collect fee if applicable
        if (fee > 0) {
            IERC20(token).safeTransfer(feeCollector, fee);
        }
        
        uint256 transferId = ++transferCounter;
        
        // Check if username is registered
        bool isRegistered = userRegistry.isUsernameRegistered(toUsername);
        address toAddress = address(0);
        
        if (isRegistered) {
            try userRegistry.getAddressByUsername(toUsername) returns (address addr) {
                toAddress = addr;
                // Transfer immediately if registered
                IERC20(token).safeTransfer(toAddress, amountAfterFee);
            } catch {
                // If getAddress fails, treat as unregistered
                isRegistered = false;
            }
        }
        
        // Create transfer record
        transfers[transferId] = Transfer({
            id: transferId,
            from: msg.sender,
            toUsername: toUsername,
            toAddress: toAddress,
            token: token,
            amount: amountAfterFee,
            timestamp: block.timestamp,
            claimed: isRegistered,
            message: message
        });
        
        sentTransfers[msg.sender].push(transferId);
        
        if (!isRegistered) {
            // Add to pending if not registered
            pendingTransfersByUsername[toUsername].push(transferId);
        } else {
            receivedTransfers[toAddress].push(transferId);
        }
        
        emit TransferSent(transferId, msg.sender, toUsername, toAddress, token, amountAfterFee, message);
        
        return transferId;
    }
    
    /**
     * @notice Send tokens to multiple usernames in one transaction
     * @param recipients Array of recipient usernames
     * @param token Token address
     * @param amounts Array of amounts for each recipient
     * @param messages Array of messages for each recipient
     * @return transferIds Array of created transfer IDs
     */
    function batchSendToUsername(
        string[] memory recipients,
        address token,
        uint256[] memory amounts,
        string[] memory messages
    ) external whenNotPaused nonReentrant returns (uint256[] memory) {
        if (recipients.length != amounts.length || recipients.length != messages.length) {
            revert InvalidAmount();
        }
        if (token == address(0)) revert InvalidAddress();
        
        uint256[] memory transferIds = new uint256[](recipients.length);
        uint256 totalAmount = 0;
        
        // Calculate total amount needed
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) revert InvalidAmount();
            totalAmount += amounts[i];
        }
        
        // Transfer total amount from sender once
        IERC20(token).safeTransferFrom(msg.sender, address(this), totalAmount);
        
        // Process each transfer
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 fee = (amounts[i] * feeBps) / 10000;
            uint256 amountAfterFee = amounts[i] - fee;
            
            if (fee > 0) {
                IERC20(token).safeTransfer(feeCollector, fee);
            }
            
            uint256 transferId = ++transferCounter;
            transferIds[i] = transferId;
            
            bool isRegistered = userRegistry.isUsernameRegistered(recipients[i]);
            address toAddress = address(0);
            
            if (isRegistered) {
                try userRegistry.getAddressByUsername(recipients[i]) returns (address addr) {
                    toAddress = addr;
                    IERC20(token).safeTransfer(toAddress, amountAfterFee);
                } catch {
                    isRegistered = false;
                }
            }
            
            transfers[transferId] = Transfer({
                id: transferId,
                from: msg.sender,
                toUsername: recipients[i],
                toAddress: toAddress,
                token: token,
                amount: amountAfterFee,
                timestamp: block.timestamp,
                claimed: isRegistered,
                message: messages[i]
            });
            
            sentTransfers[msg.sender].push(transferId);
            
            if (!isRegistered) {
                pendingTransfersByUsername[recipients[i]].push(transferId);
            } else {
                receivedTransfers[toAddress].push(transferId);
            }
            
            emit TransferSent(transferId, msg.sender, recipients[i], toAddress, token, amountAfterFee, messages[i]);
        }
        
        emit BatchTransferSent(msg.sender, transferIds);
        
        return transferIds;
    }
    
    /**
     * @notice Claim all pending transfers for the caller's registered username
     * @return claimedIds Array of claimed transfer IDs
     */
    function claimPendingTransfers() external nonReentrant returns (uint256[] memory) {
        // Get caller's username from registry
        string memory username;
        try userRegistry.getUsernameByAddress(msg.sender) returns (string memory uname) {
            username = uname;
        } catch {
            revert UsernameNotRegistered();
        }
        
        uint256[] storage pendingIds = pendingTransfersByUsername[username];
        if (pendingIds.length == 0) revert NoPendingTransfers();
        
        uint256[] memory claimedIds = new uint256[](pendingIds.length);
        uint256 claimedCount = 0;
        
        for (uint256 i = 0; i < pendingIds.length; i++) {
            uint256 transferId = pendingIds[i];
            Transfer storage transfer = transfers[transferId];
            
            if (!transfer.claimed) {
                transfer.claimed = true;
                transfer.toAddress = msg.sender;
                
                // Transfer tokens to claimer
                IERC20(transfer.token).safeTransfer(msg.sender, transfer.amount);
                
                receivedTransfers[msg.sender].push(transferId);
                claimedIds[claimedCount] = transferId;
                claimedCount++;
                
                emit TransferClaimed(transferId, msg.sender);
            }
        }
        
        // Clear pending transfers
        delete pendingTransfersByUsername[username];
        
        // Resize array to actual claimed count
        assembly {
            mstore(claimedIds, claimedCount)
        }
        
        return claimedIds;
    }
    
    /**
     * @notice Get pending transfers for a username
     * @param username The Telegram username
     * @return Array of pending Transfer structs
     */
    function getPendingTransfers(string memory username) external view returns (Transfer[] memory) {
        uint256[] memory pendingIds = pendingTransfersByUsername[username];
        Transfer[] memory pending = new Transfer[](pendingIds.length);
        
        for (uint256 i = 0; i < pendingIds.length; i++) {
            pending[i] = transfers[pendingIds[i]];
        }
        
        return pending;
    }
    
    /**
     * @notice Get number of pending transfers for a username
     * @param username The Telegram username
     * @return Number of pending transfers
     */
    function getPendingTransferCount(string memory username) external view returns (uint256) {
        return pendingTransfersByUsername[username].length;
    }
    
    /**
     * @notice Get sent transfer history for an address
     * @param user The user address
     * @return Array of Transfer structs
     */
    function getSentTransfers(address user) external view returns (Transfer[] memory) {
        uint256[] memory sentIds = sentTransfers[user];
        Transfer[] memory sent = new Transfer[](sentIds.length);
        
        for (uint256 i = 0; i < sentIds.length; i++) {
            sent[i] = transfers[sentIds[i]];
        }
        
        return sent;
    }
    
    /**
     * @notice Get received transfer history for an address
     * @param user The user address
     * @return Array of Transfer structs
     */
    function getReceivedTransfers(address user) external view returns (Transfer[] memory) {
        uint256[] memory receivedIds = receivedTransfers[user];
        Transfer[] memory received = new Transfer[](receivedIds.length);
        
        for (uint256 i = 0; i < receivedIds.length; i++) {
            received[i] = transfers[receivedIds[i]];
        }
        
        return received;
    }
    
    /**
     * @notice Get transfer details
     * @param transferId The transfer ID
     * @return Transfer struct
     */
    function getTransfer(uint256 transferId) external view returns (Transfer memory) {
        return transfers[transferId];
    }
    
    // Admin functions
    
    function setUserRegistry(address _userRegistry) external onlyOwner {
        if (_userRegistry == address(0)) revert InvalidAddress();
        userRegistry = IUserRegistry(_userRegistry);
    }
    
    function setFee(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > 500) revert InvalidFee(); // Max 5%
        feeBps = newFeeBps;
        emit FeeUpdated(newFeeBps);
    }
    
    function setFeeCollector(address newFeeCollector) external onlyOwner {
        if (newFeeCollector == address(0)) revert InvalidAddress();
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
}