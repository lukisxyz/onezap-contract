// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/registry/ContentCreatorRegistry.sol";

/**
 * @title RegistryTests
 * @notice Test suite for Content Creator Registry contract
 */
contract RegistryTests is Test {
    ContentCreatorRegistry public registry;

    address public owner = address(1);
    address public creator1 = address(2);
    address public creator2 = address(3);
    address public user1 = address(4);

    function setUp() public {}

    function testRegisterCreator() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        (string memory username, address wallet, uint256 totalEarnings, bool exists) = registry
            .getCreator(creator1);

        assertTrue(exists);
        assertEq(username, "creator1");
        assertEq(wallet, creator1);
        assertEq(totalEarnings, 0);
    }

    function testRegisterMultipleCreators() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.prank(creator2);
        registry.registerCreator("creator2", creator2);

        assertTrue(registry.isCreator(creator1));
        assertTrue(registry.isCreator(creator2));

        address[] memory allCreators = registry.getAllCreators();
        assertEq(allCreators.length, 2);
        assertEq(allCreators[0], creator1);
        assertEq(allCreators[1], creator2);
    }

    function testUpdateWallet() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        address newWallet = address(5);
        vm.prank(creator1);
        registry.updateWallet(newWallet);

        (, address wallet, , ) = registry.getCreator(creator1);
        assertEq(wallet, newWallet);
    }

    function testUpdateUsername() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.prank(creator1);
        registry.updateUsername("new_creator1");

        (string memory username, , , ) = registry.getCreator(creator1);
        assertEq(username, "new_creator1");
    }

    function testUpdateCreator() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.prank(creator1);
        registry.updateCreator("updated_creator1", address(5));

        (string memory username, address wallet, , ) = registry.getCreator(creator1);
        assertEq(username, "updated_creator1");
        assertEq(wallet, address(5));
    }

    function testAddEarnings() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.prank(owner);
        registry.addEarnings(creator1, 100 ether);

        (, , uint256 totalEarnings, ) = registry.getCreator(creator1);
        assertEq(totalEarnings, 100 ether);

        vm.prank(owner);
        registry.addEarnings(creator1, 50 ether);

        (, , totalEarnings, ) = registry.getCreator(creator1);
        assertEq(totalEarnings, 150 ether);
    }

    function testGetCreatorCount() public {
        assertEq(registry.getCreatorCount(), 0);

        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);
        assertEq(registry.getCreatorCount(), 1);

        vm.prank(creator2);
        registry.registerCreator("creator2", creator2);
        assertEq(registry.getCreatorCount(), 2);
    }

    function testIsCreator() public {
        assertFalse(registry.isCreator(creator1));

        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        assertTrue(registry.isCreator(creator1));
        assertFalse(registry.isCreator(user1));
    }

    // Revert Tests

    function testRevertRegisterAlreadyRegistered() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.expectRevert("Creator already registered");
        vm.prank(creator1);
        registry.registerCreator("creator2", creator1);
    }

    function testRevertRegisterEmptyUsername() public {
        vm.expectRevert("Username cannot be empty");
        vm.prank(creator1);
        registry.registerCreator("", creator1);
    }

    function testRevertRegisterInvalidWallet() public {
        vm.expectRevert("Invalid wallet address");
        vm.prank(creator1);
        registry.registerCreator("creator1", address(0));
    }

    function testRevertUpdateWalletInvalidAddress() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.expectRevert("Invalid wallet address");
        vm.prank(creator1);
        registry.updateWallet(address(0));
    }

    function testRevertUpdateUsernameEmpty() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.expectRevert("Username cannot be empty");
        vm.prank(creator1);
        registry.updateUsername("");
    }

    function testRevertUpdateUnregisteredCreator() public {
        vm.expectRevert("Creator not registered");
        vm.prank(creator1);
        registry.updateWallet(address(5));
    }

    function testRevertAddEarningsUnregisteredCreator() public {
        vm.expectRevert("Creator not registered");
        vm.prank(owner);
        registry.addEarnings(creator1, 100 ether);
    }

    function testRevertAddEarningsZeroAmount() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.expectRevert("Amount must be greater than 0");
        vm.prank(owner);
        registry.addEarnings(creator1, 0);
    }

    function testRevertAddEarningsFromNonOwner() public {
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.expectRevert();
        vm.prank(user1);
        registry.addEarnings(creator1, 100 ether);
    }
}
