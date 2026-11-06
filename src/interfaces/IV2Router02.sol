// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IV2Router02
 * @notice Interface for the Uniswap V2 Router
 */
interface IV2Router02 {
    
    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible
     * @param amountIn The amount of input tokens to send
     * @param amountOutMin The minimum amount of output tokens that must be received
     * @param path An array of token addresses representing the routing path
     * @param to The address of the recipient of the output tokens
     * @param deadline The unix timestamp after which the transaction will revert
     * @return amounts The input token amount and all subsequent output token amounts
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Adds liquidity to an ERC-20⇄ERC-20 pool
     * @param tokenA A pool token
     * @param tokenB A pool token
     * @param amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired
     * @param amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired
     * @param amountAMin Bounds the extent to which the B/A price can go up before the transaction reverts
     * @param amountBMin Bounds the extent to which the A/B price can go up before the transaction reverts
     * @param to Recipient of the liquidity tokens
     * @param deadline Unix timestamp after which the transaction will revert
     * @return amountA The amount of tokenA sent to the pool
     * @return amountB The amount of tokenB sent to the pool
     * @return liquidity The amount of liquidity tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice Removes liquidity from an ERC-20⇄ERC-20 pool
     * @param tokenA A pool token
     * @param tokenB A pool token
     * @param liquidity The amount of liquidity tokens to remove
     * @param amountAMin The minimum amount of tokenA that must be received for the transaction not to revert
     * @param amountBMin The minimum amount of tokenB that must be received for the transaction not to revert
     * @param to Recipient of the underlying assets
     * @param deadline Unix timestamp after which the transaction will revert
     * @return amountA The amount of tokenA received
     * @return amountB The amount of tokenB received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}