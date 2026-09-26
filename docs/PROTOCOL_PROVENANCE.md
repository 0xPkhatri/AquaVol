# Protocol provenance

## Purpose

This document records the exact external sources reviewed for AquaVol's Aqua
and SwapVM integration. A pinned entry is not evidence that code has already
been imported. Import status and local modifications must remain explicit.

## Approved baseline revisions

| Component | Repository | Revision | License | Current use |
| --- | --- | --- | --- | --- |
| Aqua contracts | `https://github.com/1inch/aqua` | `ef24220ed9647555727b06867bf509cd6959d84b` | `LicenseRef-Degensoft-Aqua-Source-1.1` | Imported unchanged as `contracts/lib/aqua` Git submodule |
| SwapVM contracts | `https://github.com/1inch/swap-vm` | `feb16411738331f7d05ae71d4a664154068018fc` | `LicenseRef-Degensoft-SwapVM-1.1` | Imported unchanged as `contracts/lib/swap-vm` Git submodule |
| Aqua TypeScript SDK | `https://github.com/1inch/sdks/tree/master/typescript/aqua` | `3dbd4fd17fdc9fb814b8d55b3efcf4a39eddb32c` | `LicenseRef-Degensoft-Aqua-Source-1.1` | Reference only; TypeScript installation deferred |

The revisions were resolved from the official upstream branches on
2026-09-26. Future upgrades require a new reviewed entry rather than silently
advancing a branch reference.

## License obligations tracked for this project

- preserve upstream SPDX identifiers, copyright notices, license files, and
  third-party notices;
- retain the exact README and applicable UI attribution required by the Aqua
  and SwapVM licenses;
- clearly mark and date any later modifications;
- keep modified or derivative components under the applicable upstream source
  license when its terms require that treatment;
- maintain reproducible build and deployment instructions;
- avoid implying endorsement or certification by 1inch or Degensoft;
- review the complete license text again before public deployment or any use
  outside the hackathon prototype.

This record is engineering provenance, not legal advice.

## Import record

Checkpoint 2 imports the complete upstream repositories as Git submodules.
This keeps their history, license files, third-party notices, source, tests,
and lockfiles intact while the AquaVol commit records exact Git revisions.

Neither submodule contains local source modifications. Their JavaScript
dependencies are local-only installations produced from the committed Yarn
lockfiles and are not repository content.

The Aqua SDK must not be installed merely for the Solidity baseline. It becomes
eligible when the shared TypeScript encoding package is authorized.

## Modified SwapVM component boundary

Prompt 0006 permits AquaVol to extend the pinned SwapVM execution model without
editing either Git submodule. The planned derivative boundary is limited to new
AquaVol router, opcode-dispatch, instruction-encoding, and directly supporting
test files. Those derivative Solidity components MUST:

- use `SPDX-License-Identifier: LicenseRef-Degensoft-SwapVM-1.1`;
- identify the pinned SwapVM revision and the modification date;
- preserve applicable notices and include the required repository attribution;
- keep complete source, tests, and reproducible build instructions public;
- clearly distinguish AquaVol changes from unchanged upstream sources.

Independent contracts such as `OptionSeries`, which neither incorporate nor
extend SwapVM, remain outside this derivative boundary. This classification is
an engineering record and not legal advice.

## Verification record

Verified on 2026-09-26 with Foundry 1.5.1-stable and Solidity 0.8.30:

```bash
yarn --cwd contracts/lib/aqua install --frozen-lockfile
yarn --cwd contracts/lib/swap-vm install --frozen-lockfile

cd contracts/lib/aqua
forge test --offline

cd ../swap-vm
forge test --offline --match-path 'test/solidity/*Aqua*.t.sol'
```

Results:

- Aqua: 50 tests passed, 0 failed;
- SwapVM Aqua suites: 95 tests passed, 0 failed;
- both submodules remained at their recorded commits with clean tracked state.

The AquaVol root smoke test deploys `Aqua` and `AquaSwapVMRouter` from these
submodules and verifies the router's immutable Aqua and WETH bindings. It does
not claim swap integration; that evidence belongs to Checkpoint 3.

## Network finding

The reviewed upstream documentation publishes deterministic Aqua and SwapVM
addresses for supported production networks, including Base mainnet. It does
not list Base Sepolia. Prompt 0005 therefore authorizes local deployment only.
Any Base Sepolia deployment requires a later recorded decision, exact-source
deployment evidence, and sponsor confirmation if available.
