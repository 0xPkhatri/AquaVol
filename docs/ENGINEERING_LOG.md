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

