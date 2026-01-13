// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDT
 * @notice Mock USDT token for testing and development
 * @dev Standard ERC20 token with mint/burn functionality for testing
 */
contract MockUSDT is ERC20, Ownable {
    /**
     * @dev Constructor that initializes the ERC20 token
     */
    constructor() ERC20("Mock USDT", "USDT") Ownable(address(1)) {}

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
}
