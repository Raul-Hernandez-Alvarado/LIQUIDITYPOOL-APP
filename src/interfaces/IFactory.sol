// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IFactory
 * @notice Interface for the Uniswap V2 Factory
 */
interface IFactory {
    
    /**
     * @notice Returns the address of the pair for tokenA and tokenB, if it has been created
     * @param tokenA The address of the first token
     * @param tokenB The address of the second token
     * @return pair The address of the liquidity pool pair contract
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}