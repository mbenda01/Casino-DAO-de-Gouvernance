import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { contractABI, contractAddress } from '../contracts';

export default function StatsDashboard({ provider, account, refreshFlag }) {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!provider || !account) return;

    const fetchStats = async () => {
      setLoading(true);
      setError('');
      try {
        const casino = new ethers.Contract(
          contractAddress.casino,
          contractABI.casino,
          provider
        );

        const placed = await casino.queryFilter(casino.filters.BetPlaced(account));
        const resolved = await casino.queryFilter(casino.filters.BetResolved(account));

        let totalBets = placed.length;
        let wins = 0;
        let losses = 0;
        let totalWon = ethers.toBigInt(0);

        resolved.forEach(event => {
          if (event.args.win) {
            wins++;
            totalWon += event.args.payout;
          } else {
            losses++;
          }
        });

        const ratio = totalBets > 0 ? ((wins / totalBets) * 100).toFixed(1) : 0;

        setStats({
          totalBets,
          wins,
          losses,
          totalWon: ethers.formatEther(totalWon),
          ratio
        });
      } catch (err) {
        console.error('Error loading stats:', err);
        setError('Failed to load stats');
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, [provider, account, refreshFlag]);

  return (
    <div className="bg-white rounded-xl shadow-md p-6 mt-6 space-y-4">
      <h2 className="text-xl font-semibold text-gray-800">📊 Your Stats</h2>
      {error && <p className="text-red-500">{error}</p>}
      {loading || !stats ? (
        <p>Loading stats...</p>
      ) : (
        <div className="grid grid-cols-2 gap-4 text-gray-700">
          <div>
            <p className="font-semibold">Total Bets:</p>
            <p>{stats.totalBets}</p>
          </div>
          <div>
            <p className="font-semibold">Wins:</p>
            <p>{stats.wins}</p>
          </div>
          <div>
            <p className="font-semibold">Losses:</p>
            <p>{stats.losses}</p>
          </div>
          <div>
            <p className="font-semibold">Total ETH Won:</p>
            <p>{stats.totalWon} ETH</p>
          </div>
          <div className="col-span-2">
            <p className="font-semibold">Win Rate:</p>
            <div className="w-full bg-gray-200 rounded-full h-4">
              <div
                className="bg-green-500 h-4 rounded-full"
                style={{ width: `${stats.ratio}%` }}
              ></div>
            </div>
            <p className="text-sm mt-1">{stats.ratio}%</p>
          </div>
        </div>
      )}
    </div>
  );
}
