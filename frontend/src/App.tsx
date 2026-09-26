import { StrategyBuilder } from "./components/StrategyBuilder";
import { DeploymentContracts, ProtocolProof } from "./components/ProtocolProof";
import { LiveMarketStatus } from "./components/LiveMarketStatus";
import { WalletPanel } from "./components/WalletPanel";
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
        <nav><a href="#strategy">Strategy builder</a><a href="#proof">Onchain proof</a><span className="network"><i />{deployment.network}</span></nav>
      </header>
      <DeploymentContracts />
      <LiveMarketStatus />
      <WalletPanel />
      <StrategyBuilder />
      <ProtocolProof />
      <footer><a className="brand" href="#"><span className="brand-mark">A</span><span>Aqua<strong>Vol</strong></span></a><span>Base Sepolia test assets only · Not production software</span><span>Powered by Aqua + SwapVM</span></footer>
    </div>
  );
}

export default App;
