import { deployment } from "./data/deployment";

function App() {
  return (
    <main className="foundation-shell">
      <header>
        <a className="brand" href="/" aria-label="AquaVol home">
          <span className="brand-mark">A</span>
          <span>
            Aqua<strong>Vol</strong>
          </span>
        </a>
        <span className="network">
          <i />
          {deployment.network}
        </span>
      </header>
      <section>
        <p>PROGRAMMABLE ONCHAIN OPTIONS</p>
        <h1>
          Strategy workspace
          <br />
          <em>coming into focus.</em>
        </h1>
        <div className="foundation-grid">
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
        </div>
        <small>
          Frontend foundation · strategy builder follows in the next checkpoint
        </small>
      </section>
    </main>
  );
}

export default App;
