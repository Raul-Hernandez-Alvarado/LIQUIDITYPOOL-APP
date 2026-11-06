// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IV2Router02} from "./interfaces/IV2Router02.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapApp {
    using SafeERC20 for IERC20;

    address public v2Router02Address;
    address public uniswapFactoryAddress;   
    address public USDT;
    address public DAI;

    event TokensSwapped(address indexed user, uint256 amountIn, uint256 amountOut, address[] path);
    event AddLiquidity(uint256 amountA, uint256 amountB, uint256 liquidity);
    event RemoveLiquidity(uint256 amountA, uint256 amountB, uint256 liquidity);

    constructor(address _v2Router02, address uniswapFactoryAddress_, address USDT_, address DAI_) {
        v2Router02Address = _v2Router02;
        uniswapFactoryAddress = uniswapFactoryAddress_;
        USDT = USDT_;
        DAI = DAI_;
    }

    function swapTokens(uint256 amountIn_, uint256 amountOutMin_, address[] memory path_, address to_,uint256 deadline_) public returns (uint256 amounts) {
        require(path_.length >= 2, "Invalid path");
        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);
        IERC20(path_[0]).forceApprove(v2Router02Address, amountIn_);
        uint[] memory amountOuts = IV2Router02(v2Router02Address).swapExactTokensForTokens(amountIn_, amountOutMin_, path_, to_, deadline_);
        emit TokensSwapped(to_, amountIn_, amountOuts[amountOuts.length - 1], path_);

        return amountOuts[amountOuts.length - 1];
    }

    function addLiquidity(uint256 amountIn_, uint256 amountOutMin_, address[] memory path_, uint256 amountAMin_, uint256 amountBMin_, uint256 deadline_) external {

        uint256 halfAmountIn = amountIn_ / 2;
        IERC20(USDT).safeTransferFrom(msg.sender, address(this), halfAmountIn);
        uint swappedAmount = swapTokens(halfAmountIn, amountOutMin_, path_, address(this), deadline_);

        IERC20(USDT).forceApprove(v2Router02Address, halfAmountIn);
        IERC20(DAI).forceApprove(v2Router02Address, swappedAmount);
        (,, uint256 lpTokenAmount) = IV2Router02(v2Router02Address).addLiquidity(USDT, DAI, halfAmountIn, swappedAmount, amountAMin_, amountBMin_, msg.sender, deadline_);
        emit AddLiquidity(amountIn_ / 2, swappedAmount, lpTokenAmount);
    }

    function removeLiquidity(uint256 liquidityAmount_, uint256 amountAMin_, uint256 amountBMin_, uint256 deadline_) external {
        IERC20 lpToken = IERC20(IFactory(uniswapFactoryAddress).getPair(USDT, DAI));
        lpToken.safeTransferFrom(msg.sender, address(this), liquidityAmount_);
        lpToken.forceApprove(v2Router02Address, liquidityAmount_);

        (uint256 amountA, uint256 amountB) = IV2Router02(v2Router02Address).removeLiquidity(USDT, DAI, liquidityAmount_, amountAMin_, amountBMin_, msg.sender, deadline_);
        emit RemoveLiquidity(amountA, amountB, liquidityAmount_);
    }

}