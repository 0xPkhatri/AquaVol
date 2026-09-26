# Dependency register

Pinned third-party protocol repositories are installed as Git submodules.
Entries below record current and planned dependencies; adding another package
still requires version and license review before integration.

| Component | Intended role | Source | Current state |
| --- | --- | --- | --- |
| Aqua contracts | Virtual balance allocation and token settlement | `1inch/aqua@ef24220ed9647555727b06867bf509cd6959d84b` | Imported unchanged as a Git submodule; upstream tests pass |
| SwapVM contracts | Composable swap program execution and base for the isolated AquaVol router extension | `1inch/swap-vm@feb16411738331f7d05ae71d4a664154068018fc` | Imported unchanged as a Git submodule; Aqua integration tests pass; AquaVol derivative files use the SwapVM-1.1 license |
| Aqua SDK | TypeScript transaction encoding and event parsing | `1inch/sdks@3dbd4fd17fdc9fb814b8d55b3efcf4a39eddb32c` (`typescript/aqua`) | Pinned reference; installation deferred |
| Foundry 1.5.1-stable (`b0a9dd9`) | Local Solidity build and test toolchain; no vendored runtime code | https://github.com/foundry-rs/foundry | In use for Prompt 0004; MIT OR Apache-2.0 |
| React | Browser UI | https://github.com/facebook/react | Planned |
| Vite | Frontend development and build | https://github.com/vitejs/vite | Planned |

## Registration requirements

Before a dependency is introduced, record:

- exact version, tag, or commit;
- license and any notice obligations;
- files or packages used;
- reason it is needed;
- whether it is modified;
- how the integration is verified.

This register covers code and packages. External data sources, price feeds, and
volatility inputs will be documented in the product and security specifications
because they create runtime trust assumptions.
