# AquaVol contracts

This Foundry project contains the isolated `OptionSeries` lifecycle. It does
not yet contain Aqua, SwapVM, pricing-oracle, deployment, or production token
integration.

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

Install Foundry with Solidity 0.8.30 available, then run from this directory:

```bash
forge fmt --check
forge build
forge test
```

The suite includes unit tests, a 512-run fractional exercise fuzz test, and
stateful invariants covering lifecycle transitions and collateral solvency.

## Security status

This is unaudited hackathon software. Passing tests establish only the bounded
properties described in the repository specifications; they are not evidence
of production or mainnet readiness.
