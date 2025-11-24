// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IEscrowManager
 * @notice Interface for EscrowManager contract
 */
interface IEscrowManager {
    // Enums
    enum EscrowType { BUY, SELL }
    enum EscrowStatus { PENDING, COMPLETED, DISPUTED, CANCELLED, REFUNDED }
    
    // Structs
    struct Escrow {
        uint256 id;
        address user;
        address token;
        uint256 amount;
        uint256 nairaAmount;
        EscrowType escrowType;
        EscrowStatus status;
        uint256 createdAt;
        uint256 expiresAt;
        string paymentReference;
        address disputedBy;
    }
    
    // Events
    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed user,
        EscrowType escrowType,
        address token,
        uint256 amount,
        uint256 nairaAmount,
        string paymentReference
    );
    event EscrowReleased(uint256 indexed escrowId, address indexed recipient, uint256 amount);
    event EscrowCancelled(uint256 indexed escrowId, address indexed user);
    event EscrowDisputed(uint256 indexed escrowId, address indexed disputedBy);
    event DisputeResolved(uint256 indexed escrowId, bool releasedToUser);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event FeeUpdated(uint256 newFeeBps);
    event FeeCollectorUpdated(address indexed newFeeCollector);
    
    // Errors
    error UnauthorizedOperator();
    error InvalidEscrowId();
    error InvalidEscrowStatus();
    error EscrowNotExpired();
    error InvalidAmount();
    error InvalidAddress();
    error InvalidFee();
    
    // Functions
    function createBuyEscrow(
        address user,
        address token,
        uint256 amount,
        uint256 nairaAmount,
        string memory paymentReference
    ) external returns (uint256);
    
    function createSellEscrow(
        address token,
        uint256 amount,
        uint256 nairaAmount,
        string memory paymentReference
    ) external returns (uint256);
    
    function releaseEscrow(uint256 escrowId) external;
    function cancelEscrow(uint256 escrowId) external;
    function disputeEscrow(uint256 escrowId) external;
    function resolveDispute(uint256 escrowId, bool releaseToUser) external;
    function claimExpiredEscrow(uint256 escrowId) external;
    function getUserEscrows(address user) external view returns (uint256[] memory);
    function getEscrow(uint256 escrowId) external view returns (Escrow memory);
    
    // Admin functions
    function addOperator(address operator) external;
    function removeOperator(address operator) external;
    function setFee(uint256 newFeeBps) external;
    function setFeeCollector(address newFeeCollector) external;
    
    // State variables
    function escrows(uint256 escrowId) external view returns (
        uint256 id,
        address user,
        address token,
        uint256 amount,
        uint256 nairaAmount,
        EscrowType escrowType,
        EscrowStatus status,
        uint256 createdAt,
        uint256 expiresAt,
        string memory paymentReference,
        address disputedBy
    );
    function trustedOperators(address operator) external view returns (bool);
    function escrowCounter() external view returns (uint256);
    function ESCROW_TIMEOUT() external view returns (uint256);
    function feeCollector() external view returns (address);
    function feeBps() external view returns (uint256);
}