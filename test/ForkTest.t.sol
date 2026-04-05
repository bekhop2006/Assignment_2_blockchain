// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract ForkTest is Test {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function setUp() public {
        vm.createSelectFork("mainnet");
    }

    function testReadUSDCTotalSupply() public {
        uint256 totalSupply = IERC20(USDC).totalSupply();
        assertGt(totalSupply, 0);
        console.log("USDC Total Supply:", totalSupply);
    }

    function testSimulateUniswapSwap() public {
        // Assume the test contract has some USDC, but since it's fork, need to deal
        // For simulation, perhaps impersonate an account with USDC
        address whale = 0xF977814e90dA44bFA03b6295A0616a897441aceC; // Some whale
        vm.startPrank(whale);
        uint256 balance = IERC20(USDC).balanceOf(whale);
        require(balance > 0, "No balance");
        // Approve router
        IERC20(USDC).approve(UNISWAP_ROUTER, balance);
        // Swap USDC to WETH
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = WETH;
        IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForTokens(
            1000000, // 1 USDC
            0, // min out
            path,
            whale,
            block.timestamp + 100
        );
        vm.stopPrank();
        // Check if swap happened
        assertGt(IERC20(WETH).balanceOf(whale), 0);
    }
}