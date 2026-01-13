// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ContentCreatorRegistry
 * @notice Manages content creator registration and information
 * @dev Allows self-registration with wallet + username, fully updatable
 */
contract ContentCreatorRegistry is Ownable {
    // Struct to store creator information
    struct Creator {
        string username;
        address wallet;
        uint256 totalEarnings; // Total USDY earned from subscriptions + penalties
        bool exists;
    }

    // Mapping from creator address to Creator struct
    mapping(address => Creator) public creators;

    // Array of all creator addresses
    address[] private allCreators;

    // Events
    event CreatorRegistered(address indexed creator, string username, address wallet);
    event CreatorUpdated(address indexed creator, string newUsername, address newWallet);
    event WalletUpdated(address indexed creator, address newWallet);
    event UsernameUpdated(address indexed creator, string newUsername);
    event EarningsUpdated(address indexed creator, uint256 additionalEarnings, uint256 totalEarnings);

    /**
     * @dev Constructor that initializes the contract
     */
    constructor() Ownable(address(1)) {}

    /**
     * @dev Registers a new content creator
     * @param username Creator's username
     * @param wallet Creator's wallet address
     */
    function registerCreator(string calldata username, address wallet) external {
        require(!creators[msg.sender].exists, "Creator already registered");
        require(bytes(username).length > 0, "Username cannot be empty");
        require(wallet != address(0), "Invalid wallet address");

        creators[msg.sender] = Creator({
            username: username,
            wallet: wallet,
            totalEarnings: 0,
            exists: true
        });

        allCreators.push(msg.sender);

        emit CreatorRegistered(msg.sender, username, wallet);
    }

    /**
     * @dev Updates both username and wallet
     * @param newUsername New username
     * @param newWallet New wallet address
     */
    function updateCreator(string calldata newUsername, address newWallet) external {
        require(creators[msg.sender].exists, "Creator not registered");
        require(bytes(newUsername).length > 0, "Username cannot be empty");
        require(newWallet != address(0), "Invalid wallet address");

        creators[msg.sender].username = newUsername;
        creators[msg.sender].wallet = newWallet;

        emit CreatorUpdated(msg.sender, newUsername, newWallet);
    }

    /**
     * @dev Updates the creator's wallet address
     * @param newWallet New wallet address
     */
    function updateWallet(address newWallet) external {
        require(creators[msg.sender].exists, "Creator not registered");
        require(newWallet != address(0), "Invalid wallet address");

        creators[msg.sender].wallet = newWallet;

        emit WalletUpdated(msg.sender, newWallet);
    }

    /**
     * @dev Updates the creator's username
     * @param newUsername New username
     */
    function updateUsername(string calldata newUsername) external {
        require(creators[msg.sender].exists, "Creator not registered");
        require(bytes(newUsername).length > 0, "Username cannot be empty");

        creators[msg.sender].username = newUsername;

        emit UsernameUpdated(msg.sender, newUsername);
    }

    /**
     * @dev Adds earnings to a creator (called by Subscription contract)
     * @param creator Creator's address
     * @param amount Amount of earnings to add
     */
    function addEarnings(address creator, uint256 amount) external onlyOwner {
        require(creators[creator].exists, "Creator not registered");
        require(amount > 0, "Amount must be greater than 0");

        creators[creator].totalEarnings += amount;

        emit EarningsUpdated(creator, amount, creators[creator].totalEarnings);
    }

    /**
     * @dev Returns creator information
     * @param creator Creator's address
     * @return username Creator's username
     * @return wallet Creator's wallet address
     * @return totalEarnings Total earnings
     * @return exists Whether creator exists
     */
    function getCreator(address creator)
        external
        view
        returns (
            string memory username,
            address wallet,
            uint256 totalEarnings,
            bool exists
        )
    {
        Creator memory c = creators[creator];
        return (c.username, c.wallet, c.totalEarnings, c.exists);
    }

    /**
     * @dev Returns all registered creator addresses
     * @return Array of all creator addresses
     */
    function getAllCreators() external view returns (address[] memory) {
        return allCreators;
    }

    /**
     * @dev Returns the total number of registered creators
     * @return Number of creators
     */
    function getCreatorCount() external view returns (uint256) {
        return allCreators.length;
    }

    /**
     * @dev Checks if an address is a registered creator
     * @param creator Address to check
     * @return True if registered, false otherwise
     */
    function isCreator(address creator) external view returns (bool) {
        return creators[creator].exists;
    }
}
