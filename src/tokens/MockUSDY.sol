// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDY
 * @notice Mock USDY token with 5% APY yield mechanics
 * @dev Simulates real USDY with fixed 5% APY that accrues continuously
 */
contract MockUSDY is ERC20, Ownable {
    // Fixed APY: 5% per year
    uint256 public constant APY_BPS = 500; // 5% = 500 basis points

    // Seconds in a year
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // Last yield accrual timestamp
    uint256 public lastYieldTimestamp;

    // Total yield accrued since deployment
    uint256 public totalYieldAccrued;

    /**
     * @dev Constructor that initializes the ERC20 token
     */
    constructor() ERC20("Mock USDY", "USDY") Ownable(address(1)) {
        lastYieldTimestamp = block.timestamp;
    }

    /**
     * @dev Mints new tokens to the specified address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from the caller's balance
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Burns tokens from a specified address
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address from, uint256 amount) external {
        _burn(from, amount);
    }

    /**
     * @dev Accrues yield based on time elapsed since last accrual
     * @notice Accrues yield continuously at 5% APY
     */
    function accrueYield() external onlyOwner {
        uint256 timeElapsed = block.timestamp - lastYieldTimestamp;
        if (timeElapsed == 0) return;

        uint256 currentSupply = totalSupply();
        if (currentSupply == 0) {
            lastYieldTimestamp = block.timestamp;
            return;
        }

        // Calculate yield: principal * rate * time
        // yield = (currentSupply * APY_BPS * timeElapsed) / (10000 * SECONDS_PER_YEAR)
        uint256 yieldAmount = (currentSupply * APY_BPS * timeElapsed) / (10000 * SECONDS_PER_YEAR);

        if (yieldAmount > 0) {
            // Mint yield tokens to owner (simulating yield distribution)
            _mint(owner(), yieldAmount);
            totalYieldAccrued += yieldAmount;
        }

        lastYieldTimestamp = block.timestamp;
    }

    /**
     * @dev Returns the current balance including accrued yield
     * @param account Address to query
     * @return Current balance with yield
     */
    function balanceOf(address account) public view override returns (uint256) {
        uint256 baseBalance = super.balanceOf(account);
        uint256 timeElapsed = block.timestamp - lastYieldTimestamp;

        if (timeElapsed == 0 || baseBalance == 0) {
            return baseBalance;
        }

        // Calculate accrued yield: principal * rate * time
        uint256 accruedYield = (baseBalance * APY_BPS * timeElapsed) / (10000 * SECONDS_PER_YEAR);

        return baseBalance + accruedYield;
    }

    /**
     * @dev Returns the current accrued yield for an account
     * @param account Address to query
     * @return Accrued yield amount
     */
    function getAccruedYield(address account) external view returns (uint256) {
        uint256 baseBalance = super.balanceOf(account);
        uint256 timeElapsed = block.timestamp - lastYieldTimestamp;

        if (timeElapsed == 0 || baseBalance == 0) {
            return 0;
        }

        // Calculate accrued yield: principal * rate * time
        uint256 accruedYield = (baseBalance * APY_BPS * timeElapsed) / (10000 * SECONDS_PER_YEAR);

        return accruedYield;
    }

    /**
     * @dev Returns the APY in basis points
     * @return rate APY rate (500 = 5%)
     */
    function getApy() external pure returns (uint256 rate) {
        return APY_BPS;
    }

    /**
     * @dev Returns the last yield timestamp
     * @return timestamp Last yield accrual timestamp
     */
    function getLastYieldTimestamp() external view returns (uint256 timestamp) {
        return lastYieldTimestamp;
    }
}
