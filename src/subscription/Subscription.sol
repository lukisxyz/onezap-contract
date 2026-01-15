// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title IMockUSDY
 * @dev Interface for MockUSDY token with yield mechanics
 */
interface IMockUSDY is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function accrueYield() external;
    function getApy() external view returns (uint256);
}

/**
 * @title Subscription
 * @notice Main subscription contract handling subscriptions, withdrawals, and penalties
 * @dev Fixed subscription: 100 USDT per content creator, USDY yield accrual, multiple withdrawal options
 */
contract Subscription is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Custom errors
    error Subscription__InvalidCreatorAddress();
    error Subscription__CannotSubscribeToSelf();
    error Subscription__CreatorNotRegistered();
    error Subscription__InvalidWithdrawalType();
    error Subscription__InvalidSubscriptionId();
    error Subscription__NotSubscriptionOwner();
    error Subscription__SubscriptionNotActive();
    error Subscription__WithdrawalAlreadyRequested();
    error Subscription__WithdrawalRequestTimeNotMet();
    error Subscription__InsufficientAllowance();
    error Subscription__InvalidAmount();
    error Subscription__MintFailed();

    // Immutable token references
    IERC20 public immutable USDT_TOKEN;
    IERC20 public immutable USDY_TOKEN;

    // Registry contract reference
    address public immutable REGISTRY;

    // Subscription amount (100 USDT with 6 decimals)
    uint256 public constant SUBSCRIPTION_AMOUNT = 100 * 10**6; // 100 USDT (6 decimals)

    // Penalty amounts (1 USDT with 6 decimals)
    uint256 public constant IMMEDIATE_WITHDRAWAL_PENALTY = 1 * 10**6; // 1 USDT (6 decimals)

    // Decimal conversion factor: USDY (18 decimals) / USDT (6 decimals)
    uint256 public constant USDY_DECIMALS = 18;
    uint256 public constant USDT_DECIMALS = 6;
    uint256 public constant DECIMAL_CONVERSION_FACTOR = 10**(USDY_DECIMALS - USDT_DECIMALS); // 10^12

    /**
     * @dev Returns the APY from USDY token
     * @return apy APY in basis points (e.g., 500 = 5%)
     */
    function getApy() external view returns (uint256 apy) {
        try IMockUSDY(address(USDY_TOKEN)).getApy() returns (uint256 _apy) {
            return _apy;
        } catch {
            return 0;
        }
    }

    // Lock period in seconds (30 days)
    uint256 public constant LOCK_PERIOD = 30 days;

    // Withdrawal types
    enum WithdrawalType {
        IMMEDIATE, // Pay 1 USDT penalty, get ~99 USDT back immediately
        COMPLETE_EPOCH // No penalty, get 100 USDT + yield back after 1 month
    }

    // Subscription status
    enum SubscriptionStatus {
        ACTIVE,
        WITHDRAWAL_REQUESTED,
        WITHDRAWAL_PROCESSED
    }

    // Struct to store subscription information
    struct SubscriptionData {
        uint256 id;
        address subscriber;
        address creator;
        uint256 amount; // Original subscription amount in USDT
        uint256 usdyAmount; // USDT swapped to USDY
        uint256 startTime;
        uint256 lastYieldAccrual;
        SubscriptionStatus status;
        WithdrawalType withdrawalType;
        uint256 withdrawalRequestTime;
    }

    // Mapping from subscription ID to SubscriptionData
    mapping(uint256 => SubscriptionData) public subscriptions;

    // Mapping from subscriber to array of subscription IDs
    mapping(address => uint256[]) private subscriberSubscriptions;

    // Next subscription ID
    uint256 private nextSubscriptionId = 1;

    // Events
    event Subscribed(
        uint256 indexed subscriptionId,
        address indexed subscriber,
        address indexed creator,
        uint256 amount
    );

    event WithdrawalRequested(
        uint256 indexed subscriptionId,
        address indexed subscriber,
        WithdrawalType withdrawalType,
        uint256 penalty
    );

    event WithdrawalProcessed(
        uint256 indexed subscriptionId,
        address indexed subscriber,
        uint256 amountReturned
    );

    event PenaltyDistributed(
        address indexed creator,
        uint256 amount,
        WithdrawalType withdrawalType
    );

    /**
     * @dev Constructor that initializes the contract
     * @param _usdtToken USDT token contract address
     * @param _usdyToken USDY token contract address
     * @param _registry Content creator registry contract address
     */
    constructor(
        address _usdtToken,
        address _usdyToken,
        address _registry
    ) Ownable(address(1)) {
        if (_usdtToken == address(0)) revert Subscription__InvalidCreatorAddress();
        if (_usdyToken == address(0)) revert Subscription__InvalidCreatorAddress();
        if (_registry == address(0)) revert Subscription__InvalidCreatorAddress();

        USDT_TOKEN = IERC20(_usdtToken);
        USDY_TOKEN = IERC20(_usdyToken);
        REGISTRY = _registry;
    }

    /**
     * @dev Subscribes to a content creator
     * @param creator Content creator's address
     * @return subscriptionId The ID of the new subscription
     */
    function subscribe(address creator) external nonReentrant returns (uint256 subscriptionId) {
        if (creator == address(0)) revert Subscription__InvalidCreatorAddress();
        if (creator == msg.sender) revert Subscription__CannotSubscribeToSelf();

        // Check if creator is registered
        (, , , bool exists) = IContentCreatorRegistry(REGISTRY)
            .getCreator(creator);
        if (!exists) revert Subscription__CreatorNotRegistered();

        // Transfer USDT from subscriber to contract (locked)
        USDT_TOKEN.safeTransferFrom(msg.sender, address(this), SUBSCRIPTION_AMOUNT);

        // Mint USDY tokens (1:1 swap, converted to 18 decimals)
        uint256 usdyToMint = SUBSCRIPTION_AMOUNT * DECIMAL_CONVERSION_FACTOR;
        try IMockUSDY(address(USDY_TOKEN)).mint(address(this), usdyToMint) {} catch {
            // If mint fails, revert
            revert Subscription__MintFailed();
        }

        // Create subscription (stores base USDY amount)
        subscriptionId = nextSubscriptionId++;
        subscriptions[subscriptionId] = SubscriptionData({
            id: subscriptionId,
            subscriber: msg.sender,
            creator: creator,
            amount: SUBSCRIPTION_AMOUNT,
            usdyAmount: usdyToMint, // Base USDY amount (will grow via accrueYield)
            startTime: block.timestamp,
            lastYieldAccrual: block.timestamp,
            status: SubscriptionStatus.ACTIVE,
            withdrawalType: WithdrawalType.IMMEDIATE, // default
            withdrawalRequestTime: 0
        });

        // Add to subscriber's subscriptions
        subscriberSubscriptions[msg.sender].push(subscriptionId);

        emit Subscribed(subscriptionId, msg.sender, creator, SUBSCRIPTION_AMOUNT);
    }

    /**
     * @dev Requests a withdrawal with specified type
     * @param subscriptionId Subscription ID
     * @param withdrawalType Type of withdrawal (IMMEDIATE, EARLY, COMPLETE_EPOCH)
     */
    function requestWithdrawal(uint256 subscriptionId, WithdrawalType withdrawalType)
        external
        nonReentrant
    {
        SubscriptionData storage sub = subscriptions[subscriptionId];
        if (sub.subscriber == address(0)) revert Subscription__InvalidSubscriptionId();
        if (sub.subscriber != msg.sender) revert Subscription__NotSubscriptionOwner();
        if (sub.status != SubscriptionStatus.ACTIVE) revert Subscription__SubscriptionNotActive();
        if (sub.withdrawalRequestTime != 0) revert Subscription__WithdrawalAlreadyRequested();
        if (block.timestamp < sub.startTime + 30 days) revert Subscription__WithdrawalRequestTimeNotMet();

        uint256 penalty = 0;
        if (withdrawalType == WithdrawalType.IMMEDIATE) {
            penalty = IMMEDIATE_WITHDRAWAL_PENALTY;
        }

        sub.withdrawalType = withdrawalType;
        sub.withdrawalRequestTime = block.timestamp;
        sub.status = SubscriptionStatus.WITHDRAWAL_REQUESTED;

        // Distribute penalty to creator
        if (penalty > 0) {
            USDT_TOKEN.safeTransfer(sub.creator, penalty);
            IContentCreatorRegistry(REGISTRY).addEarnings(sub.creator, penalty);

            emit PenaltyDistributed(sub.creator, penalty, withdrawalType);
        }

        emit WithdrawalRequested(subscriptionId, msg.sender, withdrawalType, penalty);

        // Process immediate withdrawal
        if (withdrawalType == WithdrawalType.IMMEDIATE) {
            _processWithdrawal(subscriptionId);
        }
    }

    /**
     * @dev Processes complete epoch withdrawal after 1 month
     * @param subscriptionId Subscription ID
     */
    function processCompleteEpochWithdrawal(uint256 subscriptionId) external nonReentrant {
        SubscriptionData storage sub = subscriptions[subscriptionId];
        if (sub.subscriber == address(0)) revert Subscription__InvalidSubscriptionId();
        if (sub.subscriber != msg.sender) revert Subscription__NotSubscriptionOwner();
        if (sub.status != SubscriptionStatus.WITHDRAWAL_REQUESTED) revert Subscription__SubscriptionNotActive();
        if (sub.withdrawalType != WithdrawalType.COMPLETE_EPOCH) revert Subscription__InvalidWithdrawalType();
        if (block.timestamp < sub.withdrawalRequestTime + 30 days) revert Subscription__WithdrawalRequestTimeNotMet();

        _processWithdrawal(subscriptionId);
    }

    /**
     * @dev Internal function to process withdrawal
     * @param subscriptionId Subscription ID
     */
    function _processWithdrawal(uint256 subscriptionId) internal {
        SubscriptionData storage sub = subscriptions[subscriptionId];

        // Get current USDY balance from USDY contract (includes ALL yield!)
        uint256 currentUsdyBalance = USDY_TOKEN.balanceOf(address(this));

        // Calculate return amount and yield distribution
        uint256 returnAmount = sub.amount; // Subscriber gets principal back (6 decimals)
        uint256 yieldAmount = 0;

        // For complete epoch, distribute yield to creator
        if (sub.withdrawalType == WithdrawalType.COMPLETE_EPOCH) {
            // USDY contract already calculated the yield
            // We just need to distribute it
            if (currentUsdyBalance > sub.usdyAmount) {
                // Yield is the extra value from USDY growth
                yieldAmount = currentUsdyBalance - sub.usdyAmount;

                // Convert yield to USDT (6 decimals) and distribute to creator
                uint256 yieldInUsdt = yieldAmount / DECIMAL_CONVERSION_FACTOR;
                IContentCreatorRegistry(REGISTRY).addEarnings(sub.creator, yieldInUsdt);
            }

            // Burn the original USDY amount
            IMockUSDY(address(USDY_TOKEN)).burn(sub.usdyAmount);

        } else if (sub.withdrawalType == WithdrawalType.IMMEDIATE) {
            // Return 99 USDT (1 USDT penalty)
            returnAmount = sub.amount - IMMEDIATE_WITHDRAWAL_PENALTY;
            // Burn the base USDY
            IMockUSDY(address(USDY_TOKEN)).burn(sub.usdyAmount);
        }

        // Transfer USDT back to subscriber from contract balance
        USDT_TOKEN.safeTransfer(msg.sender, returnAmount);

        sub.status = SubscriptionStatus.WITHDRAWAL_PROCESSED;

        emit WithdrawalProcessed(subscriptionId, msg.sender, returnAmount);
    }


    /**
     * @dev Returns subscription information
     * @param subscriptionId Subscription ID
     * @return Subscription data
     */
    function getSubscription(uint256 subscriptionId) external view returns (SubscriptionData memory) {
        return subscriptions[subscriptionId];
    }

    /**
     * @dev Returns all subscription IDs for a subscriber
     * @param subscriber Subscriber's address
     * @return Array of subscription IDs
     */
    function getActiveSubscriptions(address subscriber) external view returns (uint256[] memory) {
        return subscriberSubscriptions[subscriber];
    }

    /**
     * @dev Returns the number of active subscriptions for a subscriber
     * @param subscriber Subscriber's address
     * @return Number of active subscriptions
     */
    function getSubscriptionCount(address subscriber) external view returns (uint256) {
        return subscriberSubscriptions[subscriber].length;
    }
}

/**
 * @title IContentCreatorRegistry
 * @notice Interface for Content Creator Registry contract
 */
interface IContentCreatorRegistry {
    function getCreator(address creator)
        external
        view
        returns (
            string memory username,
            address wallet,
            uint256 totalEarnings,
            bool exists
        );

    function addEarnings(address creator, uint256 amount) external;

    function isCreator(address creator) external view returns (bool);
}
