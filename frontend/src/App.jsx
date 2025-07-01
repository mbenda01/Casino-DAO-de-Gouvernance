import { useState } from "react";
import Layout from "./Layout";
import BetForm from "./components/BetForm";
import BetHistory from "./components/BetHistory";
import DaoProposals from "./components/DaoProposals";
import GainDisplay from "./components/GainDisplay";
import StatsDashboard from "./components/StatsDashboard";

function App() {
  console.log("🧩 App component mounted");
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState(null);
  const [refreshFlag, setRefreshFlag] = useState(false);

  const triggerRefresh = () => setRefreshFlag(prev => !prev);

  const commonProps = { provider, signer, account, refreshFlag };

  return (
    <Layout setProvider={setProvider} setSigner={setSigner} setAccount={setAccount}>
      <div className="space-y-10">
        <section id="bet" className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-xl font-semibold mb-4">🎯 Place Your Bet</h3>
          <BetForm {...commonProps} onBetPlaced={triggerRefresh} />
        </section>

        <section id="history" className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-xl font-semibold mb-4">📜 Your Bet History</h3>
          <BetHistory {...commonProps} />
        </section>

        <section id="dao" className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-xl font-semibold mb-4">🏛️ DAO Proposals</h3>
          <DaoProposals {...commonProps} />
        </section>

        <div className="grid md:grid-cols-2 gap-6">
          <section id="gain" className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-xl font-semibold mb-4">💰 Gain & Bonus</h3>
            <GainDisplay {...commonProps} />
          </section>
          <section id="stats" className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-xl font-semibold mb-4">📊 Stats</h3>
            <StatsDashboard {...commonProps} />
          </section>
        </div>
      </div>
    </Layout>
  );
}

export default App;
