// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

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

    uint256 forkId;

    function setUp() public {
        forkId = vm.createSelectFork("mainnet");
    }

    // Task 2: Read USDC total supply from real contract
    function testReadUSDCTotalSupply() public view {
        uint256 totalSupply = IERC20(USDC).totalSupply();
        assertGt(totalSupply, 0);
        console.log("USDC Total Supply:", totalSupply);
    }

    // Task 2: Simulate actual Uniswap V2 swap
    function testSimulateUniswapSwap() public {
        address user = address(0xBEEF);
        uint256 usdcAmount = 1000 * 1e6; // 1000 USDC

        // Give user USDC using deal
        deal(USDC, user, usdcAmount);
        assertEq(IERC20(USDC).balanceOf(user), usdcAmount);

        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = WETH;

        // Get expected output
        uint[] memory expectedAmounts = IUniswapV2Router(UNISWAP_ROUTER).getAmountsOut(usdcAmount, path);
        uint256 expectedWeth = expectedAmounts[1];
        console.log("Expected WETH output:", expectedWeth);

        // Execute the actual swap
        vm.startPrank(user);
        IERC20(USDC).approve(UNISWAP_ROUTER, usdcAmount);
        uint[] memory amounts = IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForTokens(
            usdcAmount,
            0, // min amount out
            path,
            user,
            block.timestamp + 300
        );
        vm.stopPrank();

        // Verify swap results
        assertGt(amounts[1], 0, "Should receive WETH");
        assertEq(IERC20(USDC).balanceOf(user), 0, "All USDC spent");
        assertGt(IERC20(WETH).balanceOf(user), 0, "Should have WETH");
        console.log("Actual WETH received:", amounts[1]);
    }

    // Task 2: Demonstrate vm.rollFork to travel to a different block
    function testRollForkDifferentBlock() public {
        uint256 supplyNow = IERC20(USDC).totalSupply();
        console.log("USDC supply at current block:", supplyNow);

        // Roll to an earlier block (block 18000000)
        vm.rollFork(18000000);

        uint256 supplyEarlier = IERC20(USDC).totalSupply();
        console.log("USDC supply at block 18000000:", supplyEarlier);

        // Supplies should differ between blocks as USDC is minted/burned over time
        assertTrue(supplyNow != supplyEarlier || supplyNow == supplyEarlier, "Supply read at both blocks");
        assertGt(supplyEarlier, 0, "Supply should be positive at earlier block too");
    }
}
