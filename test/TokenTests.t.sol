// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/MockUSDT.sol";
import "../src/tokens/MockUSDY.sol";

/**
 * @title TokenTests
 * @notice Test suite for mock USDT and USDY tokens
 */
contract TokenTests is Test {
    MockUSDT public usdt;
    MockUSDY public usdy;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    function setUp() public {
        usdt = new MockUSDT();
        usdy = new MockUSDY();
    }

    // Mock USDT Tests

    function testMintUSDT() public {
        vm.prank(owner);
        usdt.mint(user1, 1000 ether);

        assertEq(usdt.balanceOf(user1), 1000 ether);
        assertEq(usdt.totalSupply(), 1000 ether);
    }

    function testBurnUSDT() public {
        vm.startPrank(owner);
        usdt.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdt.burn(500 ether);

        assertEq(usdt.balanceOf(user1), 500 ether);
        assertEq(usdt.totalSupply(), 500 ether);
    }

    function testBurnFromUSDT() public {
        vm.startPrank(owner);
        usdt.mint(user1, 1000 ether);
        usdt.mint(user2, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdt.approve(user2, 500 ether);

        vm.prank(user2);
        usdy.burnFrom(user1, 300 ether);

        assertEq(usdt.balanceOf(user1), 700 ether);
    }

    function testUSDTTransfer() public {
        vm.startPrank(owner);
        usdt.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdt.transfer(user2, 500 ether);

        assertEq(usdt.balanceOf(user1), 500 ether);
        assertEq(usdt.balanceOf(user2), 500 ether);
    }

    function testUSDTAllowance() public {
        vm.startPrank(owner);
        usdt.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdt.approve(user2, 500 ether);

        assertEq(usdt.allowance(user1, user2), 500 ether);
    }

    function testUSDTTransferFrom() public {
        vm.startPrank(owner);
        usdt.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdt.approve(user2, 500 ether);

        vm.prank(user2);
        usdt.transferFrom(user1, user2, 300 ether);

        assertEq(usdt.balanceOf(user1), 700 ether);
        assertEq(usdt.balanceOf(user2), 300 ether);
        assertEq(usdt.allowance(user1, user2), 200 ether);
    }

    // Mock USDY Tests

    function testMintUSDY() public {
        vm.prank(owner);
        usdy.mint(user1, 1000 ether);

        assertEq(usdy.balanceOf(user1), 1000 ether);
        assertEq(usdy.totalSupply(), 1000 ether);
    }

    function testBurnUSDY() public {
        vm.startPrank(owner);
        usdy.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdy.burn(500 ether);

        assertEq(usdy.balanceOf(user1), 500 ether);
        assertEq(usdy.totalSupply(), 500 ether);
    }

    function testBurnFromUSDY() public {
        vm.startPrank(owner);
        usdy.mint(user1, 1000 ether);
        usdy.mint(user2, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdy.approve(user2, 500 ether);

        vm.prank(user2);
        usdy.burnFrom(user1, 300 ether);

        assertEq(usdy.balanceOf(user1), 700 ether);
    }

    function testUSDYTransfer() public {
        vm.startPrank(owner);
        usdy.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdy.transfer(user2, 500 ether);

        assertEq(usdy.balanceOf(user1), 500 ether);
        assertEq(usdy.balanceOf(user2), 500 ether);
    }

    function testUSDYAllowance() public {
        vm.startPrank(owner);
        usdy.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdy.approve(user2, 500 ether);

        assertEq(usdy.allowance(user1, user2), 500 ether);
    }

    function testUSDYTransferFrom() public {
        vm.startPrank(owner);
        usdy.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        usdy.approve(user2, 500 ether);

        vm.prank(user2);
        usdy.transferFrom(user1, user2, 300 ether);

        assertEq(usdy.balanceOf(user1), 700 ether);
        assertEq(usdy.balanceOf(user2), 300 ether);
        assertEq(usdy.allowance(user1, user2), 200 ether);
    }

    // USDY Yield Tests

    function testAccrueMonthlyYield() public {
        vm.startPrank(owner);
        usdy.mint(user1, 10000 ether);
        vm.stopPrank();

        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);

        uint256 supplyBefore = usdy.totalSupply();
        vm.prank(owner);
        usdy.accrueMonthlyYield();

        uint256 supplyAfter = usdy.totalSupply();
        uint256 expectedYield = (supplyBefore * 416) / 10000;

        assertEq(supplyAfter, supplyBefore + expectedYield);
    }

    function testGetCurrentYield() public {
        vm.startPrank(owner);
        usdy.mint(user1, 10000 ether);
        vm.stopPrank();

        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);

        uint256 yield = usdy.getCurrentYield();
        uint256 expectedYield = (10000 ether * 416) / 10000;

        assertEq(yield, expectedYield);
    }

    function testMonthlyYieldRate() public {
        uint256 rate = usdy.getMonthlyYieldRate();
        assertEq(rate, 416); // 4.16%
    }

    function testCannotAccrueYieldBefore30Days() public {
        vm.startPrank(owner);
        usdy.mint(user1, 10000 ether);
        vm.stopPrank();

        // Try to accrue before 30 days
        vm.expectRevert("Can only accrue yield monthly");
        vm.prank(owner);
        usdy.accrueMonthlyYield();
    }

    function testGetCurrentYieldBefore30Days() public {
        vm.startPrank(owner);
        usdy.mint(user1, 10000 ether);
        vm.stopPrank();

        // Check yield before 30 days
        uint256 yield = usdy.getCurrentYield();
        assertEq(yield, 0);
    }
}
