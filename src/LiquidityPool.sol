// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IV2Router02} from "./interfaces/IV2Router02.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title LiquidityPool
 * @notice A contract to swap tokens and zap into Uniswap V2 liquidity pools
 */
contract LiquidityPool {
    using SafeERC20 for IERC20;

    address public immutable v2Router02Address;
    address public immutable uniswapFactoryAddress;   
    address public immutable USDT;
    address public immutable DAI;

    event TokensSwapped(address indexed user, uint256 amountIn, uint256 amountOut, address[] path);
    event AddLiquidity(uint256 amountA, uint256 amountB, uint256 liquidity);
    event RemoveLiquidity(uint256 amountA, uint256 amountB, uint256 liquidity);

    error InvalidPath();
    error ZeroAmount();

    /**
     * @notice Initializes the contract with Router, Factory, and Token addresses
     * @param _v2Router02 Address of the Uniswap V2 Router
     * @param _uniswapFactoryAddress Address of the Uniswap V2 Factory
     * @param _USDT Address of the USDT token
     * @param _DAI Address of the DAI token
     */
    constructor(address _v2Router02, address _uniswapFactoryAddress, address _USDT, address _DAI) {
        v2Router02Address = _v2Router02;
        uniswapFactoryAddress = _uniswapFactoryAddress;
        USDT = _USDT;
        DAI = _DAI;
    }

    /**
     * @notice Swaps an exact amount of input tokens for a minimum amount of output tokens
     * @param amountIn The exact amount of input tokens to swap
     * @param amountOutMin The minimum amount of output tokens to receive
     * @param path The array of token addresses representing the swap path
     * @param to The recipient of the output tokens
     * @param deadline The unix timestamp after which the swap will revert
     * @return amounts The amount of output tokens received
     */
    function swapTokens(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) public returns (uint256) {
        if (amountIn == 0) revert ZeroAmount();
        if (path.length < 2) revert InvalidPath();

        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).forceApprove(v2Router02Address, amountIn);
        
        uint[] memory amountOuts = IV2Router02(v2Router02Address).swapExactTokensForTokens(
            amountIn, 
            amountOutMin, 
            path, 
            to, 
            deadline
        );
        
        uint256 amountOut = amountOuts[amountOuts.length - 1];
        emit TokensSwapped(to, amountIn, amountOut, path);

        return amountOut;
    }

    /**
     * @notice Zaps USDT into the USDT/DAI liquidity pool by swapping half and adding liquidity
     * @param amountIn The total amount of USDT to zap in
     * @param amountOutMin The minimum amount of DAI to receive from the internal swap
     * @param path The token path for the swap (USDT -> DAI)
     * @param amountAMin The minimum amount of USDT to add to liquidity
     * @param amountBMin The minimum amount of DAI to add to liquidity
     * @param deadline The unix timestamp after which the transaction will revert
     */
    function addLiquidity(uint256 amountIn, uint256 amountOutMin, address[] memory path, uint256 amountAMin, uint256 amountBMin, uint256 deadline) external {
        if (amountIn == 0) revert ZeroAmount();

        uint256 halfAmountIn = amountIn / 2;
        uint256 remainingAmount = amountIn - halfAmountIn; // Previene errores de truncamiento con números impares

        // Se transfiere al contrato la mitad que se quedará como USDT para inyectar a la liquidez
        IERC20(USDT).safeTransferFrom(msg.sender, address(this), remainingAmount);
        
        // Se llama a swapTokens, que extraerá la otra mitad (halfAmountIn) del msg.sender y la convertirá a DAI
        uint256 swappedAmount = swapTokens(halfAmountIn, amountOutMin, path, address(this), deadline);

        IERC20(USDT).forceApprove(v2Router02Address, remainingAmount);
        IERC20(DAI).forceApprove(v2Router02Address, swappedAmount);
        
        (,, uint256 lpTokenAmount) = IV2Router02(v2Router02Address).addLiquidity(
            USDT, 
            DAI, 
            remainingAmount, 
            swappedAmount, 
            amountAMin, 
            amountBMin, 
            msg.sender, 
            deadline
        );
        
        emit AddLiquidity(remainingAmount, swappedAmount, lpTokenAmount);
    }

    /**
     * @notice Removes liquidity from the USDT/DAI pool and returns tokens to the user
     * @param liquidityAmount The amount of LP tokens to burn
     * @param amountAMin The minimum amount of USDT to receive
     * @param amountBMin The minimum amount of DAI to receive
     * @param deadline The unix timestamp after which the transaction will revert
     */
    function removeLiquidity(uint256 liquidityAmount, uint256 amountAMin, uint256 amountBMin, uint256 deadline) external {
        if (liquidityAmount == 0) revert ZeroAmount();

        IERC20 lpToken = IERC20(IFactory(uniswapFactoryAddress).getPair(USDT, DAI));
        
        lpToken.safeTransferFrom(msg.sender, address(this), liquidityAmount);
        lpToken.forceApprove(v2Router02Address, liquidityAmount);

        (uint256 amountA, uint256 amountB) = IV2Router02(v2Router02Address).removeLiquidity(
            USDT, 
            DAI, 
            liquidityAmount, 
            amountAMin, 
            amountBMin, 
            msg.sender, 
            deadline
        );
        
        emit RemoveLiquidity(amountA, amountB, liquidityAmount);
    }
}