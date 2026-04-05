// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LPToken.sol";

contract AMM {
    using SafeERC20 for IERC20;

    IERC20 public tokenA;
    IERC20 public tokenB;
    LPToken public lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public constant FEE_NUMERATOR = 997;
    uint256 public constant FEE_DENOMINATOR = 1000;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new LPToken("LP Token", "LP");
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be positive");

        uint256 liquidity;
        if (reserveA == 0 && reserveB == 0) {
            // First provider
            liquidity = sqrt(amountA * amountB);
        } else {
            // Subsequent
            uint256 liquidityA = (amountA * lpToken.totalSupply()) / reserveA;
            uint256 liquidityB = (amountB * lpToken.totalSupply()) / reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
            amountA = (liquidity * reserveA) / lpToken.totalSupply();
            amountB = (liquidity * reserveB) / lpToken.totalSupply();
        }

        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        lpToken.mint(msg.sender, liquidity);

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external {
        require(liquidity > 0, "Liquidity must be positive");
        require(lpToken.balanceOf(msg.sender) >= liquidity, "Insufficient LP tokens");

        uint256 amountA = (liquidity * reserveA) / lpToken.totalSupply();
        uint256 amountB = (liquidity * reserveB) / lpToken.totalSupply();

        lpToken.burn(msg.sender, liquidity);

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    function getAmountOut(uint256 amountIn, address tokenIn) public view returns (uint256) {
        require(amountIn > 0, "Amount in must be positive");
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");

        uint256 reserveIn = tokenIn == address(tokenA) ? reserveA : reserveB;
        uint256 reserveOut = tokenIn == address(tokenA) ? reserveB : reserveA;

        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        return numerator / denominator;
    }

    function swap(uint256 amountIn, address tokenIn, address tokenOut, uint256 minAmountOut) external {
        require(amountIn > 0, "Amount in must be positive");
        require(tokenIn != tokenOut, "Tokens must be different");
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token in");
        require(tokenOut == address(tokenA) || tokenOut == address(tokenB), "Invalid token out");

        uint256 amountOut = getAmountOut(amountIn, tokenIn);

        require(amountOut >= minAmountOut, "Slippage protection");

        if (tokenIn == address(tokenA)) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}