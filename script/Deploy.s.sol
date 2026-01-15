// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/MockUSDT.sol";
import "../src/tokens/MockUSDY.sol";
import "../src/registry/ContentCreatorRegistry.sol";
import "../src/subscription/Subscription.sol";

/**
 * @title Deploy
 * @notice Deployment script for all contracts
 */
contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Mock USDT Token
        console.log("Deploying MockUSDT token...");
        MockUSDT usdt = new MockUSDT();
        console.log("MockUSDT deployed at:", address(usdt));

        // Deploy Mock USDY Token
        console.log("Deploying MockUSDY token...");
        MockUSDY usdy = new MockUSDY();
        console.log("MockUSDY deployed at:", address(usdy));

        // Deploy Content Creator Registry
        console.log("Deploying ContentCreatorRegistry...");
        ContentCreatorRegistry registry = new ContentCreatorRegistry();
        console.log("ContentCreatorRegistry deployed at:", address(registry));

        // Deploy Subscription Contract
        console.log("Deploying Subscription contract...");
        Subscription subscription = new Subscription(
            address(usdt),
            address(usdy),
            address(registry)
        );
        console.log("Subscription deployed at:", address(subscription));

        vm.stopBroadcast();

        // Transfer ownership of tokens to subscription contract for swaps
        // We need to impersonate address(1) since that's who owns the tokens
        console.log("Transferring token ownerships...");
        vm.broadcast(address(1));
        usdt.transferOwnership(address(subscription));

        vm.broadcast(address(1));
        usdy.transferOwnership(address(subscription));

        console.log("\n=== Deployment Summary ===");
        console.log("MockUSDT:", address(usdt));
        console.log("MockUSDY:", address(usdy));
        console.log("ContentCreatorRegistry:", address(registry));
        console.log("Subscription:", address(subscription));

        // Log contract addresses for easy reference
        console.log("\n=== Save these addresses ===");
        console.log("USDT_TOKEN=<address>", address(usdt));
        console.log("USDY_TOKEN=<address>", address(usdy));
        console.log("REGISTRY=<address>", address(registry));
        console.log("SUBSCRIPTION=<address>", address(subscription));
    }
}

/**
 * @title DeployScript
 * @notice Alternative deployment script for local testing
 */
contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts
        MockUSDT usdt = new MockUSDT();
        MockUSDY usdy = new MockUSDY();
        ContentCreatorRegistry registry = new ContentCreatorRegistry();
        Subscription subscription = new Subscription(
            address(usdt),
            address(usdy),
            address(registry)
        );

        // Transfer ownership
        usdt.transferOwnership(address(subscription));
        usdy.transferOwnership(address(subscription));

        vm.stopBroadcast();

        // Log addresses
        console.log("MockUSDT:", address(usdt));
        console.log("MockUSDY:", address(usdy));
        console.log("ContentCreatorRegistry:", address(registry));
        console.log("Subscription:", address(subscription));
    }
}
