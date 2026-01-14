#!/bin/bash

# Contract Addresses
USDT_TOKEN="0x5FbDB2315678afecb367f032d93F642f64180aa3"
USDY_TOKEN="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
REGISTRY="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
SUBSCRIPTION="0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"

RPC_URL="http://127.0.0.1:8547"

# Private Keys
DEPLOYER_PK="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
CREATOR_PK="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
SUBSCRIBER_PK="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Addresses
DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
CREATOR="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
SUBSCRIBER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

echo "=== Subscription Platform Simulation ==="
echo ""
echo "Contract Addresses:"
echo "  USDT Token:    $USDT_TOKEN"
echo "  USDY Token:   $USDY_TOKEN"
echo "  Registry:      $REGISTRY"
echo "  Subscription:  $SUBSCRIPTION"
echo ""
echo "Participants:"
echo "  Deployer:      $DEPLOYER"
echo "  Creator:       $CREATOR"
echo "  Subscriber:     $SUBSCRIBER"
echo ""
echo "=== Step 1: Check Initial Balances ==="
echo "Subscriber USDT Balance:"
cast call $USDT_TOKEN "balanceOf(address)" $SUBSCRIBER --rpc-url $RPC_URL | xargs -I {} cast parse-units 18 {} | head -1
echo ""
echo "Creator USDT Balance:"
cast call $USDT_TOKEN "balanceOf(address)" $CREATOR --rpc-url $RPC_URL | xargs -I {} cast parse-units 18 {} | head -1
echo ""

echo "=== Step 2: Mint Tokens ==="
echo "Minting 10,000 USDT to Subscriber..."
cast send $USDT_TOKEN "mint(address,uint256)" $SUBSCRIBER 10000000000000000000000 --private-key $DEPLOYER_PK --rpc-url $RPC_URL --quiet
echo "Minting 10,000 USDT to Creator..."
cast send $USDT_TOKEN "mint(address,uint256)" $CREATOR 10000000000000000000000 --private-key $DEPLOYER_PK --rpc-url $RPC_URL --quiet
echo ""

echo "After Minting:"
echo "  Subscriber USDT Balance:"
cast call $USDT_TOKEN "balanceOf(address)" $SUBSCRIBER --rpc-url $RPC_URL | xargs -I {} cast parse-units 18 {} | head -1
echo "  Creator USDT Balance:"
cast call $USDT_TOKEN "balanceOf(address)" $CREATOR --rpc-url $RPC_URL | xargs -I {} cast parse-units 18 {} | head -1
echo ""

echo "=== Step 3: Register Content Creator ==="
echo "Registering 'alice_creator'..."
cast send $REGISTRY "registerCreator(string,address)" "alice_creator" $CREATOR --private-key $CREATOR_PK --rpc-url $RPC_URL --quiet
echo "Creator registered successfully!"
echo ""

echo "=== Step 4: Subscribe to Creator ==="
echo "Approving Subscription contract to spend 100 USDT..."
cast send $USDT_TOKEN "approve(address,uint256)" $SUBSCRIPTION 100000000000000000000 --private-key $SUBSCRIBER_PK --rpc-url $RPC_URL --quiet
echo "Subscribing to alice_creator..."
cast send $SUBSCRIPTION "subscribe(address)" $CREATOR --private-key $SUBSCRIBER_PK --rpc-url $RPC_URL --quiet
echo "Subscription created!"
echo ""

echo "After Subscription:"
echo "  Subscriber USDT Balance:"
cast call $USDT_TOKEN "balanceOf(address)" $SUBSCRIBER --rpc-url $RPC_URL | xargs -I {} cast parse-units 18 {} | head -1
echo "  Subscription Contract USDT Balance:"
cast call $USDT_TOKEN "balanceOf(address)" $SUBSCRIPTION --rpc-url $RPC_URL | xargs -I {} cast parse-units 18 {} | head -1
echo "  Creator totalEarnings:"
cast call $REGISTRY "getCreator(address)" $CREATOR --rpc-url $RPC_URL | awk '{print $3}' | xargs -I {} cast parse-units 18 {} | head -1
echo ""

echo "=== Step 5: Get Subscription Details ==="
echo "Getting subscription #1 details..."
echo "Reading raw data:"
cast call $SUBSCRIPTION "getSubscription(uint256)" 1 --rpc-url $RPC_URL
echo ""

echo "=== Step 6: Simulate Time Passage (30 days) ==="
echo "Advancing time by 30 days..."
cast rpc evm_increaseTime 2592000 --rpc-url $RPC_URL
cast rpc evm_mine --rpc-url $RPC_URL
echo ""

echo "=== Step 7: Request Withdrawal (COMPLETE_EPOCH) ==="
echo "Requesting complete epoch withdrawal..."
cast send $SUBSCRIPTION "requestWithdrawal(uint256,uint8)" 1 1 --private-key $SUBSCRIBER_PK --rpc-url $RPC_URL --quiet
echo "Withdrawal requested!"
echo ""

echo "After Withdrawal Request:"
echo "  Subscriber USDT Balance:"
cast call $USDT_TOKEN "balanceOf(address)" $SUBSCRIBER --rpc-url $RPC_URL | xargs -I {} cast parse-units 18 {} | head -1
echo "  Creator totalEarnings:"
cast call $REGISTRY "getCreator(address)" $CREATOR --rpc-url $RPC_URL | awk '{print $3}' | xargs -I {} cast parse-units 18 {} | head -1
echo ""

echo "=== Step 8: Process Complete Epoch Withdrawal ==="
echo "Advancing time by another 30 days..."
cast rpc evm_increaseTime 2592000 --rpc-url $RPC_URL
cast rpc evm_mine --rpc-url $RPC_URL
echo "Processing withdrawal..."
cast send $SUBSCRIPTION "processCompleteEpochWithdrawal(uint256)" 1 --private-key $SUBSCRIBER_PK --rpc-url $RPC_URL --quiet
echo ""

echo "Final State:"
echo "  Subscriber USDT Balance:"
cast call $USDT_TOKEN "balanceOf(address)" $SUBSCRIBER --rpc-url $RPC_URL | xargs -I {} cast parse-units 18 {} | head -1
echo "  Creator totalEarnings:"
cast call $REGISTRY "getCreator(address)" $CREATOR --rpc-url $RPC_URL | awk '{print $3}' | xargs -I {} cast parse-units 18 {} | head -1
echo ""

echo "=== Simulation Complete! ==="
