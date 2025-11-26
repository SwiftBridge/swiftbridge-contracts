// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenSwap {
    event TokensSwapped(address indexed user, address tokenFrom, address tokenTo, uint256 amountIn, uint256 amountOut);

    function swap(address _tokenFrom, address _tokenTo, uint256 _amountIn, uint256 _amountOutMin) public {
        // Simplified swap logic (OTC style or just wrapper)
        // In reality, this would interact with a pool or match orders
        IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amountIn);
        // Mock swap execution
        IERC20(_tokenTo).transfer(msg.sender, _amountOutMin); 
        emit TokensSwapped(msg.sender, _tokenFrom, _tokenTo, _amountIn, _amountOutMin);
    }
}
