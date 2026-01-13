// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDY
 * @notice Mock USDY token with yield mechanics
 * @dev Simulates USDY with ~5% APY, calculated as ~0.416% monthly
 */
contract MockUSDY is ERC20, Ownable {
    // Monthly yield rate: ~0.416% (5% APY)
    uint256 public constant MONTHLY_YIELD_BPS = 416; // basis points (4.16%)

    // Last yield accrual timestamp
    uint256 public lastAccrualTimestamp;

    // Total yield accrued since deployment
    uint256 public totalYieldAccrued;

    /**
     * @dev Constructor that initializes the ERC20 token
     */
    constructor() ERC20("Mock USDY", "USDY") Ownable(address(1)) {
        lastAccrualTimestamp = block.timestamp;
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
     * @dev Accrues monthly yield at ~0.416% (5% APY)
     * @notice This is a simplified yield calculation for testing
     */
    function accrueMonthlyYield() external onlyOwner {
        require(
            block.timestamp >= lastAccrualTimestamp + 30 days,
            "Can only accrue yield monthly"
        );

        uint256 currentSupply = totalSupply();
        if (currentSupply == 0) {
            lastAccrualTimestamp = block.timestamp;
            return;
        }

        // Calculate yield: (currentSupply * monthlyYieldBps) / 10000
        uint256 yieldAmount = (currentSupply * MONTHLY_YIELD_BPS) / 10000;

        // Mint yield tokens to owner (simulating yield distribution)
        _mint(owner(), yieldAmount);

        totalYieldAccrued += yieldAmount;
        lastAccrualTimestamp = block.timestamp;
    }

    /**
     * @dev Returns the current accrued yield
     * @return yieldAmount Current yield amount
     */
    function getCurrentYield() external view returns (uint256 yieldAmount) {
        uint256 timeSinceLastAccrual = block.timestamp - lastAccrualTimestamp;

        // Simplified: calculate proportional yield based on time elapsed
        // In reality, this would be more complex
        if (timeSinceLastAccrual >= 30 days) {
            uint256 currentSupply = totalSupply();
            yieldAmount = (currentSupply * MONTHLY_YIELD_BPS) / 10000;
        } else {
            yieldAmount = 0;
        }
    }

    /**
     * @dev Returns the monthly yield rate in basis points
     * @return rate Monthly yield rate (416 = 4.16%)
     */
    function getMonthlyYieldRate() external pure returns (uint256 rate) {
        return MONTHLY_YIELD_BPS;
    }
}
