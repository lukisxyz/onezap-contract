// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Subscription
 * @notice Main subscription contract handling subscriptions, withdrawals, and penalties
 * @dev Fixed subscription: 100 USDT per content creator, USDY yield accrual, multiple withdrawal options
 */
contract Subscription is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Immutable token references
    IERC20 public immutable USDT_TOKEN;
    IERC20 public immutable USDY_TOKEN;

    // Registry contract reference
    address public immutable REGISTRY;

    // Subscription amount (100 USDT)
    uint256 public constant SUBSCRIPTION_AMOUNT = 100 ether;

    // Penalty amounts
    uint256 public constant IMMEDIATE_WITHDRAWAL_PENALTY = 1 ether; // 1 USDT
    uint256 public constant EARLY_WITHDRAWAL_PENALTY = 0.5 ether; // 0.5 USDT

    // Withdrawal types
    enum WithdrawalType {
        IMMEDIATE, // Pay 1 USDT penalty, get ~99 USDT back immediately
        EARLY, // Pay 0.5 USDT penalty, get ~99.5 USDT back after 30 days
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
        require(_usdtToken != address(0), "Invalid USDT token address");
        require(_usdyToken != address(0), "Invalid USDY token address");
        require(_registry != address(0), "Invalid registry address");

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
        require(creator != address(0), "Invalid creator address");
        require(creator != msg.sender, "Cannot subscribe to yourself");

        // Check if creator is registered
        (string memory username, , , bool exists) = IContentCreatorRegistry(REGISTRY)
            .getCreator(creator);
        require(exists, "Creator not registered");

        // Transfer USDT from subscriber to contract (locked)
        USDT_TOKEN.safeTransferFrom(msg.sender, address(this), SUBSCRIPTION_AMOUNT);

        // Create subscription (USDY is tracked internally, not transferred to subscriber)
        subscriptionId = nextSubscriptionId++;
        subscriptions[subscriptionId] = SubscriptionData({
            id: subscriptionId,
            subscriber: msg.sender,
            creator: creator,
            amount: SUBSCRIPTION_AMOUNT,
            usdyAmount: SUBSCRIPTION_AMOUNT, // 1:1 with USDT initially
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
        require(sub.subscriber == msg.sender, "Not subscription owner");
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription not active");
        require(
            sub.withdrawalRequestTime == 0,
            "Withdrawal already requested"
        );

        uint256 penalty = 0;
        if (withdrawalType == WithdrawalType.IMMEDIATE) {
            penalty = IMMEDIATE_WITHDRAWAL_PENALTY;
        } else if (withdrawalType == WithdrawalType.EARLY) {
            penalty = EARLY_WITHDRAWAL_PENALTY;
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
     * @dev Processes early withdrawal after 30-day delay
     * @param subscriptionId Subscription ID
     */
    function processEarlyWithdrawal(uint256 subscriptionId) external nonReentrant {
        SubscriptionData storage sub = subscriptions[subscriptionId];
        require(sub.subscriber == msg.sender, "Not subscription owner");
        require(sub.status == SubscriptionStatus.WITHDRAWAL_REQUESTED, "Invalid status");
        require(sub.withdrawalType == WithdrawalType.EARLY, "Not early withdrawal");
        require(
            block.timestamp >= sub.withdrawalRequestTime + 30 days,
            "30-day delay not met"
        );

        _processWithdrawal(subscriptionId);
    }

    /**
     * @dev Processes complete epoch withdrawal after 1 month
     * @param subscriptionId Subscription ID
     */
    function processCompleteEpochWithdrawal(uint256 subscriptionId) external nonReentrant {
        SubscriptionData storage sub = subscriptions[subscriptionId];
        require(sub.subscriber == msg.sender, "Not subscription owner");
        require(sub.status == SubscriptionStatus.WITHDRAWAL_REQUESTED, "Invalid status");
        require(sub.withdrawalType == WithdrawalType.COMPLETE_EPOCH, "Not complete epoch");
        require(
            block.timestamp >= sub.withdrawalRequestTime + 30 days,
            "1-month delay not met"
        );

        _processWithdrawal(subscriptionId);
    }

    /**
     * @dev Internal function to process withdrawal
     * @param subscriptionId Subscription ID
     */
    function _processWithdrawal(uint256 subscriptionId) internal {
        SubscriptionData storage sub = subscriptions[subscriptionId];

        // Calculate current USDY value with yield
        uint256 currentValue = calculateCurrentValue(subscriptionId);

        // Calculate return amount (subtract penalty if any)
        uint256 returnAmount = currentValue;

        // For complete epoch, return full amount with yield
        if (sub.withdrawalType == WithdrawalType.COMPLETE_EPOCH) {
            // Full amount with yield - already calculated in currentValue
        } else if (sub.withdrawalType == WithdrawalType.EARLY) {
            // Return 99.5 USDT (0.5 USDT penalty)
            returnAmount = sub.amount - EARLY_WITHDRAWAL_PENALTY;
        } else if (sub.withdrawalType == WithdrawalType.IMMEDIATE) {
            // Return 99 USDT (1 USDT penalty)
            returnAmount = sub.amount - IMMEDIATE_WITHDRAWAL_PENALTY;
        }

        // Transfer USDT back to subscriber from contract balance
        USDT_TOKEN.safeTransfer(msg.sender, returnAmount);

        sub.status = SubscriptionStatus.WITHDRAWAL_PROCESSED;

        emit WithdrawalProcessed(subscriptionId, msg.sender, returnAmount);
    }

    /**
     * @dev Calculates the current value of a subscription including yield
     * @param subscriptionId Subscription ID
     * @return currentValue Current value in USDT
     */
    function calculateCurrentValue(uint256 subscriptionId) internal view returns (uint256 currentValue) {
        SubscriptionData storage sub = subscriptions[subscriptionId];
        uint256 timeElapsed = block.timestamp - sub.lastYieldAccrual;

        if (timeElapsed == 0) {
            return sub.usdyAmount;
        }

        // Yield calculation: principal * rate * time
        // currentValue = (principal * APY * time) / (10000 * seconds_per_year) + principal
        uint256 apyBps = 500; // 5% APY
        uint256 secondsPerYear = 365 days;

        uint256 yieldAmount = (sub.usdyAmount * apyBps * timeElapsed) / (10000 * secondsPerYear);
        currentValue = sub.usdyAmount + yieldAmount;
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
