// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title EscrowManager
 * @notice Manages escrow for buy/sell operations between crypto and fiat (Naira)
 * @dev Handles token locking, release, disputes, and timeouts
 */
contract EscrowManager is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
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
    
    // State variables
    mapping(uint256 => Escrow) public escrows;
    mapping(address => bool) public trustedOperators;
    mapping(address => uint256[]) public userEscrows;
    
    uint256 public escrowCounter;
    uint256 public constant ESCROW_TIMEOUT = 24 hours;
    address public feeCollector;
    uint256 public feeBps = 50; // 0.5% fee in basis points
    
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
    
    // Modifiers
    modifier onlyOperator() {
        if (!trustedOperators[msg.sender] && msg.sender != owner()) {
            revert UnauthorizedOperator();
        }
        _;
    }
    
    constructor(address _feeCollector) Ownable(msg.sender) {
        if (_feeCollector == address(0)) revert InvalidAddress();
        feeCollector = _feeCollector;
    }
    
    /**
     * @notice Create a BUY escrow (user buying crypto with Naira)
     * @param user The user's address
     * @param token The token address
     * @param amount The amount of tokens
     * @param nairaAmount The equivalent Naira amount
     * @param paymentReference Unique payment reference
     * @return escrowId The created escrow ID
     */
    function createBuyEscrow(
        address user,
        address token,
        uint256 amount,
        uint256 nairaAmount,
        string memory paymentReference
    ) external onlyOperator whenNotPaused nonReentrant returns (uint256) {
        if (user == address(0) || token == address(0)) revert InvalidAddress();
        if (amount == 0 || nairaAmount == 0) revert InvalidAmount();
        
        // Transfer tokens from operator to contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        uint256 escrowId = ++escrowCounter;
        
        escrows[escrowId] = Escrow({
            id: escrowId,
            user: user,
            token: token,
            amount: amount,
            nairaAmount: nairaAmount,
            escrowType: EscrowType.BUY,
            status: EscrowStatus.PENDING,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + ESCROW_TIMEOUT,
            paymentReference: paymentReference,
            disputedBy: address(0)
        });
        
        userEscrows[user].push(escrowId);
        
        emit EscrowCreated(escrowId, user, EscrowType.BUY, token, amount, nairaAmount, paymentReference);
        
        return escrowId;
    }
    
    /**
     * @notice Create a SELL escrow (user selling crypto for Naira)
     * @param token The token address
     * @param amount The amount of tokens
     * @param nairaAmount The equivalent Naira amount
     * @param paymentReference Unique payment reference
     * @return escrowId The created escrow ID
     */
    function createSellEscrow(
        address token,
        uint256 amount,
        uint256 nairaAmount,
        string memory paymentReference
    ) external whenNotPaused nonReentrant returns (uint256) {
        if (token == address(0)) revert InvalidAddress();
        if (amount == 0 || nairaAmount == 0) revert InvalidAmount();
        
        // Transfer tokens from user to contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        uint256 escrowId = ++escrowCounter;
        
        escrows[escrowId] = Escrow({
            id: escrowId,
            user: msg.sender,
            token: token,
            amount: amount,
            nairaAmount: nairaAmount,
            escrowType: EscrowType.SELL,
            status: EscrowStatus.PENDING,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + ESCROW_TIMEOUT,
            paymentReference: paymentReference,
            disputedBy: address(0)
        });
        
        userEscrows[msg.sender].push(escrowId);
        
        emit EscrowCreated(escrowId, msg.sender, EscrowType.SELL, token, amount, nairaAmount, paymentReference);
        
        return escrowId;
    }
    
    /**
     * @notice Release escrow to the recipient
     * @param escrowId The escrow ID
     */
    function releaseEscrow(uint256 escrowId) external onlyOperator nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        
        if (escrow.id == 0) revert InvalidEscrowId();
        if (escrow.status != EscrowStatus.PENDING) revert InvalidEscrowStatus();
        
        escrow.status = EscrowStatus.COMPLETED;
        
        // Calculate fee
        uint256 fee = (escrow.amount * feeBps) / 10000;
        uint256 amountAfterFee = escrow.amount - fee;
        
        // Determine recipient based on escrow type
        address recipient;
        if (escrow.escrowType == EscrowType.BUY) {
            // User is buying crypto, send to user
            recipient = escrow.user;
        } else {
            // User is selling crypto, send to operator
            recipient = msg.sender;
        }
        
        // Transfer tokens
        if (fee > 0) {
            IERC20(escrow.token).safeTransfer(feeCollector, fee);
        }
        IERC20(escrow.token).safeTransfer(recipient, amountAfterFee);
        
        emit EscrowReleased(escrowId, recipient, amountAfterFee);
    }
    
    /**
     * @notice Cancel an escrow and refund
     * @param escrowId The escrow ID
     */
    function cancelEscrow(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        
        if (escrow.id == 0) revert InvalidEscrowId();
        if (escrow.status != EscrowStatus.PENDING) revert InvalidEscrowStatus();
        
        // Only operator or user can cancel
        if (msg.sender != escrow.user && !trustedOperators[msg.sender] && msg.sender != owner()) {
            revert UnauthorizedOperator();
        }
        
        escrow.status = EscrowStatus.CANCELLED;
        
        // Refund tokens to original sender
        address refundRecipient;
        if (escrow.escrowType == EscrowType.BUY) {
            // Refund to operator (who supplied the crypto)
            refundRecipient = msg.sender;
        } else {
            // Refund to user (who supplied the crypto)
            refundRecipient = escrow.user;
        }
        
        IERC20(escrow.token).safeTransfer(refundRecipient, escrow.amount);
        
        emit EscrowCancelled(escrowId, escrow.user);
    }
    
    /**
     * @notice Dispute an escrow
     * @param escrowId The escrow ID
     */
    function disputeEscrow(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        
        if (escrow.id == 0) revert InvalidEscrowId();
        if (escrow.status != EscrowStatus.PENDING) revert InvalidEscrowStatus();
        
        // Only user or operator can dispute
        if (msg.sender != escrow.user && !trustedOperators[msg.sender]) {
            revert UnauthorizedOperator();
        }
        
        escrow.status = EscrowStatus.DISPUTED;
        escrow.disputedBy = msg.sender;
        
        emit EscrowDisputed(escrowId, msg.sender);
    }
    
    /**
     * @notice Resolve a disputed escrow (owner only)
     * @param escrowId The escrow ID
     * @param releaseToUser If true, release to user; otherwise refund
     */
    function resolveDispute(uint256 escrowId, bool releaseToUser) external onlyOwner nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        
        if (escrow.id == 0) revert InvalidEscrowId();
        if (escrow.status != EscrowStatus.DISPUTED) revert InvalidEscrowStatus();
        
        escrow.status = EscrowStatus.COMPLETED;
        
        address recipient;
        if (releaseToUser) {
            recipient = escrow.user;
        } else {
            // Refund based on escrow type
            if (escrow.escrowType == EscrowType.SELL) {
                recipient = escrow.user;
            } else {
                // For BUY escrows, we can't identify operator here, so send to owner
                recipient = owner();
            }
        }
        
        IERC20(escrow.token).safeTransfer(recipient, escrow.amount);
        
        emit DisputeResolved(escrowId, releaseToUser);
    }
    
    /**
     * @notice Claim expired escrow
     * @param escrowId The escrow ID
     */
    function claimExpiredEscrow(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        
        if (escrow.id == 0) revert InvalidEscrowId();
        if (escrow.status != EscrowStatus.PENDING) revert InvalidEscrowStatus();
        if (block.timestamp < escrow.expiresAt) revert EscrowNotExpired();
        
        escrow.status = EscrowStatus.REFUNDED;
        
        // Refund to original sender
        address refundRecipient;
        if (escrow.escrowType == EscrowType.SELL) {
            refundRecipient = escrow.user;
        } else {
            // For BUY type, only operator can claim
            if (!trustedOperators[msg.sender] && msg.sender != owner()) {
                revert UnauthorizedOperator();
            }
            refundRecipient = msg.sender;
        }
        
        IERC20(escrow.token).safeTransfer(refundRecipient, escrow.amount);
        
        emit EscrowCancelled(escrowId, escrow.user);
    }
    
    /**
     * @notice Get user's escrow IDs
     * @param user The user address
     * @return Array of escrow IDs
     */
    function getUserEscrows(address user) external view returns (uint256[] memory) {
        return userEscrows[user];
    }
    
    /**
     * @notice Get escrow details
     * @param escrowId The escrow ID
     * @return Escrow struct
     */
    function getEscrow(uint256 escrowId) external view returns (Escrow memory) {
        return escrows[escrowId];
    }
    
    // Admin functions
    
    function addOperator(address operator) external onlyOwner {
        if (operator == address(0)) revert InvalidAddress();
        trustedOperators[operator] = true;
        emit OperatorAdded(operator);
    }
    
    function removeOperator(address operator) external onlyOwner {
        trustedOperators[operator] = false;
        emit OperatorRemoved(operator);
    }
    
    function setFee(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > 1000) revert InvalidFee(); // Max 10%
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