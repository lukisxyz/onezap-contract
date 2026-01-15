#!/bin/bash
# ==============================================================================
# Deploy OneZap Subscription Platform to Mantle Sepolia Testnet
# ==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please copy .env.example to .env and fill in your values:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$MANTLE_SEPOLIA_RPC_URL" ] || [ -z "$MANTLE_SEPOLIA_PRIVATE_KEY" ]; then
    print_error "Mantle Sepolia RPC URL or Private Key not configured!"
    echo "Please check your .env file"
    exit 1
fi

print_step "Deploying OneZap Subscription Platform to Mantle Sepolia Testnet"
echo "================================================================"
echo ""
echo "Network Details:"
echo "  RPC URL:    $MANTLE_SEPOLIA_RPC_URL"
echo "  Chain ID:   5003"
echo "  Explorer:   https://sepolia.mantlescan.xyz/"
echo "  Currency:   MNT (test token)"
echo ""

# Check for verification flag
VERIFY_FLAG=""
if [ "$VERIFY_CONTRACTS" = "true" ]; then
    if [ -z "$POLYGONSCAN_API_KEY" ]; then
        print_warning "VERIFY_CONTRACTS is true but POLYGONSCAN_API_KEY is not set"
        print_warning "Continuing without verification..."
    else
        VERIFY_FLAG="--verify --etherscan-api-key $POLYGONSCAN_API_KEY"
        print_step "Contract verification enabled (using Polygonscan API)"
    fi
fi

# Build contracts
print_step "Building contracts..."
forge build
if [ $? -eq 0 ]; then
    print_success "Contracts built successfully"
else
    print_error "Failed to build contracts"
    exit 1
fi
echo ""

# Create deployments directory
mkdir -p deployments

# Deploy to Mantle Sepolia
print_step "Deploying to Mantle Sepolia..."
echo ""

forge script script/DeployMultiNetwork.s.sol:DeployMantleSepolia \
    --rpc-url $MANTLE_SEPOLIA_RPC_URL \
    --private-key $MANTLE_SEPOLIA_PRIVATE_KEY \
    --broadcast \
    $VERIFY_FLAG \
    -vvvv

if [ $? -eq 0 ]; then
    print_success "Deployment completed successfully!"
    echo ""
    echo "================================================================"
    echo "📋 DEPLOYMENT SUMMARY"
    echo "================================================================"
    echo "Network:           Mantle Sepolia Testnet (Chain ID: 5003)"
    echo "Currency:          MNT (test token)"
    echo "Network Type:     Mantle L2 (Testnet)"
    echo "Timestamp:         $(date)"
    echo ""
    echo "📁 Deployment artifacts saved to:"
    echo "   - deployments/"
    echo ""
    echo "🔍 View on Mantle Sepolia Explorer:"
    echo "   https://sepolia.mantlescan.xyz/"
    echo ""
    echo "⚠️  Next Steps:"
    echo "   1. Verify all contracts on Mantle Sepolia Explorer"
    echo "   2. Test the contracts with small amounts"
    echo "   3. Fund test accounts with MNT from faucet"
    echo "   4. If satisfied, proceed to Mantle mainnet deployment"
    echo ""
else
    print_error "Deployment failed!"
    exit 1
fi
