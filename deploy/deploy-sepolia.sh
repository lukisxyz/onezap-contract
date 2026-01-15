#!/bin/bash
# ==============================================================================
# Deploy OneZap Subscription Platform to Sepolia Testnet
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
if [ -z "$SEPOLIA_RPC_URL" ] || [ -z "$SEPOLIA_PRIVATE_KEY" ]; then
    print_error "Sepolia RPC URL or Private Key not configured!"
    echo "Please check your .env file"
    exit 1
fi

print_step "Deploying OneZap Subscription Platform to Sepolia Testnet"
echo "============================================================"
echo ""

# Check for verification flag
VERIFY_FLAG=""
if [ "$VERIFY_CONTRACTS" = "true" ]; then
    if [ -z "$ETHERSCAN_API_KEY" ]; then
        print_warning "VERIFY_CONTRACTS is true but ETHERSCAN_API_KEY is not set"
        print_warning "Continuing without verification..."
    else
        VERIFY_FLAG="--verify --etherscan-api-key $ETHERSCAN_API_KEY"
        print_step "Contract verification enabled"
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

# Deploy to Sepolia
print_step "Deploying to Sepolia..."
echo "RPC URL: $SEPOLIA_RPC_URL"
echo "Chain ID: 11155111"
echo ""

forge script script/DeployMultiNetwork.s.sol:DeploySepolia \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    $VERIFY_FLAG \
    -vvvv

if [ $? -eq 0 ]; then
    print_success "Deployment completed successfully!"
    echo ""
    echo "============================================================"
    echo "📋 DEPLOYMENT SUMMARY"
    echo "============================================================"
    echo "Network:           Sepolia Testnet (Chain ID: 11155111)"
    echo "Currency:          ETH (Sepolia)"
    echo "Timestamp:         $(date)"
    echo ""
    echo "📁 Deployment artifacts saved to:"
    echo "   - deployments/"
    echo ""
    echo "🔍 View on Sepolia Etherscan:"
    echo "   https://sepolia.etherscan.io/"
    echo ""
    echo "⚠️  Next Steps:"
    echo "   1. Verify all contracts are verified on Etherscan"
    echo "   2. Test the contracts with small amounts"
    echo "   3. Fund test accounts with Sepolia ETH"
    echo ""
else
    print_error "Deployment failed!"
    exit 1
fi
