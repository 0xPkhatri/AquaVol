import { useState } from "react";
import { createPublicClient, createWalletClient, custom, formatEther, formatUnits, getAddress, http, parseEther, type Address, type EIP1193Provider, type Hash } from "viem";
import { baseSepolia } from "viem/chains";
import { deployment, shortAddress } from "../data/deployment";

const erc20Abi = [{ type: "function", name: "balanceOf", stateMutability: "view", inputs: [{ type: "address" }], outputs: [{ type: "uint256" }] }] as const;
const wethAbi = [
  { type: "function", name: "deposit", stateMutability: "payable", inputs: [], outputs: [] },
  { type: "function", name: "approve", stateMutability: "nonpayable", inputs: [{ type: "address" }, { type: "uint256" }], outputs: [{ type: "bool" }] },
] as const;
const seriesAbi = [
  { type: "function", name: "approve", stateMutability: "nonpayable", inputs: [{ type: "address" }, { type: "uint256" }], outputs: [{ type: "bool" }] },
  { type: "function", name: "write", stateMutability: "nonpayable", inputs: [{ type: "uint256" }], outputs: [] },
] as const;
const aquaAbi = [{ type: "function", name: "push", stateMutability: "nonpayable", inputs: [{ type: "address" }, { type: "address" }, { type: "bytes32" }, { type: "address" }, { type: "uint256" }], outputs: [] }] as const;
const aquaBalanceAbi = [{ type: "function", name: "safeBalances", stateMutability: "view", inputs: [{ type: "address" }, { type: "address" }, { type: "bytes32" }, { type: "address" }, { type: "address" }], outputs: [{ type: "uint256" }, { type: "uint256" }] }] as const;
const publicClient = createPublicClient({ chain: baseSepolia, transport: http(import.meta.env.VITE_BASE_SEPOLIA_RPC_URL || deployment.rpcUrl) });
type Balances = { eth: string; avUsd: string; call: string };

export function WalletPanel() {
  const [account, setAccount] = useState<Address>();
  const [balances, setBalances] = useState<Balances>();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [amount, setAmount] = useState("0.01");
  const [action, setAction] = useState("");
  const [lastTx, setLastTx] = useState<Hash>();
  const alice = account?.toLowerCase() === deployment.addresses.operator.toLowerCase();

  const refresh = async (address: Address) => {
    const [eth, avUsd, call] = await Promise.all([
      publicClient.getBalance({ address }),
      publicClient.readContract({ address: deployment.addresses.avUsd, abi: erc20Abi, functionName: "balanceOf", args: [address] }),
      publicClient.readContract({ address: deployment.addresses.optionSeries, abi: erc20Abi, functionName: "balanceOf", args: [address] }),
    ]);
    setBalances({ eth: Number(formatEther(eth)).toFixed(4), avUsd: Number(formatUnits(avUsd, 6)).toFixed(6), call: Number(formatEther(call)).toFixed(4) });
  };

  const connect = async () => {
    const provider = (window as Window & { ethereum?: EIP1193Provider }).ethereum;
    if (!provider) return setError("MetaMask was not detected.");
    setBusy(true); setError("");
    try {
      const wallet = createWalletClient({ chain: baseSepolia, transport: custom(provider) });
      const [selected] = await wallet.requestAddresses();
      try {
        await wallet.switchChain({ id: deployment.chainId });
      } catch {
        await provider.request({
          method: "wallet_addEthereumChain",
          params: [{
            chainId: "0x14a34",
            chainName: "Base Sepolia",
            nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
            rpcUrls: [deployment.rpcUrl],
            blockExplorerUrls: [deployment.explorer],
          }],
        });
        await wallet.switchChain({ id: deployment.chainId });
      }
      const checked = getAddress(selected);
      setAccount(checked);
      await refresh(checked);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Wallet connection failed.");
    } finally { setBusy(false); }
  };

  const transact = async (label: string, send: (wallet: ReturnType<typeof createWalletClient>, owner: Address) => Promise<Hash>) => {
    const provider = (window as Window & { ethereum?: EIP1193Provider }).ethereum;
    if (!provider || !account) return;
    setAction(label); setError(""); setLastTx(undefined);
    try {
      const wallet = createWalletClient({ account, chain: baseSepolia, transport: custom(provider) });
      const hash = await send(wallet, account);
      setLastTx(hash);
      await publicClient.waitForTransactionReceipt({ hash });
      await refresh(account);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : `${label} failed.`);
    } finally { setAction(""); }
  };
  const units = () => parseEther(amount || "0");
  // Deliberately use the injected EIP-1193 provider for this first, simple
  // payable call. It avoids a pre-flight eth_call/eth_estimateGas round trip
  // against a public RPC before MetaMask gets the request.
  const wrapWeth = () => transact("Wrapping ETH", async (_wallet, owner) => {
    const provider = (window as Window & { ethereum?: EIP1193Provider }).ethereum;
    if (!provider) throw new Error("MetaMask was not detected.");
    return provider.request({
      method: "eth_sendTransaction",
      params: [{
        from: owner,
        to: deployment.addresses.weth,
        data: "0xd0e30db0", // WETH9 deposit()
        value: `0x${units().toString(16)}`,
        gas: "0xc350", // 50,000; deposit() estimates at ~28,000 on Base Sepolia
      }],
    }) as Promise<Hash>;
  });
  const watchCall = async () => {
    const provider = (window as Window & { ethereum?: EIP1193Provider }).ethereum;
    if (!provider) return;
    await provider.request({ method: "wallet_watchAsset", params: { type: "ERC20", options: { address: deployment.addresses.optionSeries, symbol: "avWETH-4000-C", decimals: 18 } } });
  };
  const authorizeInventory = () => transact("Authorizing full inventory", async (wallet, owner) => {
    const [virtualCall] = await publicClient.readContract({ address: deployment.addresses.aqua, abi: aquaBalanceAbi, functionName: "safeBalances", args: [deployment.addresses.operator, deployment.addresses.router, deployment.strategyHash, deployment.addresses.optionSeries, deployment.addresses.avUsd] });
    return wallet.writeContract({ account: owner, chain: null, address: deployment.addresses.optionSeries, abi: seriesAbi, functionName: "approve", args: [deployment.addresses.aqua, virtualCall] });
  });

  return <><section className="wallet-panel">
    <div className="wallet-identity">
      <span className="eyebrow">METAMASK</span>
      <strong>{account ? shortAddress(account) : "Wallet not connected"}</strong>
      {account && <small className={alice ? "alice-role" : "trader-role"}>{alice ? "ALICE · OPERATOR" : "TRADER"}</small>}
    </div>
    {account && <><div><small>BASE ETH</small><strong>{balances?.eth ?? "—"}</strong></div><div><small>avUSD</small><strong>{balances?.avUsd ?? "—"}</strong></div><div><small>LIVE CALL</small><strong>{balances?.call ?? "—"}</strong></div></>}
    <button onClick={() => account ? void refresh(account) : void connect()} disabled={busy}>{busy ? "Connecting…" : account ? "↻ Balances" : "Connect MetaMask"}</button>
    {error && <p>{error.length > 90 ? `${error.slice(0, 90)}…` : error}</p>}
  </section>
  {alice && <section className="maker-console">
    <div className="maker-heading"><div><span className="eyebrow">ALICE · MAKER CONSOLE</span><h2>Write and expose covered CALL</h2></div><label>CALL amount<input value={amount} onChange={(event) => setAmount(event.target.value)} type="number" min="0.001" step="0.01"/></label></div>
    <div className="maker-steps">
      <button disabled={!!action} onClick={() => void wrapWeth()}><span>01</span><strong>Wrap ETH</strong><small>ETH → WETH</small></button>
      <button disabled={!!action} onClick={() => void transact("Approving WETH", (wallet, owner) => wallet.writeContract({ account: owner, chain: null, address: deployment.addresses.weth, abi: wethAbi, functionName: "approve", args: [deployment.addresses.optionSeries, units()] }))}><span>02</span><strong>Approve WETH</strong><small>Exact amount</small></button>
      <button disabled={!!action} onClick={() => void transact("Writing CALL", (wallet, owner) => wallet.writeContract({ account: owner, chain: null, address: deployment.addresses.optionSeries, abi: seriesAbi, functionName: "write", args: [units()] }))}><span>03</span><strong>Write CALL</strong><small>Lock WETH + mint</small></button>
      <button disabled={!!action} onClick={() => void watchCall()}><span>04</span><strong>Add to MetaMask</strong><small>Watch ERC-20</small></button>
      <button disabled={!!action} onClick={() => void transact("Approving CALL", (wallet, owner) => wallet.writeContract({ account: owner, chain: null, address: deployment.addresses.optionSeries, abi: seriesAbi, functionName: "approve", args: [deployment.addresses.aqua, units()] }))}><span>05</span><strong>Approve Aqua</strong><small>Exact CALL amount</small></button>
      <button disabled={!!action} onClick={() => void transact("Adding Aqua liquidity", (wallet, owner) => wallet.writeContract({ account: owner, chain: null, address: deployment.addresses.aqua, abi: aquaAbi, functionName: "push", args: [deployment.addresses.operator, deployment.addresses.router, deployment.strategyHash, deployment.addresses.optionSeries, units()] }))}><span>06</span><strong>Push to Aqua</strong><small>Increase virtual CALL</small></button>
      <button disabled={!!action} onClick={() => void authorizeInventory()}><span>07</span><strong>Authorize inventory</strong><small>Full virtual CALL</small></button>
    </div>
    <div className="maker-status"><span>{action || "Execute each numbered transaction in order."}</span>{lastTx && <a href={`${deployment.explorer}/tx/${lastTx}`} target="_blank" rel="noreferrer">View confirmed transaction ↗</a>}</div>
  </section>}
  </>;
}
