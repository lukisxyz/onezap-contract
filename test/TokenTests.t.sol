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
        usdt.burnFrom(user1, 300 ether);

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
        usdy.accrueYield();

        uint256 supplyAfter = usdy.totalSupply();
        // 5% APY for 30 days: 10000 * 500 * 30 / (10000 * 365) = 4.10958904109589
        uint256 expectedYield = (supplyBefore * 500 * 30) / (10000 * 365);

        assertEq(supplyAfter, supplyBefore + expectedYield);
    }

    function testGetCurrentYield() public {
        vm.startPrank(owner);
        usdy.mint(user1, 10000 ether);
        vm.stopPrank();

        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);

        uint256 yield = usdy.getAccruedYield(user1);
        // 5% APY for 30 days: should be approximately 410.96 ether
        // Using a calculation that works with Solidity's type system
        uint256 principal = 10000 ether;
        uint256 apy = 500; // 5%
        uint256 numDays = 30;
        uint256 expectedYield = (principal * apy * numDays) / (10000 * 365);

        assertEq(yield, expectedYield);
    }

    function testAPY() external view {
        uint256 rate = usdy.getApy();
        assertEq(rate, 500); // 5%
    }

    function testGetCurrentYieldBefore30Days() public {
        vm.startPrank(owner);
        usdy.mint(user1, 10000 ether);
        vm.stopPrank();

        // Fast forward 15 days (less than 30)
        vm.warp(block.timestamp + 15 days);

        // Check yield - should have some yield even before 30 days
        uint256 yield = usdy.getAccruedYield(user1);
        // 5% APY for 15 days: should be approximately 205.48 ether
        uint256 principal = 10000 ether;
        uint256 apy = 500; // 5%
        uint256 numDays = 15;
        uint256 expectedYield = (principal * apy * numDays) / (10000 * 365);
        assertEq(yield, expectedYield);
    }
}
