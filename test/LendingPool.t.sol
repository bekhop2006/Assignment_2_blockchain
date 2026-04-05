// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {TokenA, TokenB} from "../src/Tokens.sol";

contract LendingPoolTest is Test {
    LendingPool public pool;
    TokenA public collateral; // TokenA as collateral
    TokenB public borrowToken; // TokenB as borrow

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        collateral = new TokenA();
        borrowToken = new TokenB();
        pool = new LendingPool(address(collateral), address(borrowToken));

        // Fund users
        collateral.transfer(alice, 10000);
        borrowToken.transfer(alice, 10000);
        collateral.transfer(bob, 10000);
        borrowToken.transfer(bob, 10000);

        // Pool has borrow tokens
        borrowToken.transfer(address(pool), 10000);
    }

    function testDeposit() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        vm.stopPrank();

        assertEq(pool.getDeposited(alice), 1000);
    }

    function testBorrowWithinLTV() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.borrow(750); // 75% of 1000
        vm.stopPrank();

        assertEq(pool.getBorrowed(alice), 750);
    }

    function testBorrowExceedLTV() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        vm.expectRevert("Exceeds LTV");
        pool.borrow(751);
        vm.stopPrank();
    }

    function testRepay() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.borrow(500);
        borrowToken.approve(address(pool), 250);
        pool.repay(250);
        vm.stopPrank();

        assertEq(pool.getBorrowed(alice), 250);
    }

    function testWithdraw() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.withdraw(500);
        vm.stopPrank();

        assertEq(pool.getDeposited(alice), 500);
    }

    function testWithdrawWithDebt() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.borrow(500);
        vm.expectRevert("Would violate LTV");
        pool.withdraw(400); // Would make LTV >75%
        vm.stopPrank();
    }

    function testLiquidate() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.borrow(750);
        vm.stopPrank();

        // Price drop to 0.5
        pool.setCollateralPrice(0.5e18);

        vm.startPrank(bob);
        borrowToken.approve(address(pool), 750);
        pool.liquidate(alice);
        vm.stopPrank();

        assertEq(pool.getDeposited(alice), 0);
        assertEq(pool.getBorrowed(alice), 0);
    }

    function testInterestAccrual() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.borrow(500);
        vm.stopPrank();

        borrowToken.transfer(alice, 100); // Extra for interest

        vm.warp(block.timestamp + 365 * 24 * 3600); // 1 year

        uint256 currentBorrow = pool.getCurrentBorrow(alice);
        assertGt(currentBorrow, 500); // Interest accrued
    }

    function testBorrowZeroCollateral() public {
        vm.startPrank(alice);
        vm.expectRevert("No collateral");
        pool.borrow(100);
        vm.stopPrank();
    }

    function testRepayMoreThanBorrowed() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.borrow(500);
        borrowToken.approve(address(pool), 600);
        vm.expectRevert("Repay too much");
        pool.repay(600);
        vm.stopPrank();
    }

    function testHealthFactor() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.borrow(500);
        vm.stopPrank();

        uint256 health = pool.getHealthFactor(alice);
        assertGt(health, 1e18); // >1
    }

    function testLiquidateHealthy() public {
        vm.startPrank(alice);
        collateral.approve(address(pool), 1000);
        pool.deposit(1000);
        pool.borrow(500);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Not undercollateralized");
        pool.liquidate(alice);
        vm.stopPrank();
    }
}