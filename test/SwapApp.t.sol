// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LiquidityPool} from "../src/LiquidityPool.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IFactory} from "../src/interfaces/IFactory.sol";

/**
 * @title LiquidityPoolTest
 * @notice Test suite for the LiquidityPool contract on an Arbitrum fork
 */
contract LiquidityPoolTest is Test {

    LiquidityPool pool;
    
    address constant UNISWAP_V2_ROUTER = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address constant UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant WHALE = 0x2a36459aB9AfD643D5cde84910B1fC9B6be6497c; // Address with USDT in arbitrum mainnet 
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // USDT token address in arbitrum mainnet
    address constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI token address in arbitrum mainnet

    function setUp() public {
        pool = new LiquidityPool(UNISWAP_V2_ROUTER, UNISWAP_FACTORY, USDT, DAI);
    }

    /**
     * @notice Verifies that the contract is deployed with the correct Router address
     */
    function testHasBeenDeployedCorrectly() public view {
        assertEq(pool.v2Router02Address(), UNISWAP_V2_ROUTER);
        assertEq(pool.uniswapFactoryAddress(), UNISWAP_FACTORY);
    }

    /**
     * @notice Ensures the transaction reverts if the user tries to swap 0 tokens
     */
    function testRevertIfAmountInIsZero() public {
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;

        vm.expectRevert(LiquidityPool.ZeroAmount.selector);
        pool.swapTokens(0, 1 ether, path, msg.sender, block.timestamp + 1000);
    }

    /**
     * @notice Ensures the transaction reverts if the routing path is invalid
     */
    function testRevertIfPathIsInvalid() public {
        address[] memory path = new address[](1);
        path[0] = USDT;

        vm.expectRevert(LiquidityPool.InvalidPath.selector);
        pool.swapTokens(1e6, 1 ether, path, msg.sender, block.timestamp + 1000);
    }

    /**
     * @notice Tests a successful swap from USDT to DAI impersonating a whale account
     */
    function testSwapTokensCorrectly() public {
        vm.startPrank(WHALE);
        uint256 amountIn = 5 * 1e6; // 5 USDT with 6 decimals
        
        IERC20(USDT).approve(address(pool), amountIn);
        
        uint256 amountOutMin = 4 * 1e18; 
        uint256 deadline = block.timestamp + 1000; 

        address[] memory path = new address[](2);
        path[0] = USDT; 
        path[1] = DAI; 

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(WHALE);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(WHALE);
        
        pool.swapTokens(amountIn, amountOutMin, path, WHALE, deadline);
        
        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(WHALE);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(WHALE);

        assertEq(usdtBalanceAfter, usdtBalanceBefore - amountIn);
        assertGt(daiBalanceAfter, daiBalanceBefore);

        vm.stopPrank();
    }

    /**
     * @notice Tests the 'Zap' feature: swapping half the input amount and adding both sides to the liquidity pool
     */
    function testCanAddLiquidityCorrectly() public {
        vm.startPrank(WHALE);
        uint256 amountIn = 10 * 1e6; // 10 USDT with 6 decimals
        
        IERC20(USDT).approve(address(pool), amountIn);
        
        uint256 amountOutMin = 3 * 1e18; 
        uint256 amountAMin = 4 * 1e6; // Min USDT to add
        uint256 amountBMin = 4 * 1e18; // Min DAI to add
        uint256 deadline = block.timestamp + 1000; 

        address[] memory path = new address[](2);
        path[0] = USDT; 
        path[1] = DAI; 

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(WHALE);
        
        pool.addLiquidity(amountIn, amountOutMin, path, amountAMin, amountBMin, deadline);
        
        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(WHALE);

        // The user should have spent the full amountIn (10 USDT) from their wallet
        assertEq(usdtBalanceAfter, usdtBalanceBefore - amountIn);

        // Verify that the user received LP tokens
        IERC20 lpToken = IERC20(IFactory(UNISWAP_FACTORY).getPair(USDT, DAI));
        assertGt(lpToken.balanceOf(WHALE), 0);

        vm.stopPrank();
    }

    /**
     * @notice Tests burning LP tokens to retrieve the underlying USDT and DAI
     */
    function testCanRemoveLiquidityCorrectly() public {
        // First, add liquidity so we have LP tokens to remove
        vm.startPrank(WHALE);
        uint256 amountIn = 10 * 1e6; 
        IERC20(USDT).approve(address(pool), amountIn);
        address[] memory path = new address[](2);
        path[0] = USDT; 
        path[1] = DAI; 
        
        pool.addLiquidity(amountIn, 3 * 1e18, path, 4 * 1e6, 4 * 1e18, block.timestamp + 1000);
        
        IERC20 lpToken = IERC20(IFactory(UNISWAP_FACTORY).getPair(USDT, DAI));
        uint256 liquidityAmount = lpToken.balanceOf(WHALE);
        
        require(liquidityAmount > 0, "No LP tokens minted");

        // Now, test removing that liquidity
        lpToken.approve(address(pool), liquidityAmount);
        
        uint256 amountAMin = 0; // Set to 0 for simplicity in the test
        uint256 amountBMin = 0; 
        uint256 deadline = block.timestamp + 1000; 

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(WHALE);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(WHALE);
        
        pool.removeLiquidity(liquidityAmount, amountAMin, amountBMin, deadline);
        
        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(WHALE);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(WHALE);
        uint256 finalLpBalance = lpToken.balanceOf(WHALE);

        assertGt(usdtBalanceAfter, usdtBalanceBefore);
        assertGt(daiBalanceAfter, daiBalanceBefore);
        assertEq(finalLpBalance, 0);

        vm.stopPrank();
    }
}