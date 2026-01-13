# Lossless Subscription Platform

A decentralized subscription platform where content creators earn from USDY yield while subscribers get their principal back.

## Overview

This platform enables:
- Fixed subscriptions: 100 USDT per content creator
- USDY yield accrual: ~5% APY (~0.416% monthly)
- Multiple withdrawal options with different penalties
- Content creator registry with updatable information
- Multiple subscriptions per content creator

## Core Mechanics

### Subscription Flow
1. Subscriber pays 100 USDT
2. USDT swapped to USDY
3. USDY accrues yield monthly at ~0.416%
4. Subscriber can withdraw using different options

### Withdrawal Options

#### Immediate Withdrawal
- **Penalty**: 1 USDT
- **Return**: ~99 USDT
- **Delay**: None

#### Early Withdrawal (< 30 days)
- **Penalty**: 0.5 USDT
- **Return**: ~99.5 USDT
- **Delay**: 30 days

#### Complete Epoch (1 month)
- **Penalty**: None
- **Return**: 100 USDT + accrued yield
- **Delay**: 1 month

## Smart Contracts

- **MockUSDT**: Mock USDT token for testing
- **MockUSDY**: Mock USDY token with yield mechanics
- **ContentCreatorRegistry**: Manages content creator registration
- **Subscription**: Main contract handling subscriptions and withdrawals

## Documentation

See the `docs/` directory for detailed documentation:
- [Architecture](docs/ARCHITECTURE.md) - Smart contract architecture
- [API Reference](docs/API.md) - Contract API documentation
- [Usage Guide](docs/USAGE.md) - How to use the platform

## Quick Start

### Prerequisites
- [Foundry](https://getfoundry.sh/) installed

### Installation

```bash
git clone <repository>
cd contract
forge install
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Run Tests with Coverage

```shell
$ forge coverage
```

### Local Deployment

1. Start local blockchain:
```bash
anvil
```

2. Deploy contracts:
```bash
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY>
```

### Testnet Deployment

1. Set up environment:
```bash
cp .env.example .env
# Edit .env with your values
```

2. Deploy to testnet:
```shell
$ forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Project Structure

```
contract/
├── src/
│   ├── tokens/
│   │   ├── MockUSDT.sol
│   │   └── MockUSDY.sol
│   ├── registry/
│   │   └── ContentCreatorRegistry.sol
│   └── subscription/
│       └── Subscription.sol
├── test/
│   ├── TokenTests.t.sol
│   ├── RegistryTests.t.sol
│   └── SubscriptionTests.t.sol
├── script/
│   └── Deploy.s.sol
├── docs/
│   ├── ARCHITECTURE.md
│   ├── API.md
│   └── USAGE.md
└── .env.example
```

## Features

- ✅ Mock USDT token implementation
- ✅ Mock USDY token with yield mechanics
- ✅ Content creator registry
- ✅ Subscription management
- ✅ Multiple withdrawal options
- ✅ Penalty distribution system
- ✅ Comprehensive test suite
- ✅ Deployment scripts

## Testing

The test suite covers:
- Token minting and burning
- Registry registration and updates
- Subscription creation and management
- All withdrawal scenarios
- Event emissions
- Access control
- Revert conditions

Run all tests:
```bash
forge test -vv
```

## Security

- ReentrancyGuard on withdrawal functions
- Access control for critical functions
- Input validation on all public functions
- SafeERC20 for token transfers

## Contributing

1. Create an issue in beads
2. Implement the feature/fix
3. Add tests
4. Run tests and ensure they pass
5. Submit a pull request

## License

MIT
