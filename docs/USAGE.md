# Usage Guide

## Getting Started

### Prerequisites
- Foundry installed
- Git

### Installation

```bash
git clone <repository>
cd contract
forge install
```

### Building

```bash
forge build
```

### Testing

```bash
forge test
```

### Running Tests with Coverage

```bash
forge coverage
```

## Contract Deployment

### Local Development

1. Start local blockchain:
```bash
anvil
```

2. Deploy contracts:
```bash
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY>
```

### Testnet Deployment

1. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your values
```

2. Deploy to testnet:
```bash
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

3. Verify contracts:
```bash
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain-id 11155111
```

## Using the Platform

### For Content Creators

#### 1. Register as a Content Creator

```solidity
// Call registerCreator with your username and wallet address
registry.registerCreator("my_username", msg.sender);
```

#### 2. Update Wallet Address (if needed)

```solidity
registry.updateWallet(newWalletAddress);
```

#### 3. Update Username (if needed)

```solidity
registry.updateUsername("new_username");
```

### For Subscribers

#### 1. Subscribe to a Content Creator

```solidity
// Approve USDT for subscription
usdt.approve(subscriptionContract, 100 ether);

// Subscribe
subscription.subscribe(creatorAddress, 100 ether);
```

#### 2. Request Withdrawal

```solidity
// Immediate withdrawal (1 USDT penalty)
subscription.requestWithdrawal(subscriptionId, WithdrawalType.IMMEDIATE);

// Early withdrawal (0.5 USDT penalty, 30-day delay)
subscription.requestWithdrawal(subscriptionId, WithdrawalType.EARLY);

// Complete epoch (no penalty, 1-month wait)
subscription.requestWithdrawal(subscriptionId, WithdrawalType.COMPLETE_EPOCH);
```

#### 3. Check Subscription Status

```solidity
// Get subscription details
Subscription memory sub = subscription.getSubscription(subscriptionId);

// Get all active subscriptions
uint256[] memory subs = subscription.getActiveSubscriptions(msg.sender);
```

## Withdrawal Scenarios

### Scenario 1: Immediate Withdrawal
- **When**: You need money urgently
- **Penalty**: 1 USDT
- **Return**: ~99 USDT
- **Delay**: None

### Scenario 2: Early Withdrawal (< 30 days)
- **When**: You can wait 30 days
- **Penalty**: 0.5 USDT
- **Return**: ~99.5 USDT
- **Delay**: 30 days

### Scenario 3: Complete Epoch (1 month)
- **When**: You can wait 1 month
- **Penalty**: None
- **Return**: 100 USDT + accrued yield
- **Delay**: 1 month

## Example Workflow

```solidity
// 1. Approve USDT
usdt.approve(subscriptionContract, 100 ether);

// 2. Subscribe to creator
uint256 subscriptionId = subscription.subscribe(creatorAddress, 100 ether);

// 3. Wait for yield to accrue
// Yield accrues monthly at ~0.416%

// 4. Request complete epoch withdrawal
subscription.requestWithdrawal(subscriptionId, WithdrawalType.COMPLETE_EPOCH);

// 5. Wait 1 month, then withdraw
subscription.processEarlyWithdrawal(subscriptionId);
```

## Testing Examples

```solidity
// Deploy contracts
MockUSDT usdt = new MockUSDT();
MockUSDY usdy = new MockUSDY();
ContentCreatorRegistry registry = new ContentCreatorRegistry();
Subscription subscription = new Subscription(address(usdt), address(usdy), address(registry));

// Mint tokens for testing
usdt.mint(subscriber, 1000 ether);
usdy.mint(owner, 100000 ether);

// Register creator
registry.registerCreator("creator1", creator);

// Subscribe
usdt.approve(address(subscription), 100 ether);
subscription.subscribe(creator, 100 ether);

// Request withdrawal
subscription.requestWithdrawal(1, WithdrawalType.COMPLETE_EPOCH);
```

## Security Considerations

1. **Always approve tokens before calling subscription functions**
2. **Check subscription status before requesting withdrawal**
3. **Understand penalty implications before choosing withdrawal type**
4. **Keep your private keys secure**
5. **Test thoroughly on testnet before mainnet deployment**

## Common Issues

### "Insufficient allowance"
**Solution**: Approve the contract to spend your tokens first

### "Subscription not found"
**Solution**: Check that the subscription ID is correct and belongs to you

### "Withdrawal already requested"
**Solution**: Wait for the current withdrawal to process before requesting another
