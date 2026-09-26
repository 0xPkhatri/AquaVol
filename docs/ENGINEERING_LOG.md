# Engineering log

This file records decisions that constrain later specifications or
implementation. Entries are append-only; superseded decisions remain visible
and point to their replacement.

## E-001 — Separate reference math from settlement

- Date: 2026-09-26
- State: accepted

Python is the independent mathematical reference environment. It may generate
vectors and simulations but is not part of transaction authorization or live
settlement. Solidity remains authoritative for enforceable outcomes.

Reason: a reference implementation is most valuable when it is independent of
the implementation it checks.

## E-002 — Use Base Sepolia for public evidence

- Date: 2026-09-26
- State: accepted with deployment work pending

The canonical public demonstration will target Base Sepolia. Official contract
deployment availability must be verified before implementation. If compatible
official deployments are unavailable, exact upstream versions and any local
modifications must be recorded before redeployment.

## E-003 — Do not scaffold application code during discovery

- Date: 2026-09-26
- State: accepted

React, service, Python, and Foundry scaffolds are deferred until the position
lifecycle and settlement boundary are specified.

Reason: generated structure would imply interfaces and dependencies that have
not yet been justified by product behavior.

## E-004 — Keep the canonical demo dependency-light

- Date: 2026-09-26
- State: proposed

Prefer wallet, public RPC, deployed contracts, and browser-readable chain state
for the canonical path. A backend or indexer becomes mandatory only when the
approved position cannot be demonstrated reliably without it.

## E-005 — Freeze the canonical covered-call MVP

- Date: 2026-09-26
- State: accepted

The canonical market uses one writer, one WETH/USDC European call series, 10
WETH collateral, a 4,000 USDC strike, seven initial days to expiry, a 24-hour
exercise window, 64% implied volatility, 20% inventory gamma, and a 1%
half-spread. Exact-output buys and exact-input sell-backs are both in scope.

CALL tokens remain transferable after expiry, but Aqua trading stops at expiry.
Public swap evidence targets Base Sepolia; deterministic exercise uses a labeled
local-fork replay.

## E-006 — Authorize the independent math phase

- Date: 2026-09-26
- State: accepted

The first implementation artifact is a standard-library Python reference and
versioned test vectors. It is independent of the live execution path. Solidity,
Aqua, SwapVM, TypeScript, and UI implementation remain unauthorized until the
reference results are reviewed.

## E-007 — Isolate the collateral contract phase

- Date: 2026-09-26
- State: accepted

Prompt 0004 authorizes `OptionSeries` and its Foundry tests without authorizing
Aqua, SwapVM, oracle, deployment, or frontend work. The series uses no runtime
package dependency. It accepts only exact incoming WETH and USDC transfers,
uses upward rounding for fractional strike settlement, and protects every
lifecycle mutation with a reentrancy guard.

Reason: proving collateral solvency and exercise behavior independently keeps
later trading and pricing failures outside the option holder's settlement
rights.

## E-008 — Prove the unmodified protocol path first

- Date: 2026-09-26
- State: accepted

The Aqua and SwapVM integration is split into three human-reviewed commits:
provenance and specification, a pinned upstream harness, and an unmodified
end-to-end swap test. Custom opcodes are not authorized until that baseline
reconciles maker, trader, and Aqua virtual balances.

Reason: this separates upstream integration failures from errors introduced by
AquaVol's later mathematical instructions and produces meaningful Git history
without fragmenting the work into cosmetic commits.

## E-009 — Accept the unmodified local settlement baseline

- Date: 2026-09-26
- State: accepted

The pinned official Aqua and SwapVM contracts settle an exact-output CALL buy
against 10 CALL and 5,000 USDC of virtual liquidity. The authoritative quote,
real maker/trader transfers, and Aqua virtual-balance changes reconcile while
OptionSeries retains all WETH collateral. Altered order bytes and insufficient
CALL liquidity revert without partial settlement.

This accepts protocol wiring only. The upstream constant-product instruction
is not the AquaVol option-pricing model and must be replaced by separately
authorized custom pricing instructions.

## E-010 — Isolate custom opcodes from the pinned submodules

- Date: 2026-09-26
- State: accepted

AquaVol will leave both upstream Git submodules unchanged. A new derivative
router and opcode dispatcher will intercept AquaVol instructions and delegate
all other instructions to the pinned official implementation. The extension
will add no custom storage and custom opcodes will only calculate swap-register
values; Aqua remains responsible for token settlement.

At pinned SwapVM revision `feb16411738331f7d05ae71d4a664154068018fc`, the
`0xd0–0xef` bank is unallocated and `0xf0–0xff` is permanently reserved.
AquaVol allocates `0xd0` to a temporary deterministic constant-price proof and
reserves `0xd1` and `0xd2` for fair value and inventory skew. The temporary
opcode must not be presented as production pricing and must be removed or
disabled before the final deployment.

The derivative router boundary follows `LicenseRef-Degensoft-SwapVM-1.1`, with
marked changes, source availability, reproducible instructions, preserved
notices, and the required README/UI attribution.

## E-011 — Accept the deterministic custom-router foundation

- Date: 2026-09-26
- State: accepted with integration pending

The AquaVol router, dispatcher, raw instruction builder, and temporary `0xd0`
constant-price instruction compile against the pinned protocol revisions. Unit
tests prove canonical encoding, ceiling rounding, liquidity and mode guards,
upstream opcode delegation, reserved-value rejection, unchanged token balances,
and inherited Aqua/WETH bindings.

The instruction supports only exact-output quote-to-CALL calculation and has no
external calls or persistent storage. Acceptance of this unit layer does not
claim modified-router settlement; Prompt 0006 Checkpoint 3 must demonstrate
that separately through Aqua.

## E-012 — Accept modified-router Aqua settlement

- Date: 2026-09-26
- State: accepted as local integration evidence

The AquaVol router quotes and settles an exact-output one-CALL purchase for the
configured `61.505937` USDC proof premium. Real maker/trader transfers and Aqua
virtual balances reconcile, while the OptionSeries WETH collateral remains
untouched and fully backs live CALL supply.

The modified router also settles the pinned upstream constant-product program
at its independently expected `555.555556` USDC result. Maximum-input failure,
altered order bytes, and insufficient CALL liquidity all revert without partial
state changes. This accepts the custom dispatch and settlement path only; the
constant-price instruction remains temporary and is not production valuation.

## E-013 — Use Uniswap V3 TWAP for spot input

- Date: 2026-09-26
- State: accepted for Prompt 0007

AquaVol will replace the administrator-updated spot input with a strategy-bound
Uniswap V3 time-weighted average. Implied volatility remains a separately
bounded administrator input because a spot TWAP is not implied volatility.

The generic adapter will validate the official factory, exact pool and pair,
fee tier, token order, decimal normalization, full observation window, latest
observation age, harmonic-mean liquidity, and an optional deviation circuit
breaker. It will fail closed and will not fall back to `slot0()` pricing.

Read-only Base Sepolia checks found canonical WETH/Circle test-USDC pools at all
three standard fee tiers. Their observed prices differed materially from each
other and from the canonical AquaVol scenario. The public deterministic demo
will therefore use canonical Base Sepolia WETH with clearly labeled DemoUSDC in
a project-seeded pool created by the official V3 factory. The existing 0.30%
canonical pool remains a comparison feed, not the authoritative demo input.
