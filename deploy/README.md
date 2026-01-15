# 🚀 Deployment Scripts

This folder contains deployment scripts for the OneZap Subscription Platform.

## Available Scripts

### 1. deploy-sepolia.sh
Deploy to **Ethereum Sepolia Testnet**
- Chain ID: 11155111
- Currency: ETH (Sepolia)
- Cost: **FREE**
- Use for: Testing before mainnet

### 2. deploy-mantle-sepolia.sh
Deploy to **Mantle Sepolia Testnet**
- Chain ID: 5003
- Currency: MNT (test token)
- Cost: **FREE**
- Use for: Testing Mantle L2

### 3. deploy-mantle.sh
Deploy to **Mantle Mainnet**
- Chain ID: 5000
- Currency: MNT (native token)
- Cost: ~$0.009
- Use for: Production deployment

## Quick Start

### 1. Setup Environment
```bash
# Copy environment template
cp ../.env.example ../.env

# Edit with your values
nano ../.env
```

### 2. Deploy
```bash
# Make scripts executable
chmod +x *.sh

# Deploy to networks
./deploy-sepolia.sh           # Test on Ethereum
./deploy-mantle-sepolia.sh   # Test on Mantle L2
./deploy-mantle.sh           # Deploy to production
```

## What Gets Deployed

Each deployment creates 4 contracts:
1. **MockUSDT** - Subscription payment token
2. **MockUSDY** - Yield-bearing token
3. **ContentCreatorRegistry** - Creator management
4. **Subscription** - Main subscription contract

## Requirements

Before deploying, ensure you have:
- [ ] Environment variables configured in `.env`
- [ ] Private keys for deployer wallets
- [ ] RPC URLs (Alchemy recommended)
- [ ] Etherscan API key (for Sepolia verification)
- [ ] Polygonscan API key (for Mantle verification)
- [ ] Sufficient test tokens for gas fees

## Verification

After deployment:
- Check contracts on block explorer
- Verify contracts are automatically verified
- Run tests against deployed contracts

## Documentation

See `/docs/` folder for:
- `DEPLOYMENT.md` - Complete deployment guide
- `QUICK_DEPLOY.md` - Quick start guide
- `DEPLOYMENT_FILES.md` - File reference
