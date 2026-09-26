# Dependency register

No third-party package or source repository has been installed or vendored at
this stage. Entries below are candidates that require version and license
review before integration.

| Component | Intended role | Source | Current state |
| --- | --- | --- | --- |
| Aqua contracts | Virtual balance allocation and token settlement | https://github.com/1inch/aqua | Under evaluation |
| SwapVM contracts | Composable swap program execution | https://github.com/1inch/swap-vm | Under evaluation |
| Aqua SDK | TypeScript transaction encoding and event parsing | https://github.com/1inch/sdks/tree/master/typescript/aqua | Under evaluation |
| Foundry | Solidity build and test toolchain | https://github.com/foundry-rs/foundry | Planned |
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

