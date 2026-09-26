# AquaVol contracts

This Foundry project contains the isolated `OptionSeries` lifecycle, pinned
unmodified Aqua and SwapVM submodules, an AquaVol router extension, a guarded
Uniswap V3 TWAP adapter, and a bounded implied-volatility registry. Local tests
prove the CALL/USDC settlement path, custom opcode dispatch foundation, oracle
validation boundaries, fixed-point European-call pricing, and fair-value Aqua
settlement in both directions. Inventory skew, public deployment, and
production token integration are not yet present.

## Custom SwapVM foundation

The AquaVol extension leaves both protocol submodules unchanged and adds:

- a raw two-byte instruction-header builder;
- canonical opcode allocation in the upstream unallocated bank;
- a dispatcher that handles `0xd0` and `0xd1` and delegates other opcodes upstream;
- a modified router with the official Aqua settlement interface;
- a temporary exact-output constant-price instruction for integration testing.

`AQUAVOL_CONSTANT_PRICE` accepts ABI-encoded CALL token, quote token, and
premium-per-whole-CALL values. It calculates the quote input with maker-favoring
ceiling rounding, rejects unsupported modes and insufficient output liquidity,
and never transfers tokens or mutates storage. It is test scaffolding and must
be removed or disabled before final deployment.

## Behavior

- the immutable writer deposits 18-decimal WETH and receives the same number
  of 18-decimal CALL units before expiry;
- CALL remains transferable at every lifecycle phase;
- holders exercise only from expiry until the 24-hour window closes;
- exercise USDC is calculated from an 18-decimal strike and rounded upward to
  6-decimal token units;
- exercise collects USDC, burns CALL, and delivers WETH atomically;
- after the window, the writer can redeem remaining WETH and collected USDC
  exactly once.

Incoming transfers must increase the series balance by the exact requested
amount, so fee-on-transfer collateral and quote assets are rejected. Standard,
non-rebasing ERC-20 behavior is an explicit MVP assumption.

## Verify

After cloning AquaVol, initialize the pinned protocol submodules and install
their lockfile dependencies:

```bash
git submodule update --init --recursive
yarn --cwd contracts/lib/aqua install --frozen-lockfile
yarn --cwd contracts/lib/swap-vm install --frozen-lockfile
```

Install Foundry with Solidity 0.8.30 available, then run from this directory:

```bash
forge fmt --check
forge build
forge test
```

Run the upstream protocol verification from the repository root:

```bash
cd contracts/lib/aqua
forge test --offline

cd ../swap-vm
forge test --offline --match-path 'test/solidity/*Aqua*.t.sol'
```

Run only the AquaVol baseline settlement evidence from `contracts/`:

```bash
forge test --offline --match-contract AquaSwapVMBaselineTest -vv
```

Run only the custom-router unit suite:

```bash
forge test --offline --match-path test/swapvm/AquaVolSwapVMRouter.t.sol -vv
```

Run the modified-router settlement evidence:

```bash
forge test --offline --match-contract AquaVolSwapVMSettlementTest -vv
```

Run the explicitly enabled Base Sepolia read-only evidence with your RPC URL:

```bash
RUN_BASE_SEPOLIA_FORK=true \
BASE_SEPOLIA_RPC_URL="https://your-base-sepolia-rpc" \
forge test --match-path test/fork/BaseSepoliaUniswapV3.t.sol -vv
```

The fork test resolves the WETH/test-USDC pool through the official V3 factory
and performs no transaction, deployment, liquidity operation, or swap. Without
the opt-in flag, it makes no RPC request.

## Volatility trust boundary

`VolatilityRegistry` stores 18-decimal annualized implied volatility keyed by
the deployed `OptionSeries` address. One immutable updater may write values from
0.01% through 500%; every update receives the current block timestamp and emits
its previous and new value. The registry has no ownership transfer, fallback
value, arbitrary timestamp input, token operation, or external series call.
Consumers remain responsible for enforcing a strategy-bound freshness limit.

## Fixed-point fair value

`NormalCDF` implements the bounded Abramowitz and Stegun 26.2.17 approximation,
including exact tail saturation and symmetry. `BlackScholes` implements only
the zero-rate, zero-dividend European-call model over the documented spot,
strike, time, and volatility domains. It uses the pinned, unmodified PRBMath
`v4.2.0` submodule for signed fixed-point transcendental operations.

Solidity tests read the committed Python JSON vectors directly. They cover CDF
accuracy and monotonicity, canonical call values, analytical bounds, domain
edges, intrinsic-value behavior, and a measured approximation clamp.

SwapVM opcode `0xd1` binds this math to a strategy-committed option series,
guarded TWAP oracle, volatility registry, and maximum volatility age. Buys are
exact-output and round USDC input upward; sell-backs are exact-input and round
USDC output downward. The instruction changes only SwapVM amount registers,
while Aqua performs token settlement.

Run the focused opcode and settlement evidence:

```bash
forge test --offline --match-path test/swapvm/AquaVolFairValue.t.sol -vv
forge test --offline --match-path test/integration/AquaVolFairValueSettlement.t.sol -vv
```

The suite includes unit tests, a 512-run fractional exercise fuzz test, and
stateful invariants covering lifecycle transitions and collateral solvency.

## Security status

This is unaudited hackathon software. Passing tests establish only the bounded
properties described in the repository specifications; they are not evidence
of production or mainnet readiness.
