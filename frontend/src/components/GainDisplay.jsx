import { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import { contractAddress, contractABI } from '../contracts';

export default function GainDisplay({ provider, account, refreshFlag }) {
  const [tokenBalance, setTokenBalance] = useState(null);
  const [lastWin, setLastWin] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!provider || !account) return;

    const fetchData = async () => {
      setLoading(true);
      setError('');
      try {
        const tokenContract = new ethers.Contract(
          contractAddress.token,
          contractABI.token,
          provider
        );

        const balance = await tokenContract.balanceOf(account);
        setTokenBalance(ethers.formatUnits(balance, 18));

        const casino = new ethers.Contract(
          contractAddress.casino,
          contractABI.casino,
          provider
        );

        const events = await casino.queryFilter(
          casino.filters.BetResolved(account),
          -1000
        );

        if (events.length > 0) {
          const last = events[events.length - 1];
          setLastWin({
            payout: ethers.formatEther(last.args.payout),
            win: last.args.win,
            block: last.blockNumber
          });
        } else {
          setLastWin(null);
        }
      } catch (err) {
        console.error('Error fetching gain data:', err);
        setError('Failed to load balance or payout info');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [provider, account, refreshFlag]);

  return (
    <div className="bg-white p-6 rounded-xl shadow-md space-y-4">
      <h2 className="text-xl font-semibold text-gray-800">🏆 Your Gains</h2>

      {error && <p className="text-red-500">{error}</p>}
      {loading ? (
        <p>Loading your balance and last result...</p>
      ) : (
        <div className="space-y-2">
          <p><strong>🎯 Token Balance:</strong> {tokenBalance} HT</p>
          {lastWin ? (
            <div className="bg-green-50 p-4 rounded-md border border-green-200">
              <p><strong>Last Bet:</strong> {lastWin.win ? '✅ Won' : '❌ Lost'}</p>
              <p><strong>Payout:</strong> {lastWin.payout} ETH</p>
              <p><strong>Block:</strong> {lastWin.block}</p>
            </div>
          ) : (
            <p>No previous bet resolved found.</p>
          )}
        </div>
      )}
    </div>
  );
}
