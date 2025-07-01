import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { contractABI, contractAddress } from '../contracts';

export default function BetHistory({ provider, account, refreshFlag }) {
  const [bets, setBets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!provider || !account) return;

    const fetchBetHistory = async () => {
      setLoading(true);
      setError('');
      try {
        const casinoContract = new ethers.Contract(
          contractAddress.casino,
          contractABI.casino,
          provider
        );

        const betEvents = await casinoContract.queryFilter(
          casinoContract.filters.BetPlaced(account)
        );

        const resolvedBetEvents = await casinoContract.queryFilter(
          casinoContract.filters.BetResolved(account)
        );

        const formattedBets = await Promise.all(betEvents.map(async (event) => {
          const resolvedEvent = resolvedBetEvents.find(
            e => e.args.requestId.toString() === event.args.requestId.toString()
          );

          const block = await event.getBlock();

          return {
            id: event.args.requestId.toString(),
            amount: ethers.formatEther(event.args.amount),
            choice: event.args.choice === 0 ? 'Even' : 'Odd',
            status: resolvedEvent ? (resolvedEvent.args.win ? 'Won' : 'Lost') : 'Pending',
            payout: resolvedEvent ? ethers.formatEther(resolvedEvent.args.payout || 0) : '0',
            timestamp: new Date(block.timestamp * 1000).toLocaleString()
          };
        }));

        setBets(formattedBets);
      } catch (err) {
        console.error(err);
        setError('Failed to load bet history');
      } finally {
        setLoading(false);
      }
    };

    fetchBetHistory();
  }, [provider, account, refreshFlag]);

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h2 className="text-xl font-bold mb-4">📜 Your Bet History</h2>
      {error && <p className="text-red-600">{error}</p>}
      {loading ? (
        <p>Loading...</p>
      ) : bets.length === 0 ? (
        <p>No bets found.</p>
      ) : (
        <table className="w-full border text-sm">
          <thead>
            <tr className="bg-gray-100">
              <th className="border px-2 py-1">Amount</th>
              <th className="border px-2 py-1">Choice</th>
              <th className="border px-2 py-1">Status</th>
              <th className="border px-2 py-1">Payout</th>
              <th className="border px-2 py-1">Date</th>
            </tr>
          </thead>
          <tbody>
            {bets.map(bet => (
              <tr key={bet.id}>
                <td className="border px-2 py-1">{bet.amount}</td>
                <td className="border px-2 py-1">{bet.choice}</td>
                <td className={`border px-2 py-1 ${bet.status === 'Won' ? 'text-green-600' : bet.status === 'Lost' ? 'text-red-600' : 'text-yellow-600'}`}>{bet.status}</td>
                <td className="border px-2 py-1">{bet.payout}</td>
                <td className="border px-2 py-1">{bet.timestamp}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
