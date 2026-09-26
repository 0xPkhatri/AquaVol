# Protocol provenance

## Purpose

This document records the exact external sources reviewed for AquaVol's Aqua
and SwapVM integration. A pinned entry is not evidence that code has already
been imported. Import status and local modifications must remain explicit.

## Approved baseline revisions

| Component | Repository | Revision | License | Current use |
| --- | --- | --- | --- | --- |
| Aqua contracts | `https://github.com/1inch/aqua` | `ef24220ed9647555727b06867bf509cd6959d84b` | `LicenseRef-Degensoft-Aqua-Source-1.1` | Pinned for the unmodified local baseline; not yet imported |
| SwapVM contracts | `https://github.com/1inch/swap-vm` | `feb16411738331f7d05ae71d4a664154068018fc` | `LicenseRef-Degensoft-SwapVM-1.1` | Pinned for the unmodified local baseline; not yet imported |
| Aqua TypeScript SDK | `https://github.com/1inch/sdks/tree/master/typescript/aqua` | `3dbd4fd17fdc9fb814b8d55b3efcf4a39eddb32c` | `LicenseRef-Degensoft-Aqua-Source-1.1` | Reference only; TypeScript installation deferred |

The revisions were resolved from the official upstream branches on
2026-09-26. Future upgrades require a new reviewed entry rather than silently
advancing a branch reference.

## License obligations tracked for this project

- preserve upstream SPDX identifiers, copyright notices, license files, and
  third-party notices;
- identify the source as Aqua and retain the upstream attribution required by
  the Aqua license;
- clearly mark and date any later modifications;
- keep modified or derivative components under the applicable upstream source
  license when its terms require that treatment;
- maintain reproducible build and deployment instructions;
- avoid implying endorsement or certification by 1inch or Degensoft;
- review the complete license text again before public deployment or any use
  outside the hackathon prototype.

This record is engineering provenance, not legal advice.

## Import policy

Checkpoint 2 may import only the files needed to compile and exercise the
official local baseline. The import must record:

- the exact mechanism used, such as a pinned Git submodule or vendored source;
- every upstream directory included;
- preserved license and notice files;
- a clean diff proving there are no source modifications;
- the commands used to compile and run upstream tests.

The Aqua SDK must not be installed merely for the Solidity baseline. It becomes
eligible when the shared TypeScript encoding package is authorized.

## Network finding

The reviewed upstream documentation publishes deterministic Aqua and SwapVM
addresses for supported production networks, including Base mainnet. It does
not list Base Sepolia. Prompt 0005 therefore authorizes local deployment only.
Any Base Sepolia deployment requires a later recorded decision, exact-source
deployment evidence, and sponsor confirmation if available.
