import { StrategyBuilder } from "./components/StrategyBuilder";
import { deployment } from "./data/deployment";

function App() {
  return (
    <div className="app-shell">
      <header className="topbar">
        <a className="brand" href="/" aria-label="AquaVol home">
          <span className="brand-mark">A</span>
          <span>
            Aqua<strong>Vol</strong>
          </span>
        </a>
        <nav><a href="#strategy">Strategy builder</a><span className="network"><i />{deployment.network}</span></nav>
      </header>
      <section className="hero">
        <p className="eyebrow">PROGRAMMABLE ONCHAIN OPTIONS</p>
        <h1>
          Options liquidity,
          <br />
          <em>made programmable.</em>
        </h1>
        <p className="hero-copy">Explore multi-leg WETH strategies while keeping the deployed Aqua position visibly separate from local simulations.</p>
        <div className="foundation-grid market-grid">
          <article>
            <span>WETH TWAP</span>
            <strong>
              ${deployment.spot.toLocaleString(undefined, {
                maximumFractionDigits: 2,
              })}
            </strong>
          </article>
          <article>
            <span>LIVE STRIKE</span>
            <strong>${deployment.liveStrike.toLocaleString()}</strong>
          </article>
          <article>
            <span>IMPLIED VOL</span>
            <strong>{deployment.volatility * 100}%</strong>
          </article>
          <article><span>NEXT ASK / 0.01</span><strong>{deployment.lastAsk} avUSD</strong></article>
        </div>
      </section>
      <StrategyBuilder />
      <footer><span>AquaVol · Base Sepolia experimental software</span><span>Live series and simulations are explicitly labelled</span></footer>
    </div>
  );
}

export default App;
