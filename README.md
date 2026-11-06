# LiquidityPool 💧

An advanced, gas-optimized smart contract for interacting with Uniswap V2 pools. Built with Solidity and Foundry, this project allows users to seamlessly swap tokens and manage liquidity, featuring a "Zap" function to enter a liquidity pool using only a single asset.

## Features ✨
- One-Click Zap (Add Liquidity): Supply a single token (e.g., USDT) and the contract automatically swaps half for the paired token (e.g., DAI) and provisions both into the Uniswap V2 Liquidity Pool in one transaction.
- Remove Liquidity: Easily burn LP tokens to retrieve the underlying assets.
- Token Swapping: Direct ERC20 to ERC20 token swaps with slippage protection.
- Safe Transfers: Implements OpenZeppelin's SafeERC20 (safeTransferFrom, forceApprove) for maximum compatibility with non-standard tokens.
- Gas Optimized: 
  * Protocol addresses (Router, Factory, Tokens) are declared as immutable.
  * Uses Solidity Custom Errors (ZeroAmount, InvalidPath) instead of string reverts.

## Prerequisites 📋
- Foundry installed on your system.
- An Arbitrum Mainnet RPC URL (Alchemy, Infura, etc.) to run the fork tests.

## Setup & Installation 🛠️

1. Clone the repository:
   git clone https://github.com/your-username/LIQUIDITY-POOL.git
   cd LIQUIDITY-POOL

2. Install dependencies (OpenZeppelin contracts):
   forge install OpenZeppelin/openzeppelin-contracts --no-commit

3. Build the project:
   forge build

## Testing 🧪
The test suite (LiquidityPoolTest.sol) is designed to run against real Uniswap V2 contracts on the Arbitrum Mainnet. It impersonates a whale account to execute live zaps, swaps, and liquidity removals.

Important: Because this project uses live mainnet addresses, you MUST run the tests on an Arbitrum Mainnet fork.

Run the tests using the following command (replace <YOUR_ARBITRUM_RPC_URL> with your actual endpoint):
   forge test --fork-url <YOUR_ARBITRUM_RPC_URL>

To view detailed traces (useful for verifying exact token balances and gas consumption):
   forge test --fork-url <YOUR_ARBITRUM_RPC_URL> -vvvv

## Smart Contract Architecture 🏗️
### LiquidityPool.sol
- constructor(...): Hardcodes the V2 Router, Factory, USDT, and DAI addresses to save gas.
- swapTokens(...): Executes standard exact-input token swaps.
- addLiquidity(...): The "Zap" function. Divides the input token amount in half, swaps one half for the paired token, and adds both to the Dex liquidity pool, returning LP tokens to the user.
- removeLiquidity(...): Approves the router to burn the user's LP tokens and returns the underlying paired assets to the user.

## License 📄
This project is licensed under the MIT License.

====================================================================
DESCRIPCIÓN GITHUB (Inglés - Máx 250 caracteres)
====================================================================
A smart contract to zap into Uniswap V2 pools using a single asset. Built with Solidity and Foundry, it features SafeERC20, slippage protection, and automated liquidity management tested on an Arbitrum mainnet fork.

====================================================================
DESCRIPCIÓN GITHUB (Español - Máx 250 caracteres)
====================================================================
Smart contract en Solidity y Foundry para pools de Uniswap V2. Incluye función Zap para añadir liquidez con un solo token, SafeERC20, protección anti-slippage y tests ejecutados en un fork de Arbitrum mainnet.