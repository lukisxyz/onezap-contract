# API Documentation

## Mock USDT Token

### Functions

#### `mint(address to, uint256 amount)`
Mints new tokens for testing purposes.

**Parameters:**
- `to`: Address to mint tokens to
- `amount`: Amount of tokens to mint

#### `burn(uint256 amount)`
Burns tokens from the caller's balance.

**Parameters:**
- `amount`: Amount of tokens to burn

## Mock USDY Token

### Functions

#### `mint(address to, uint256 amount)`
Mints new tokens for testing purposes.

**Parameters:**
- `to`: Address to mint tokens to
- `amount`: Amount of tokens to mint

#### `accrueMonthlyYield()`
Accrues monthly yield at ~0.416% (5% APY).

**Access**: Owner only

#### `getCurrentYield()` → uint256
Returns the current accrued yield amount.

**Returns:**
- `uint256`: Current yield amount

## Content Creator Registry

### Functions

#### `registerCreator(string username, address wallet)`
Registers a new content creator.

**Parameters:**
- `username`: Creator's username
- `wallet`: Creator's wallet address

#### `updateWallet(address newWallet)`
Updates the creator's wallet address.

**Parameters:**
- `newWallet`: New wallet address

#### `updateUsername(string newUsername)`
Updates the creator's username.

**Parameters:**
- `newUsername`: New username

#### `getCreator(address creator) → Creator`
Returns creator information.

**Parameters:**
- `creator`: Creator's address

**Returns:**
- `Creator`: Creator struct with username, wallet, and earnings

#### `getAllCreators() → address[]`
Returns all registered creator addresses.

**Returns:**
- `address[]`: Array of all creator addresses

## Subscription Contract

### Functions

#### `subscribe(address creator, uint256 amount)`
Subscribes to a content creator.

**Parameters:**
- `creator`: Content creator's address
- `amount`: Amount to subscribe (100 USDT)

#### `requestWithdrawal(uint256 subscriptionId, WithdrawalType type)`
Requests a withdrawal with specified type.

**Parameters:**
- `subscriptionId`: Subscription ID
- `type`: Withdrawal type (IMMEDIATE, EARLY, COMPLETE_EPOCH)

#### `processEarlyWithdrawal(uint256 subscriptionId)`
Processes early withdrawal after 30-day delay.

**Parameters:**
- `subscriptionId`: Subscription ID

#### `getSubscription(uint256 subscriptionId) → Subscription`
Returns subscription information.

**Parameters:**
- `subscriptionId`: Subscription ID

**Returns:**
- `Subscription`: Subscription struct with all details

#### `getActiveSubscriptions(address subscriber) → uint256[]`
Returns active subscription IDs for a subscriber.

**Parameters:**
- `subscriber`: Subscriber's address

**Returns:**
- `uint256[]`: Array of subscription IDs

## Events

### Subscription Contract

#### `Subscribed(uint256 indexed subscriptionId, address indexed subscriber, address indexed creator, uint256 amount)`
Emitted when a new subscription is created.

#### `WithdrawalRequested(uint256 indexed subscriptionId, address indexed subscriber, WithdrawalType type, uint256 penalty)`
Emitted when a withdrawal is requested.

#### `WithdrawalProcessed(uint256 indexed subscriptionId, address indexed subscriber, uint256 amountReturned)`
Emitted when a withdrawal is processed.

#### `PenaltyDistributed(address indexed creator, uint256 amount)`
Emitted when a penalty is distributed to a content creator.
