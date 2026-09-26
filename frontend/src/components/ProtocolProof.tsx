import { deployment, shortAddress } from "../data/deployment";

const flow = [
  { id: "01", name: "Uniswap V3", detail: "30-minute WETH / avUSD TWAP", tag: "SPOT INPUT" },
  { id: "02", name: "Black–Scholes", detail: "Volatility-aware fair value", tag: "PRICING ENGINE" },
  { id: "03", name: "Custom SwapVM", detail: "Inventory-skewed executable ask", tag: "OPCODES D1 · D2" },
  { id: "04", name: "Aqua", detail: "Self-custodial token settlement", tag: "LIQUIDITY LAYER" },
];

const contracts = [
  ["Aqua", deployment.addresses.aqua],
  ["Modified SwapVM router", deployment.addresses.router],
  ["Pricing engine", deployment.addresses.pricing],
  ["Uniswap TWAP oracle", deployment.addresses.oracle],
  ["WETH 4,000 CALL", deployment.addresses.optionSeries],
  ["Uniswap V3 pool", deployment.addresses.pool],
] as const;

export function ProtocolProof() {
  const repricing = (deployment.lastAsk / deployment.settledAsk - 1) * 100;
  return <section className="proof-section" id="proof">
    <div className="proof-intro">
      <span className="eyebrow">ONCHAIN PROOF</span>
      <h2>One trade.<br/><em>Four verifiable layers.</em></h2>
      <p>The live market is backed by a distinct-trader Base Sepolia transaction, with token transfers and Aqua virtual balances reconciled.</p>
    </div>

    <div className="flow-grid">
      {flow.map((step, index) => <article className="flow-card" key={step.id}>
        <div><span>{step.id}</span><small>{step.tag}</small></div>
        <h3>{step.name}</h3><p>{step.detail}</p>
        {index < flow.length - 1 && <b aria-hidden="true">→</b>}
      </article>)}
    </div>

    <div className="evidence-grid">
      <article className="trade-card">
        <div className="evidence-title"><span className="live-badge">SETTLED ONCHAIN</span><span>BASE SEPOLIA · 84532</span></div>
        <h3>0.01 CALL purchased</h3>
        <div className="trade-value">{deployment.settledAsk}<small> avUSD paid</small></div>
        <div className="reprice-row">
          <div><small>SETTLED ASK</small><strong>{deployment.settledAsk}</strong></div>
          <span>→</span>
          <div><small>NEXT ASK</small><strong>{deployment.lastAsk}</strong></div>
          <em>+{repricing.toFixed(2)}%</em>
        </div>
        <p>CALL inventory fell while quote inventory increased. The same immutable strategy then returned a higher ask.</p>
        <a className="evidence-link" href={`${deployment.explorer}/tx/${deployment.tradeTx}`} target="_blank" rel="noreferrer">Inspect public trade on BaseScan <span>↗</span></a>
      </article>

      <article className="balance-card">
        <div className="panel-heading"><div><span className="eyebrow">STATE TRANSITION</span><h2>Aqua virtual balances</h2></div><span className="proof-pill">RECONCILED</span></div>
        <div className="balance-head"><span>ASSET</span><span>BEFORE</span><span>AFTER</span><span>CHANGE</span></div>
        <div className="balance-row"><strong>CALL</strong><span>0.10</span><span>0.09</span><em className="down">−0.01</em></div>
        <div className="balance-row"><strong>avUSD</strong><span>50.000000</span><span>50.779818</span><em className="up">+0.779818</em></div>
        <div className="balance-row"><strong>WETH collateral</strong><span>0.10</span><span>0.10</span><em>UNCHANGED</em></div>
        <p className="panel-note">OptionSeries collateral remains equal to outstanding CALL supply after settlement.</p>
      </article>
    </div>

    <article className="contracts-panel panel">
      <div className="panel-heading"><div><span className="eyebrow">PUBLIC DEPLOYMENT</span><h2>Contracts judges can verify</h2></div><span className="network"><i/>Base Sepolia</span></div>
      <div className="contract-grid">{contracts.map(([name, address]) =>
        <a href={`${deployment.explorer}/address/${address}`} target="_blank" rel="noreferrer" key={name}>
          <span>{name}</span><strong>{shortAddress(address)}</strong><b>↗</b>
        </a>)}</div>
    </article>
  </section>;
}
