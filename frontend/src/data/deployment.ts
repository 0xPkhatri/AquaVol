export const deployment = {
  chainId: 84532,
  network: "Base Sepolia",
  explorer: "https://sepolia.basescan.org",
  rpcUrl: "https://sepolia.base.org",
  spot: 3842.159899,
  volatility: 0.64,
  liveStrike: 4000,
  liveExpiry: "2026-10-04T03:00:00Z",
  quoteSize: 0.01,
  lastAsk: 0.815649,
  settledAsk: 0.779818,
  addresses: {
    aqua: "0x170B0d7C534785eAD9Ecbc278B3D87781855D4F9",
    router: "0x8b734D9222D51Aa75C038AB81145FC86D5b4ceb4",
    pricing: "0x68b7036ae9e1266675f226F36d2c764927C84884",
    oracle: "0x2D2bfade5AD73C946fdcA2a882A21E542A568903",
    optionSeries: "0x7F3c414aEf81CAf377fF34A419EC388105fBA117",
    volatilityRegistry: "0xF2537463ddeA54EEa205bD183a9e303bDe02C37e",
    pool: "0x0d9516aA182Aa72284802372afaa943E9E77A6D0",
  },
  tradeTx: "0xb49b7574aa15a92cb96fb6b804279ca321488dcd1b43a8c6bb780a9dd1cf7379",
} as const;

export const shortAddress = (value: string) =>
  `${value.slice(0, 6)}…${value.slice(-4)}`;
