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
