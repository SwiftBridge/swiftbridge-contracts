// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Uniswap V3 interfaces
interface IUniswapV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

interface IWETH {
    function withdraw(uint256) external;
}

/**
 * @title SwapRouter
 * @notice Handles token swaps via Uniswap V3 on Base network
 * @dev Integrates with Uniswap V3 Router for token exchanges
 */
contract SwapRouter is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // State variables
    IUniswapV3SwapRouter public immutable uniswapRouter;
    IQuoter public quoter;
    address public immutable WETH;
    
    address public feeCollector;
    uint256 public feeBps = 30; // 0.3% fee in basis points
    
    // Supported pool fees
    uint24 public constant POOL_FEE_LOW = 500;      // 0.05%
    uint24 public constant POOL_FEE_MEDIUM = 3000;  // 0.3%
    uint24 public constant POOL_FEE_HIGH = 10000;   // 1%
    
    // Events
    event SwapExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint24 poolFee
    );
    event FeeUpdated(uint256 newFeeBps);
    event FeeCollectorUpdated(address indexed newFeeCollector);
    event QuoterUpdated(address indexed newQuoter);
    
    // Errors
    error InvalidAddress();
    error InvalidAmount();
    error InvalidFee();
    error SlippageExceeded();
    error SwapFailed();
    error InsufficientOutput();
    
    constructor(
        address _uniswapRouter,
        address _quoter,
        address _weth,
        address _feeCollector
    ) Ownable(msg.sender) {
        if (_uniswapRouter == address(0) || _weth == address(0) || _feeCollector == address(0)) {
            revert InvalidAddress();
        }
        
        uniswapRouter = IUniswapV3SwapRouter(_uniswapRouter);
        quoter = IQuoter(_quoter);
        WETH = _weth;
        feeCollector = _feeCollector;
    }
    
    /**
     * @notice Swap exact tokens for tokens
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @param amountOutMinimum Minimum amount of output tokens (slippage protection)
     * @param poolFee Uniswap pool fee tier
     * @return amountOut Amount of output tokens received
     */
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint24 poolFee
    ) external whenNotPaused nonReentrant returns (uint256 amountOut) {
        if (tokenIn == address(0) || tokenOut == address(0)) revert InvalidAddress();
        if (amountIn == 0) revert InvalidAmount();
        if (!_isValidPoolFee(poolFee)) revert InvalidFee();
        
        // Calculate platform fee
        uint256 platformFee = (amountIn * feeBps) / 10000;
        uint256 amountToSwap = amountIn - platformFee;
        
        // Transfer tokens from user
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        
        // Collect platform fee
        if (platformFee > 0) {
            IERC20(tokenIn).safeTransfer(feeCollector, platformFee);
        }
        
        // Approve Uniswap router
        IERC20(tokenIn).forceApprove(address(uniswapRouter), amountToSwap);
        
        // Execute swap
        IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountToSwap,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });
        
        amountOut = uniswapRouter.exactInputSingle(params);
        
        if (amountOut < amountOutMinimum) revert SlippageExceeded();
        
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut, poolFee);
        
        return amountOut;
    }
    
    /**
     * @notice Swap exact ETH for tokens
     * @param tokenOut Output token address
     * @param amountOutMinimum Minimum amount of output tokens
     * @param poolFee Uniswap pool fee tier
     * @return amountOut Amount of output tokens received
     */
    function swapExactETHForTokens(
        address tokenOut,
        uint256 amountOutMinimum,
        uint24 poolFee
    ) external payable whenNotPaused nonReentrant returns (uint256 amountOut) {
        if (tokenOut == address(0)) revert InvalidAddress();
        if (msg.value == 0) revert InvalidAmount();
        if (!_isValidPoolFee(poolFee)) revert InvalidFee();
        
        // Calculate platform fee
        uint256 platformFee = (msg.value * feeBps) / 10000;
        uint256 amountToSwap = msg.value - platformFee;
        
        // Send platform fee
        if (platformFee > 0) {
            (bool success, ) = feeCollector.call{value: platformFee}("");
            if (!success) revert SwapFailed();
        }
        
        // Execute swap
        IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountToSwap,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });
        
        amountOut = uniswapRouter.exactInputSingle{value: amountToSwap}(params);
        
        if (amountOut < amountOutMinimum) revert SlippageExceeded();
        
        emit SwapExecuted(msg.sender, WETH, tokenOut, msg.value, amountOut, poolFee);
        
        return amountOut;
    }
    
    /**
     * @notice Swap exact tokens for ETH
     * @param tokenIn Input token address
     * @param amountIn Amount of input tokens
     * @param amountOutMinimum Minimum amount of ETH
     * @param poolFee Uniswap pool fee tier
     * @return amountOut Amount of ETH received
     */
    function swapExactTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint24 poolFee
    ) external whenNotPaused nonReentrant returns (uint256 amountOut) {
        if (tokenIn == address(0)) revert InvalidAddress();
        if (amountIn == 0) revert InvalidAmount();
        if (!_isValidPoolFee(poolFee)) revert InvalidFee();
        
        // Calculate platform fee
        uint256 platformFee = (amountIn * feeBps) / 10000;
        uint256 amountToSwap = amountIn - platformFee;
        
        // Transfer tokens from user
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        
        // Collect platform fee
        if (platformFee > 0) {
            IERC20(tokenIn).safeTransfer(feeCollector, platformFee);
        }
        
        // Approve Uniswap router
        IERC20(tokenIn).forceApprove(address(uniswapRouter), amountToSwap);
        
        // Execute swap
        IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: WETH,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountToSwap,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });
        
        amountOut = uniswapRouter.exactInputSingle(params);
        
        if (amountOut < amountOutMinimum) revert SlippageExceeded();
        
        // Unwrap WETH and send ETH to user
        IWETH(WETH).withdraw(amountOut);
        (bool success, ) = msg.sender.call{value: amountOut}("");
        if (!success) revert SwapFailed();
        
        emit SwapExecuted(msg.sender, tokenIn, WETH, amountIn, amountOut, poolFee);
        
        return amountOut;
    }
    
    /**
     * @notice Get quote for token swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @param poolFee Uniswap pool fee tier
     * @return amountOut Expected amount of output tokens
     */
    function getQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 poolFee
    ) external returns (uint256 amountOut) {
        if (address(quoter) == address(0)) revert InvalidAddress();
        
        // Subtract platform fee from quote
        uint256 platformFee = (amountIn * feeBps) / 10000;
        uint256 amountToSwap = amountIn - platformFee;
        
        try quoter.quoteExactInputSingle(tokenIn, tokenOut, poolFee, amountToSwap, 0) returns (uint256 quote) {
            return quote;
        } catch {
            revert SwapFailed();
        }
    }
    
    /**
     * @notice Get best pool fee for a token pair
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @return bestFee The pool fee with the best output
     * @return bestAmountOut The best output amount
     */
    function getBestPoolFee(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint24 bestFee, uint256 bestAmountOut) {
        if (address(quoter) == address(0)) revert InvalidAddress();
        
        uint256 platformFee = (amountIn * feeBps) / 10000;
        uint256 amountToSwap = amountIn - platformFee;
        
        uint24[3] memory fees = [POOL_FEE_LOW, POOL_FEE_MEDIUM, POOL_FEE_HIGH];
        bestAmountOut = 0;
        bestFee = POOL_FEE_MEDIUM;
        
        for (uint256 i = 0; i < fees.length; i++) {
            try quoter.quoteExactInputSingle(tokenIn, tokenOut, fees[i], amountToSwap, 0) returns (uint256 amountOut) {
                if (amountOut > bestAmountOut) {
                    bestAmountOut = amountOut;
                    bestFee = fees[i];
                }
            } catch {
                continue;
            }
        }
        
        if (bestAmountOut == 0) revert InsufficientOutput();
        
        return (bestFee, bestAmountOut);
    }
    
    /**
     * @dev Check if pool fee is valid
     */
    function _isValidPoolFee(uint24 fee) internal pure returns (bool) {
        return fee == POOL_FEE_LOW || fee == POOL_FEE_MEDIUM || fee == POOL_FEE_HIGH;
    }
    
    // Admin functions
    
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
    
    function setQuoter(address newQuoter) external onlyOwner {
        if (newQuoter == address(0)) revert InvalidAddress();
        quoter = IQuoter(newQuoter);
        emit QuoterUpdated(newQuoter);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Receive ETH
    receive() external payable {}
}