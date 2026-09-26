# Base Sepolia deployment evidence

- Network: Base Sepolia (`84532`)
- Explorer: `https://sepolia.basescan.org`
- Operator: `0xA4A103c574a9bF22Bc49a7Ce3f089508300320d5`
- Recorded source HEAD: `05452e89e8cc057332555cb045357e7304f50b45`
- Deployment state: **partial — infrastructure, protocol core, oracle, series,
  and Aqua position are live; the distinct-trader transaction and final source
  verification remain pending**

The operator is a disposable testnet-only account acting as deployer,
volatility updater, option writer, and Aqua maker. This role consolidation is a
hackathon operating choice, not a production security model. The public trade
must use a distinct trader account.

## Live contracts

| Component | Address | Deployment transaction | Block |
| --- | --- | --- | ---: |
| AquaVol Demo USD (`avUSD`) | `0xf47584005b5c0F90f292C811016E70e37E3BA9dc` | `0xc7e7fa5b04d91090979e33c9aeb0e5f5c99c005ab7982ed67eee29e496b2c601` | 47,329,669 |
| WETH/avUSD Uniswap V3 pool | `0x0d9516aA182Aa72284802372afaa943E9E77A6D0` | `0xd0218b789250e95232e6f81fccdb4a34b1cdc69016ab0e1850a7402c38affd6b` | 47,329,864 |
| Exact-source Aqua | `0x170B0d7C534785eAD9Ecbc278B3D87781855D4F9` | `0x8a1c691a9180a362fde08a5bde631d85dfd92ed3ab4b7add9f4c0507ea56e946` | 47,330,045 |
| AquaVol pricing engine | `0x68b7036ae9e1266675f226F36d2c764927C84884` | `0xe89d2fafffd66be94d8a65b84a45c5ef54555a6709d8da5b9d952b98ce0e8378` | 47,330,045 |
| Modified SwapVM router | `0x8b734D9222D51Aa75C038AB81145FC86D5b4ceb4` | `0x90c28a8af14d6d2b9487b2b8e10f7be1a4b980b2b93482a3d241093a170dc893` | 47,330,045 |
| Volatility registry | `0xF2537463ddeA54EEa205bD183a9e303bDe02C37e` | `0x30f66c9e14d6feb52f9fdd0c1c4ffdcc801a0cd993991d55868742c0b5836638` | 47,330,045 |
| Guarded Uniswap V3 TWAP oracle | `0x2D2bfade5AD73C946fdcA2a882A21E542A568903` | `0xd617f52a7f7b14107bcb58a7d1bd5e8cf83fa0e981579b981e58f5d314453356` | pending receipt transcription |
| WETH 4,000 call OptionSeries | `0x7F3c414aEf81CAf377fF34A419EC388105fBA117` | `0x6ab7f1b685d7067b8a29d40f866cd64ab4624794139fdb3370eb95e1e1658e71` | pending receipt transcription |

The core deployment used uncommitted checkpoint-4 source changes. The final
source commit must therefore be recorded separately after human review; this
record does not claim that the recorded HEAD alone reproduces the deployed
router.

## Uniswap market

- Official factory: `0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24`
- Official position manager: `0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2`
- Official SwapRouter02: `0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4`
- Canonical WETH: `0x4200000000000000000000000000000000000006`
- Fee tier: `3000` (0.30%)
- Initial target price: 3,800 avUSD per WETH
- Seed inputs: 0.10 WETH and 380 avUSD
- LP NFT: `82416`
- Pool liquidity after seeding: `6,164,414,002,968`
- Observation capacity requested: `16`
- Required TWAP window: 30 minutes

The pool and quote token are project-seeded demo infrastructure. They are not
Circle USDC and must not be represented as production liquidity.

## Core verification

Read-only Base Sepolia checks returned deployed runtime sizes of 2,678 bytes
for Aqua, 11,201 bytes for the pricing engine, 22,503 bytes for the router, and
942 bytes for the registry. The router reports the Aqua and canonical WETH
addresses above, binds the listed pricing engine, and the registry reports the
operator as its immutable updater.

The computation-heavy Black-Scholes and inventory logic lives in the stateless
pricing engine so the official SwapVM-derived router remains below the EIP-170
runtime limit. The router still dispatches AquaVol opcodes `0xd1` and `0xd2`,
and Aqua/SwapVM remains the only settlement path.

## Live option position

- Strategy hash: `0x1a38d471dce4c9cc7a425010f584dd7ebaf5e0bbcdb42a67506dac1d91e465f5`
- Series strike: 4,000 avUSD per WETH
- Expiry: 2026-10-04 03:00:00 UTC
- Exercise window: 24 hours
- Implied volatility: 64% annualized
- Maximum volatility age: 1 hour
- Initial CALL inventory and locked collateral: 0.10 CALL / 0.10 WETH
- Initial virtual quote inventory: 50 avUSD
- Inventory gamma: 0.20 WAD
- Half spread: 0.01 WAD
- First public-state quote for 0.01 CALL: 0.672443 avUSD

The position preparation broadcast confirmed that live OptionSeries collateral
equals total CALL supply and that Aqua reports the reviewed virtual balances.
Its transactions were:

| Action | Transaction |
| --- | --- |
| Set series volatility | `0x075b70086d9cffde41fa26b7b7daf815e40c010d099aa2e2cf34564503189b4d` |
| Approve WETH collateral | `0x4add93a906f574c056332799a03750501bb817a61033b66aef071d2559fb9cb5` |
| Write 0.10 covered CALL | `0x91b2cab5d1a4e3d8a1bd78634c4ee658d36862c1b447a918a93f928814163f55` |
| Approve CALL to Aqua | `0xc2a391feec5216fda41ace2d0be184f1c78b920b77060e99edd865a2f4b0488f` |
| Approve avUSD to Aqua | `0x856c9cb61823f837989103b9199f342c05aff1ab981c47548e09cf55002c989e` |
| Ship immutable Aqua strategy | `0xfc0953fea80cd8061fddcc4d03365ae8a1be34313506941e24d3d8f2161d38ef` |

The most recent observation refresh used approval transaction
`0x3d1b96d96546ec52461456897305e158112c8a952ea6d741f4f66d583fae6242`
and swap transaction
`0x43c61710dbeca565e1d4cf830cca0b088f3c11ced55de411eb69b6cd79a9f604`.

## Remaining evidence

- settle a bounded trade from a distinct trader wallet;
- record balance reconciliation, strategy hash, next quote, source
  verification status, and all remaining transaction hashes.
