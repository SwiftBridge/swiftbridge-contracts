// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISwapRouter
 * @notice Interface for SwapRouter contract
 */
interface ISwapRouter {
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
    
    // Functions
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint24 poolFee
    ) external returns (uint256 amountOut);
    
    function swapExactETHForTokens(
        address tokenOut,
        uint256 amountOutMinimum,
        uint24 poolFee
    ) external payable returns (uint256 amountOut);
    
    function swapExactTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint24 poolFee
    ) external returns (uint256 amountOut);
    
    function getQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 poolFee
    ) external returns (uint256 amountOut);
    
    function getBestPoolFee(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint24 bestFee, uint256 bestAmountOut);
    
    // Admin functions
    function setFee(uint256 newFeeBps) external;
    function setFeeCollector(address newFeeCollector) external;
    function setQuoter(address newQuoter) external;
    
    // State variables
    function uniswapRouter() external view returns (address);
    function quoter() external view returns (address);
    function WETH() external view returns (address);
    function feeCollector() external view returns (address);
    function feeBps() external view returns (uint256);
    function POOL_FEE_LOW() external view returns (uint24);
    function POOL_FEE_MEDIUM() external view returns (uint24);
    function POOL_FEE_HIGH() external view returns (uint24);
}