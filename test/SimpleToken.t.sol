// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

contract SimpleTokenTest is Test {
    SimpleToken public token;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        token = new SimpleToken("SimpleToken", "STK");
        token.mint(alice, 1000);
        token.mint(bob, 500);
    }

    // Unit tests
    function testMint() public {
        token.mint(address(0x3), 100);
        assertEq(token.balanceOf(address(0x3)), 100);
        assertEq(token.totalSupply(), 1600);
    }

    function testTransfer() public {
        vm.prank(alice);
        token.transfer(bob, 50);
        assertEq(token.balanceOf(alice), 950);
        assertEq(token.balanceOf(bob), 550);
    }

    function testApprove() public {
        vm.prank(alice);
        token.approve(bob, 50);
        assertEq(token.allowance(alice, bob), 50);
    }

    function testTransferFrom() public {
        vm.prank(alice);
        token.approve(bob, 50);
        vm.prank(bob);
        token.transferFrom(alice, bob, 30);
        assertEq(token.balanceOf(alice), 970);
        assertEq(token.balanceOf(bob), 530);
        assertEq(token.allowance(alice, bob), 20);
    }

    function testTransferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 2000);
    }

    function testTransferFromInsufficientAllowance() public {
        vm.prank(alice);
        token.approve(bob, 20);
        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, 50);
    }

    function testTransferFromInsufficientBalance() public {
        vm.prank(alice);
        token.approve(bob, 2000);
        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, 1500);
    }

    function testMintToZeroAddress() public {
        vm.expectRevert();
        token.mint(address(0), 100);
    }

    function testTransferToZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(address(0), 50);
    }

    function testApproveToZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert();
        token.approve(address(0), 50);
    }

    // Fuzz tests
    function testFuzzTransfer(uint256 transferAmount) public {
        transferAmount = bound(transferAmount, 0, token.balanceOf(alice));
        uint256 initialAlice = token.balanceOf(alice);
        uint256 initialBob = token.balanceOf(bob);
        vm.prank(alice);
        token.transfer(bob, transferAmount);
        assertEq(token.balanceOf(alice), initialAlice - transferAmount);
        assertEq(token.balanceOf(bob), initialBob + transferAmount);
    }

    // Invariant tests
    function invariantTotalSupplyConsistent() public view {
        // No address can hold more than the total supply
        assertLe(token.balanceOf(alice), token.totalSupply());
        assertLe(token.balanceOf(bob), token.totalSupply());
    }

    function invariantTotalSupplyMinimum() public view {
        // Total supply should never drop below sum of known balances
        // (other addresses may hold tokens too, so supply >= alice + bob)
        assertGe(token.totalSupply(), token.balanceOf(alice) + token.balanceOf(bob));
    }
}