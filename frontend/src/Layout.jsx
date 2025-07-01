// src/Layout.jsx
import WalletConnector from "./components/WalletConnector";
import {
  HomeIcon,
  HistoryIcon,
  LandmarkIcon,
  BanknoteIcon,
  BarChartIcon,
} from "lucide-react";

const navItems = [
  { id: "bet", name: "Pari", icon: <HomeIcon size={18} /> },
  { id: "history", name: "Historique", icon: <HistoryIcon size={18} /> },
  { id: "dao", name: "DAO", icon: <LandmarkIcon size={18} /> },
  { id: "gain", name: "Gains", icon: <BanknoteIcon size={18} /> },
  { id: "stats", name: "Statistiques", icon: <BarChartIcon size={18} /> },
];

export default function Layout({ children }) {
  return (
    <div className="flex h-screen overflow-hidden">
      {/* Sidebar fixée à gauche */}
      <aside className="w-64 bg-white shadow-lg border-r fixed top-0 left-0 h-full z-40 flex flex-col justify-between">
        <div className="p-6">
          <h1 className="text-2xl font-bold text-purple-600 mb-6">🎰 Casino DAO</h1>
          <nav className="space-y-2">
            {navItems.map((item) => (
              <a
                key={item.id}
                href={`#${item.id}`}
                className="flex items-center gap-2 px-4 py-2 text-gray-700 hover:bg-purple-100 rounded transition"
              >
                {item.icon}
                {item.name}
              </a>
            ))}
          </nav>
        </div>
        <div className="p-4 text-sm text-gray-400 border-t">
          © 2025 Casino DAO
        </div>
      </aside>

      {/* Contenu principal décalé */}
      <main className="ml-64 flex-1 bg-gray-100 p-8 overflow-y-auto h-screen">
        <div className="flex justify-end mb-6">
          <WalletConnector />
        </div>
        {children}
      </main>
    </div>
  );
}
