# Base Sepolia deployment plan

## Scope

This is the ordered deployment plan for public hackathon evidence. It contains
no private keys, live addresses created by AquaVol, or authorization to
broadcast transactions.

## Network and asset profile

- Chain: Base Sepolia (`84532`).
- Underlying: canonical Base Sepolia WETH when faucet balance permits.
- Quote: clearly labeled AquaVol DemoUSDC with controlled test minting.
- Spot market: WETH/DemoUSDC pool created through the official Uniswap V3
  factory and seeded near 3,800 DemoUSDC per WETH.
- Comparison only: existing canonical WETH/Circle test-USDC 0.30% pool.

Public deployment amounts MAY be smaller than local canonical inventory when
testnet WETH is scarce, but per-WETH strike, premium, decimals, and accounting
must remain identical. The final amounts require a reviewed deployment prompt.

## Ordered stages

1. Reverify chain ID, official Uniswap addresses, code hashes, token addresses,
   and deployer balance.
2. Deploy DemoUSDC with explicit faucet/minter controls and public labeling.
3. Resolve or create the WETH/DemoUSDC V3 pool through the official factory.
4. Initialize the pool, increase observation capacity, and add bounded demo
   liquidity through the official position manager.
5. Allow the complete TWAP window to elapse and write recent observations.
6. Deploy and verify `UniswapV3TwapOracle` with immutable pool guards.
7. Deploy and verify the bounded volatility registry.
8. Deploy and verify `OptionSeries`, exact-source Aqua, and
   `AquaVolSwapVMRouter` in their dependency order.
9. Write collateralized CALL, approve Aqua, encode one strategy, and ship
   virtual CALL/DemoUSDC balances.
10. Quote and settle a public trade, then record real and virtual balance
    changes, events, transaction hashes, and explorer links.
11. Run a read-only verification script against the deployment manifest.

## Operational rules

- Use a dedicated unfunded testnet deployer, preferably through an encrypted
  Foundry keystore; never commit a private key or populated `.env`.
- Broadcast only from a separately reviewed deployment prompt.
- Store chain ID, source commit, compiler settings, constructor arguments,
  addresses, transactions, and verification status in a versioned manifest.
- Treat pool initialization and initial liquidity as economic configuration;
  show the exact values before broadcasting.
- Keep local-fork demo evidence available if the public RPC, explorer, or pool
  observation history is unavailable during judging.
