import { useEffect, useState } from "react";
import { createPublicClient, formatEther, http } from "viem";
import { baseSepolia } from "viem/chains";
import { deployment } from "../data/deployment";

const scalarAbi = (name: string) => [{ type: "function", name, stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] }] as const;
const volAbi = [{ type: "function", name: "read", stateMutability: "view", inputs: [{ type: "address" }], outputs: [{ type: "uint256" }, { type: "uint64" }] }] as const;
const client = createPublicClient({ chain: baseSepolia, transport: http(import.meta.env.VITE_BASE_SEPOLIA_RPC_URL || deployment.rpcUrl) });
type Live = { block?: bigint; supply?: bigint; written?: bigint; vol?: bigint; loading: boolean; error?: boolean };

export function LiveMarketStatus() {
  const [live, setLive] = useState<Live>({ loading: true });
  const refresh = async () => {
    setLive({ loading: true });
    try {
      const [block, supply, written, volatility] = await Promise.all([
        client.getBlockNumber(),
        client.readContract({ address: deployment.addresses.optionSeries, abi: scalarAbi("totalSupply"), functionName: "totalSupply" }),
        client.readContract({ address: deployment.addresses.optionSeries, abi: scalarAbi("totalWritten"), functionName: "totalWritten" }),
        client.readContract({ address: deployment.addresses.volatilityRegistry, abi: volAbi, functionName: "read", args: [deployment.addresses.optionSeries] }),
      ]);
      setLive({ block, supply, written, vol: volatility[0], loading: false });
    } catch { setLive({ loading: false, error: true }); }
  };
  useEffect(() => { void refresh(); }, []);
  const ether = (value?: bigint) => value === undefined ? "—" : Number(formatEther(value)).toFixed(2);
  return <section className="live-sync">
    <div><span className="eyebrow">LIVE CONTRACT READ</span><strong>{live.loading ? "Synchronizing…" : live.error ? "RPC unavailable" : `Block ${live.block?.toLocaleString()}`}</strong></div>
    <div><small>CALL SUPPLY</small><strong>{ether(live.supply)}</strong></div>
    <div><small>TOTAL WRITTEN</small><strong>{ether(live.written)} WETH</strong></div>
    <div><small>ONCHAIN IV</small><strong>{live.vol === undefined ? "—" : `${Number(formatEther(live.vol)) * 100}%`}</strong></div>
    <div><small>TWAP POLICY</small><strong className="sync-good">GUARDED · 30 MIN</strong></div>
    <button disabled={live.loading} onClick={() => void refresh()}>↻ Refresh</button>
  </section>;
}
