// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../src/AMM.sol";
import {TokenA, TokenB} from "../src/Tokens.sol";
import {LPToken} from "../src/LPToken.sol";

contract AMMTest is Test {
    AMM public amm;
    TokenA public tokenA;
    TokenB public tokenB;
    LPToken public lpToken;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        amm = new AMM(address(tokenA), address(tokenB));
        lpToken = amm.lpToken();

        // Transfer some tokens to alice and bob
        tokenA.transfer(alice, 10000);
        tokenB.transfer(alice, 10000);
        tokenA.transfer(bob, 10000);
        tokenB.transfer(bob, 10000);
    }

    // Test add liquidity first provider
    function testAddLiquidityFirst() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        assertEq(amm.reserveA(), 1000);
        assertEq(amm.reserveB(), 1000);
        assertEq(lpToken.balanceOf(alice), 1000); // sqrt(1000*1000)=1000
    }

    // Test add liquidity subsequent
    function testAddLiquiditySubsequent() public {
        // First add
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        // Second add
        vm.startPrank(bob);
        tokenA.approve(address(amm), 500);
        tokenB.approve(address(amm), 500);
        amm.addLiquidity(500, 500);
        vm.stopPrank();

        assertEq(amm.reserveA(), 1500);
        assertEq(amm.reserveB(), 1500);
        assertEq(lpToken.balanceOf(bob), 500);
        assertEq(lpToken.totalSupply(), 1500);
    }

    // Test remove liquidity
    function testRemoveLiquidity() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        uint256 initialA = tokenA.balanceOf(alice);
        uint256 initialB = tokenB.balanceOf(alice);

        vm.startPrank(alice);
        amm.removeLiquidity(500);
        vm.stopPrank();

        assertEq(amm.reserveA(), 500);
        assertEq(amm.reserveB(), 500);
        assertEq(lpToken.balanceOf(alice), 500);
        assertEq(tokenA.balanceOf(alice), initialA + 500);
        assertEq(tokenB.balanceOf(alice), initialB + 500);
    }

    // Test swap A to B
    function testSwapAToB() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        uint256 amountOut = amm.getAmountOut(100, address(tokenA));
        vm.startPrank(bob);
        tokenA.approve(address(amm), 100);
        amm.swap(100, address(tokenA), address(tokenB), amountOut);
        vm.stopPrank();

        assertEq(amm.reserveA(), 1100);
        assertEq(amm.reserveB(), 1000 - amountOut);
    }

    // Test swap B to A
    function testSwapBToA() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        uint256 amountOut = amm.getAmountOut(100, address(tokenB));
        vm.startPrank(bob);
        tokenB.approve(address(amm), 100);
        amm.swap(100, address(tokenB), address(tokenA), amountOut);
        vm.stopPrank();

        assertEq(amm.reserveB(), 1100);
        assertEq(amm.reserveA(), 1000 - amountOut);
    }

    // Test k increases after swap
    function testKIncreasesAfterSwap() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        uint256 kBefore = amm.reserveA() * amm.reserveB();

        vm.startPrank(bob);
        tokenA.approve(address(amm), 100);
        amm.swap(100, address(tokenA), address(tokenB), 0);
        vm.stopPrank();

        uint256 kAfter = amm.reserveA() * amm.reserveB();
        assertGe(kAfter, kBefore);
    }

    // Test slippage protection
    function testSlippageProtection() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(amm), 100);
        vm.expectRevert("Slippage protection");
        amm.swap(100, address(tokenA), address(tokenB), 1000); // too high min
        vm.stopPrank();
    }

    // Edge cases
    function testAddLiquidityZero() public {
        vm.startPrank(alice);
        vm.expectRevert("Amounts must be positive");
        amm.addLiquidity(0, 100);
        vm.stopPrank();
    }

    function testSwapZero() public {
        vm.startPrank(alice);
        vm.expectRevert("Amount in must be positive");
        amm.swap(0, address(tokenA), address(tokenB), 0);
        vm.stopPrank();
    }

    function testRemoveLiquidityInsufficient() public {
        vm.startPrank(alice);
        vm.expectRevert("Insufficient LP tokens");
        amm.removeLiquidity(100);
        vm.stopPrank();
    }

    function testSwapInvalidToken() public {
        vm.startPrank(alice);
        vm.expectRevert("Invalid token in");
        amm.swap(100, address(0), address(tokenB), 0);
        vm.stopPrank();
    }

    // Fuzz test swap
    function testFuzzSwap(uint256 amountIn) public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        amountIn = bound(amountIn, 1, 100);
        uint256 amountOut = amm.getAmountOut(amountIn, address(tokenA));
        vm.startPrank(bob);
        tokenA.approve(address(amm), amountIn);
        amm.swap(amountIn, address(tokenA), address(tokenB), amountOut);
        vm.stopPrank();

        assertGe(amm.reserveA(), 1000);
        assertLe(amm.reserveB(), 1000);
    }

    // More tests to reach 15
    function testAddLiquidityImbalanced() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(amm), 200);
        tokenB.approve(address(amm), 100);
        amm.addLiquidity(200, 100); // Should adjust to ratio
        vm.stopPrank();

        // liquidity limited by B: 100
        assertEq(lpToken.balanceOf(bob), 100);
    }

    function testRemoveAllLiquidity() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        amm.removeLiquidity(1000);
        vm.stopPrank();

        assertEq(amm.reserveA(), 0);
        assertEq(amm.reserveB(), 0);
        assertEq(lpToken.balanceOf(alice), 0);
    }

    function testSwapLargeAmount() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000);
        tokenB.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(amm), 500);
        uint256 amountOut = amm.getAmountOut(500, address(tokenA));
        amm.swap(500, address(tokenA), address(tokenB), amountOut);
        vm.stopPrank();

        // High price impact
        assertLt(amountOut, 500); // Less than 1:1 due to fee and impact
    }
}