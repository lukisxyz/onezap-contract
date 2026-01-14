# 🚀 OneZap Subscription Platform - Deployment Guide

## Table of Contents
1. [Overview](#overview)
2. [Supported Networks](#supported-networks)
3. [Prerequisites](#prerequisites)
4. [Environment Setup](#environment-setup)
5. [Deploy to Sepolia (Testnet)](#deploy-to-sepolia-testnet)
6. [Deploy to Mantle (Mainnet)](#deploy-to-mantle-mainnet)
7. [Verification](#verification)
8. [Post-Deployment](#post-deployment)
9. [Troubleshooting](#troubleshooting)

---

## Overview

This guide will walk you through deploying the OneZap Subscription Platform to:
- **Sepolia Testnet** (for testing)
- **Mantle Network** (L2 - recommended for production)

The platform consists of 4 smart contracts:
1. **MockUSDT** - USDT token for subscriptions
2. **MockUSDY** - Yield-bearing USDY token
3. **ContentCreatorRegistry** - Manages content creators
4. **Subscription** - Main subscription contract

---

## Supported Networks

### 🧪 Sepolia Testnet (Recommended for Testing)
- **Chain ID:** 11155111
- **Currency:** ETH (Sepolia)
- **Use Case:** Testing before mainnet deployment
- **Cost:** Free (test ETH from faucet)
- **Transaction Speed:** ~15 seconds
- **Explorer:** https://sepolia.etherscan.io/

**Get Test ETH:**
- Visit: https://sepoliafaucet.com/
- Or: https://faucets.chain.link/sepolia

### ⚡ Mantle Network (Recommended for Production)
- **Chain ID:** 5000
- **Currency:** MNT (Mantle native token)
- **Use Case:** Production deployment
- **Cost:** Very cheap (~$0.01 per transaction)
- **Transaction Speed:** ~2-3 seconds
- **Explorer:** https://explorer.mantle.xyz/

**Get MNT:**
- Visit: https://faucet.mantle.xyz/

---

## Prerequisites

### Required Software
```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
```

### Required Services
1. **Alchemy or Infura** (for Sepolia RPC)
   - Sign up at https://www.alchemy.com/ (free tier available)
   - Create a new app on Sepolia network

2. **Block Explorer APIs** (for contract verification)
   - **Etherscan:** https://etherscan.io/apis
   - **Polygonscan:** https://polygonscan.com/apis

---

## Environment Setup

### Step 1: Copy Environment File
```bash
cp .env.example .env
```

### Step 2: Edit .env File
```bash
nano .env
```

Fill in the required values:

#### For Sepolia Deployment:
```env
# Sepolia
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
SEPOLIA_PRIVATE_KEY=your_sepolia_wallet_private_key_without_quotes

# Verification
ETHERSCAN_API_KEY=your_etherscan_api_key
```

#### For Mantle Deployment:
```env
# Mantle
MANTLE_RPC_URL=https://rpc.mantle.xyz
MANTLE_PRIVATE_KEY=your_mantle_wallet_private_key_without_quotes

# Verification
POLYGONSCAN_API_KEY=your_polygonscan_api_key
```

### Step 3: Secure Your Private Keys
⚠️ **CRITICAL SECURITY NOTES:**
- Never commit `.env` to version control
- Use a dedicated deployer wallet (not your main wallet)
- Only fund with minimal needed tokens
- Keep backups of your private keys in a secure location

---

## Deploy to Sepolia (Testnet)

### Option 1: Using the Deployment Script (Recommended)
```bash
# Make script executable
chmod +x deploy-sepolia.sh

# Run deployment
./deploy-sepolia.sh
```

The script will:
1. ✅ Validate environment variables
2. ✅ Build contracts
3. ✅ Deploy to Sepolia
4. ✅ Verify contracts (if API key provided)
5. ✅ Save deployment artifacts

### Option 2: Manual Deployment
```bash
# Build contracts
forge build

# Deploy to Sepolia
forge script script/DeployMultiNetwork.s.sol:DeploySepolia \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

### Expected Output
```
=== Sepolia Deployment Complete ===
MockUSDT: 0x1234...abcd
MockUSDY: 0x2345...cdef
ContentCreatorRegistry: 0x3456...defg
Subscription: 0x4567...efgh
Timestamp: 1705123456
```

---

## Deploy to Mantle (Mainnet)

### Option 1: Using the Deployment Script (Recommended)
```bash
# Make script executable
chmod +x deploy-mantle.sh

# Run deployment
./deploy-mantle.sh
```

The script will:
1. ✅ Validate environment variables
2. ✅ Build contracts
3. ✅ Deploy to Mantle
4. ✅ Verify contracts (using Polygonscan API)
5. ✅ Save deployment artifacts

### Option 2: Manual Deployment
```bash
# Build contracts
forge build

# Deploy to Mantle
forge script script/DeployMultiNetwork.s.sol:DeployMantle \
    --rpc-url $MANTLE_RPC_URL \
    --private-key $MANTLE_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $POLYGONSCAN_API_KEY \
    -vvvv
```

### Expected Output
```
=== Mantle Deployment Complete ===
MockUSDT: 0x1234...abcd
MockUSDY: 0x2345...cdef
ContentCreatorRegistry: 0x3456...defg
Subscription: 0x4567...efgh
Timestamp: 1705123456
```

---

## Verification

### Check Deployment Status
```bash
# View on Sepolia Etherscan
https://sepolia.etherscan.io/address/<CONTRACT_ADDRESS>

# View on Mantle Explorer
https://explorer.mantle.xyz/address/<CONTRACT_ADDRESS>
```

### Verify Contracts
Contracts should be automatically verified if you used `--verify` flag. If not:
```bash
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
    --chain-id <CHAIN_ID> \
    --etherscan-api-key <API_KEY>
```

### Run Tests on Deployed Contracts
```bash
# Run all tests
forge test --fork-url $SEPOLIA_RPC_URL -vv

# Run specific test
forge test --fork-url $SEPOLIA_RPC_URL --match-test testSubscribeToCreator -vv
```

---

## Post-Deployment

### Step 1: Save Contract Addresses
Update your `.env` file with deployed addresses:
```env
# Sepolia
SEPOLIA_USDT_TOKEN=0x1234...abcd
SEPOLIA_USDY_TOKEN=0x2345...cdef
SEPOLIA_REGISTRY=0x3456...defg
SEPOLIA_SUBSCRIPTION=0x4567...efgh

# Mantle
MANTLE_USDT_TOKEN=0x1234...abcd
MANTLE_USDY_TOKEN=0x2345...cdef
MANTLE_REGISTRY=0x3456...defg
MANTLE_SUBSCRIPTION=0x4567...efgh
```

### Step 2: Create Deployment Documentation
```bash
# Save deployment info
echo "Deployment completed at $(date)" > deployments/deployment_info.txt
echo "Network: $NETWORK" >> deployments/deployment_info.txt
echo "Block number: $(cast block-number --rpc-url $RPC_URL)" >> deployments/deployment_info.txt
```

### Step 3: Test the Platform
```bash
# Mint tokens
cast send $USDT_TOKEN "mint(address,uint256)" $YOUR_WALLET 1000000000000000000000 \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

# Register creator
cast send $REGISTRY "registerCreator(string,address)" "your_creator" $YOUR_WALLET \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

# Subscribe
cast send $USDT_TOKEN "approve(address,uint256)" $SUBSCRIPTION 100000000000000000000 \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

cast send $SUBSCRIPTION "subscribe(address)" $YOUR_WALLET \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL
```

---

## Troubleshooting

### Issue: "Insufficient funds"
**Solution:** Fund your deployer wallet with more ETH/MNT

### Issue: "Contract verification failed"
**Solution:**
```bash
# Try verifying manually
forge verify-contract <ADDRESS> <CONTRACT_NAME> \
    --chain-id <CHAIN_ID> \
    --etherscan-api-key <API_KEY> \
    --compiler-version 0.8.20
```

### Issue: "RPC rate limit exceeded"
**Solution:** Use a premium RPC provider (Alchemy Pro, Infura Pro)

### Issue: "Private key not found"
**Solution:** Ensure `PRIVATE_KEY` doesn't have quotes in `.env`

### Issue: Transactions failing
**Solution:**
1. Check network congestion
2. Increase gas price:
```bash
forge script script/Deploy.s.sol:Deploy \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --gas-price 30000000000 \  # 30 gwei
    -vvvv
```

---

## Gas Costs (Estimated)

### Sepolia Testnet
- MockUSDT: ~2,000,000 gas
- MockUSDY: ~2,000,000 gas
- ContentCreatorRegistry: ~1,500,000 gas
- Subscription: ~3,000,000 gas
- **Total:** ~8.5M gas (free on testnet)

### Mantle Network
- MockUSDT: ~2,000,000 gas × $0.000001 ≈ $0.002
- MockUSDY: ~2,000,000 gas × $0.000001 ≈ $0.002
- ContentCreatorRegistry: ~1,500,000 gas × $0.000001 ≈ $0.0015
- Subscription: ~3,000,000 gas × $0.000001 ≈ $0.003
- **Total:** ~8.5M gas ≈ **$0.0085**

---

## Security Checklist

Before deploying to production:

- [ ] Private key stored securely (not in .env on shared machines)
- [ ] Deployer wallet funded with minimal required amount
- [ ] All contracts verified on block explorer
- [ ] Tests passing on testnet
- [ ] Gas costs calculated and acceptable
- [ ] Backup of deployment artifacts saved
- [ ] Frontend integration tested
- [ ] Security audit completed (recommended)
- [ ] Monitoring and alerting set up

---

## Support

If you encounter issues:
1. Check this deployment guide
2. Review Foundry documentation: https://book.getfoundry.sh/
3. Check network status: https://status.ethereum.org/
4. Review contract code and tests

---

## Next Steps

After successful deployment:
1. ✅ Set up frontend integration
2. ✅ Deploy to testnet and test thoroughly
3. ✅ Conduct security audit
4. ✅ Launch on Mantle mainnet
5. ✅ Monitor contracts and transactions
6. ✅ Gather user feedback and iterate

---

**🎉 Happy Deploying!**
