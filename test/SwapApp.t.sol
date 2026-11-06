// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SwapApp} from "../src/SwapApp.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SwapAppTest is Test {

    SwapApp app;
    address uniswapV2Router02Address = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address uniswapFactoryAddress = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address user = 0x2a36459aB9AfD643D5cde84910B1fC9B6be6497c; // Address with USDT in arbitrum mainnet 
    address usdtAddress = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // USDT token address in arbitrum mainnet
    address daiAddress = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI token address in arbitrum mainnet

    function setUp() public {
        app = new SwapApp(uniswapV2Router02Address, uniswapFactoryAddress, usdtAddress, daiAddress);
    }

    function testHasBeanDeployedCorrectly() public view {
        assertEq(app.v2Router02Address(), uniswapV2Router02Address);
    }

    function testSwapTokensCorrectly() public {
        vm.startPrank(user);
        uint256 amountIn = 5* 1e6; // 5 USDT with 6 decimals
        IERC20(usdtAddress).approve(address(app), amountIn);
        uint256 amountOutMin = 4 * 1e18; // Set a minimum amount out to avoid slippage issues
        uint256 deadline = 1738499328 + 100000000000; // Set a deadline far in the future to avoid transaction expiration

        address[] memory path = new address[](2);
        path[0] = usdtAddress; // USDT
        path[1] = daiAddress; // DAI

        uint256 usdtBalanceBefore = IERC20(usdtAddress).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(daiAddress).balanceOf(user);
        app.swapTokens(amountIn, amountOutMin, path, msg.sender,deadline);
        uint256 usdtBalanceAfter = IERC20(usdtAddress).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(daiAddress).balanceOf(user);

        assertEq(usdtBalanceAfter, usdtBalanceBefore - amountIn);
        assertGt(daiBalanceAfter, daiBalanceBefore);

        vm.stopPrank();
    }

    function testCanAddLiquidityCorrectly() public {
        vm.startPrank(user);
        uint256 amountIn = 10 * 1e6; // 10 USDT with 6 decimals
        IERC20(usdtAddress).approve(address(app), amountIn);
        uint256 amountOutMin = 3 * 1e18; // Set a minimum amount out to avoid slippage issues
        uint256 amountAMin = 4 * 1e6; // Minimum amount of USDT to add as liquidity
        uint256 amountBMin = 4 * 1e18; // Minimum amount of DAI to add as liquidity
        uint256 deadline = block.timestamp + 100000000000; // Set a deadline far in the future to avoid transaction expiration

        address[] memory path = new address[](2);
        path[0] = usdtAddress; // USDT
        path[1] = daiAddress; // DAI

        uint256 usdtBalanceBefore = IERC20(usdtAddress).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(daiAddress).balanceOf(user);
        
        app.addLiquidity(amountIn, amountOutMin, path, amountAMin, amountBMin, deadline);
        
        uint256 usdtBalanceAfter = IERC20(usdtAddress).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(daiAddress).balanceOf(user);

        assertLt(usdtBalanceAfter, usdtBalanceBefore - (amountIn / 2));
        assertLt(daiBalanceAfter, daiBalanceBefore - (amountIn / 2));

        vm.stopPrank();
    }

    function testCanRemoveLiquidityCorrectly() public {
        vm.startPrank(user);
        uint256 liquidityAmount = 1 * 1e18; // Amount of LP tokens to remove
        IERC20 lpToken = IERC20(IFactory(uniswapFactoryAddress).getPair(usdtAddress, daiAddress));
        lpToken.approve(address(app), liquidityAmount);
        uint256 amountAMin = 4 * 1e6; // Minimum amount of USDT to receive
        uint256 amountBMin = 4 * 1e18; // Minimum amount of DAI to receive
        uint256 deadline = block.timestamp + 100000000000; // Set a deadline far in the future to avoid transaction expiration

        uint256 usdtBalanceBefore = IERC20(usdtAddress).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(daiAddress).balanceOf(user);
        
        app.removeLiquidity(liquidityAmount, amountAMin, amountBMin, deadline);
        
        uint256 usdtBalanceAfter = IERC20(usdtAddress).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(daiAddress).balanceOf(user);

        assertGt(usdtBalanceAfter, usdtBalanceBefore);
        assertGt(daiBalanceAfter, daiBalanceBefore);

        vm.stopPrank();
    }

}
