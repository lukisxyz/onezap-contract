# ⚡ Quick Deploy Guide - Sepolia & Mantle

## TL;DR - 5-Minute Deployment

### 1. Setup (2 minutes)
```bash
# Copy env file
cp .env.example .env

# Edit with your values
nano .env
```

**Required in .env:**
```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
SEPOLIA_PRIVATE_KEY=your_key_here
MANTLE_SEPOLIA_RPC_URL=https://rpc.sepolia.mantle.xyz
MANTLE_SEPOLIA_PRIVATE_KEY=your_key_here
MANTLE_RPC_URL=https://rpc.mantle.xyz
MANTLE_PRIVATE_KEY=your_key_here
ETHERSCAN_API_KEY=your_key
POLYGONSCAN_API_KEY=your_key
```

### 2. Deploy (2 minutes)

**Sepolia:**
```bash
chmod +x deploy/deploy-sepolia.sh
./deploy/deploy-sepolia.sh
```

**Mantle Sepolia:**
```bash
chmod +x deploy/deploy-mantle-sepolia.sh
./deploy/deploy-mantle-sepolia.sh
```

**Mantle:**
```bash
chmod +x deploy/deploy-mantle.sh
./deploy/deploy-mantle.sh
```

### 3. Verify (1 minute)
Check on block explorer:
- Sepolia: https://sepolia.etherscan.io/
- Mantle: https://explorer.mantle.xyz/

---

## Detailed Instructions

### Get RPC URLs

#### Sepolia (Alchemy - Free)
1. Go to https://www.alchemy.com/
2. Sign up/login
3. Create new app → Sepolia
4. Copy HTTPS URL

#### Mantle
- Public RPC: `https://rpc.mantle.xyz`
- Or use Alchemy: https://www.alchemy.com/

### Get Private Keys
⚠️ **Create a NEW wallet for deployment**
- Never use your main wallet
- Fund with minimal needed tokens

### Get Faucet Tokens

#### Sepolia ETH
- https://sepoliafaucet.com/
- https://faucets.chain.link/sepolia

#### Mantle MNT
- https://faucet.mantle.xyz/

### Get API Keys

#### Etherscan (for Sepolia)
1. https://etherscan.io/apis
2. Sign up, create API key
3. Free tier: 5 calls/second

#### Polygonscan (for Mantle)
1. https://polygonscan.com/apis
2. Sign up, create API key
3. Same API works for Mantle

---

## Full Example

```bash
# 1. Setup
cp .env.example .env
nano .env

# 2. Deploy to Sepolia
./deploy-sepolia.sh

# 3. Deploy to Mantle
./deploy-mantle.sh
```

That's it! 🚀

---

## What Gets Deployed

```
📦 MockUSDT Token (100M supply)
📦 MockUSDY Token (100M supply)
📦 ContentCreatorRegistry
📦 Subscription (Main contract)
```

All contracts verified on explorer automatically.

---

## Cost Breakdown

| Network | Gas Cost | USD Cost | Time |
|---------|----------|----------|------|
| Sepolia | ~8.5M | Free | 2 min |
| Mantle | ~8.5M | ~$0.009 | 2 min |

---

## Need Help?

- Full guide: `DEPLOYMENT.md`
- Contract docs: `SCENARIO_DEMO.md`
- Tests: `forge test -vv`

---

## Pro Tips

1. **Test on Sepolia first** - Free and safer
2. **Use Alchemy Pro** for better RPC reliability
3. **Keep gas multiplier at 1.2** for faster deployment
4. **Save deployment addresses** in a spreadsheet
5. **Run tests** before mainnet deployment

```bash
# Run tests
forge test --fork-url $SEPOLIA_RPC_URL -vv
```

---

## Success! ✅

After deployment you'll have:
- ✅ 4 verified contracts on Sepolia/Mantle
- ✅ All contract addresses saved
- ✅ Ready for frontend integration
- ✅ Production-ready subscription platform

**Happy deploying!** 🎉
