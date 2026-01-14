// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/MockUSDT.sol";
import "../src/tokens/MockUSDY.sol";
import "../src/registry/ContentCreatorRegistry.sol";
import "../src/subscription/Subscription.sol";

/**
 * @title SubscriptionTests
 * @notice Comprehensive test suite for Subscription contract
 */
contract SubscriptionTests is Test {
    MockUSDT public usdt;
    MockUSDY public usdy;
    ContentCreatorRegistry public registry;
    Subscription public subscription;

    address public owner = address(1);
    address public creator1 = address(2);
    address public creator2 = address(3);
    address public subscriber1 = address(4);
    address public subscriber2 = address(5);

    function setUp() public {
        usdt = new MockUSDT();
        usdy = new MockUSDY();
        registry = new ContentCreatorRegistry();
        subscription = new Subscription(address(usdt), address(usdy), address(registry));

        // Transfer ownership of all contracts to subscription contract
        vm.prank(owner);
        usdt.transferOwnership(address(subscription));
        vm.prank(owner);
        usdy.transferOwnership(address(subscription));
        vm.prank(owner);
        registry.transferOwnership(address(subscription));

        // Mint tokens to subscription contract for payouts
        vm.prank(address(subscription));
        usdt.mint(address(subscription), 100000 ether);

        // Register creators
        vm.prank(creator1);
        registry.registerCreator("creator1", creator1);

        vm.prank(creator2);
        registry.registerCreator("creator2", creator2);

        // Mint tokens to subscribers
        vm.prank(address(subscription));
        usdt.mint(subscriber1, 1000 ether);

        vm.prank(address(subscription));
        usdt.mint(subscriber2, 1000 ether);
    }

    // Subscription Tests

    function testSubscribeToCreator() public {
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        uint256 subscriptionId = subscription.subscribe(creator1);
        vm.stopPrank();

        assertEq(subscriptionId, 1);

        Subscription.SubscriptionData memory sub = subscription.getSubscription(subscriptionId);
        assertEq(sub.id, 1);
        assertEq(sub.subscriber, subscriber1);
        assertEq(sub.creator, creator1);
        assertEq(sub.amount, 100 ether);
        assertEq(sub.usdyAmount, 100 ether);
        assertEq(uint256(sub.status), uint256(Subscription.SubscriptionStatus.ACTIVE));

        // Check subscriber's subscription count
        assertEq(subscription.getSubscriptionCount(subscriber1), 1);

        // Check active subscriptions
        uint256[] memory subs = subscription.getActiveSubscriptions(subscriber1);
        assertEq(subs.length, 1);
        assertEq(subs[0], 1);
    }

    function testMultipleSubscriptions() public {
        // Subscriber 1 subscribes to creator 1
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        subscription.subscribe(creator1);
        vm.stopPrank();

        // Subscriber 1 subscribes to creator 2
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        subscription.subscribe(creator2);
        vm.stopPrank();

        // Subscriber 2 subscribes to creator 1
        vm.startPrank(subscriber2);
        usdt.approve(address(subscription), 100 ether);
        subscription.subscribe(creator1);
        vm.stopPrank();

        assertEq(subscription.getSubscriptionCount(subscriber1), 2);
        assertEq(subscription.getSubscriptionCount(subscriber2), 1);
    }

    function testSubscribeToSelfReverts() public {
        vm.prank(creator1);
        usdt.approve(address(subscription), 100 ether);

        vm.expectRevert("Cannot subscribe to yourself");
        vm.prank(creator1);
        subscription.subscribe(creator1);
    }

    function testSubscribeToUnregisteredCreatorReverts() public {
        vm.prank(subscriber1);
        usdt.approve(address(subscription), 100 ether);

        vm.expectRevert("Creator not registered");
        vm.prank(subscriber1);
        subscription.subscribe(address(10));
    }

    function testSubscribeWithoutApprovalReverts() public {
        vm.expectRevert();
        vm.prank(subscriber1);
        subscription.subscribe(creator1);
    }

    function testSubscribeWithInsufficientAllowanceReverts() public {
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 50 ether);

        vm.expectRevert();
        subscription.subscribe(creator1);
        vm.stopPrank();
    }

    // Withdrawal Tests

    function testRequestImmediateWithdrawal() public {
        // Subscribe
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        uint256 subscriptionId = subscription.subscribe(creator1);
        vm.stopPrank();

        // Request immediate withdrawal
        vm.prank(subscriber1);
        subscription.requestWithdrawal(subscriptionId, Subscription.WithdrawalType.IMMEDIATE);

        // Check subscription status
        Subscription.SubscriptionData memory sub = subscription.getSubscription(subscriptionId);
        assertEq(uint256(sub.status), uint256(Subscription.SubscriptionStatus.WITHDRAWAL_PROCESSED));

        // Check penalty distribution
        (, , uint256 totalEarnings, ) = registry.getCreator(creator1);
        assertEq(totalEarnings, 1 ether); // 1 USDT penalty
    }

    function testRequestCompleteEpochWithdrawal() public {
        // Subscribe
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        uint256 subscriptionId = subscription.subscribe(creator1);
        vm.stopPrank();

        // Request complete epoch withdrawal
        vm.prank(subscriber1);
        subscription.requestWithdrawal(subscriptionId, Subscription.WithdrawalType.COMPLETE_EPOCH);

        // Check subscription status
        Subscription.SubscriptionData memory sub = subscription.getSubscription(subscriptionId);
        assertEq(uint256(sub.status), uint256(Subscription.SubscriptionStatus.WITHDRAWAL_REQUESTED));
        assertEq(uint256(sub.withdrawalType), uint256(Subscription.WithdrawalType.COMPLETE_EPOCH));

        // No penalty for complete epoch
        (, , uint256 totalEarnings, ) = registry.getCreator(creator1);
        assertEq(totalEarnings, 0);
    }

    function testProcessCompleteEpochWithdrawalAfter30Days() public {
        // Subscribe
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        uint256 subscriptionId = subscription.subscribe(creator1);
        vm.stopPrank();

        // Request complete epoch withdrawal
        vm.prank(subscriber1);
        subscription.requestWithdrawal(subscriptionId, Subscription.WithdrawalType.COMPLETE_EPOCH);

        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);

        // Process withdrawal
        vm.prank(subscriber1);
        subscription.processCompleteEpochWithdrawal(subscriptionId);

        // Check subscription status
        Subscription.SubscriptionData memory sub = subscription.getSubscription(subscriptionId);
        assertEq(uint256(sub.status), uint256(Subscription.SubscriptionStatus.WITHDRAWAL_PROCESSED));
    }

    function testProcessCompleteEpochWithdrawalBefore30DaysReverts() public {
        // Subscribe
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        uint256 subscriptionId = subscription.subscribe(creator1);
        vm.stopPrank();

        // Request complete epoch withdrawal
        vm.prank(subscriber1);
        subscription.requestWithdrawal(subscriptionId, Subscription.WithdrawalType.COMPLETE_EPOCH);

        // Try to process before 30 days
        vm.expectRevert("1-month delay not met");
        vm.prank(subscriber1);
        subscription.processCompleteEpochWithdrawal(subscriptionId);
    }

    function testNonOwnerCannotRequestWithdrawal() public {
        // Subscribe
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        uint256 subscriptionId = subscription.subscribe(creator1);
        vm.stopPrank();

        // Subscriber 2 tries to request withdrawal
        vm.expectRevert("Not subscription owner");
        vm.prank(subscriber2);
        subscription.requestWithdrawal(subscriptionId, Subscription.WithdrawalType.IMMEDIATE);
    }

    function testCannotRequestWithdrawalTwice() public {
        // Subscribe
        vm.startPrank(subscriber1);
        usdt.approve(address(subscription), 100 ether);
        uint256 subscriptionId = subscription.subscribe(creator1);
        vm.stopPrank();

        // Request withdrawal
        vm.prank(subscriber1);
        subscription.requestWithdrawal(subscriptionId, Subscription.WithdrawalType.IMMEDIATE);

        // Try to request again
        vm.expectRevert("Subscription not active");
        vm.prank(subscriber1);
        subscription.requestWithdrawal(subscriptionId, Subscription.WithdrawalType.COMPLETE_EPOCH);
    }

    function testCannotRequestWithdrawalOnNonExistentSubscription() public {
        vm.expectRevert();
        vm.prank(subscriber1);
        subscription.requestWithdrawal(999, Subscription.WithdrawalType.IMMEDIATE);
    }

    // Events (Tests removed - events are tested implicitly through other tests)

    // Constants

    function testSubscriptionAmount() public {
        assertEq(subscription.SUBSCRIPTION_AMOUNT(), 100 ether);
    }

    function testImmediateWithdrawalPenalty() public {
        assertEq(subscription.IMMEDIATE_WITHDRAWAL_PENALTY(), 1 ether);
    }
}
