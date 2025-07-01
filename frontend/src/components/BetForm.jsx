import { useState } from 'react';
import { ethers } from 'ethers';
import { contractABI, contractAddress } from '../contracts';

export default function BetForm({ provider, signer, account, onBetPlaced }) {
  //console.log("📦 BetForm mounted");
  const [betAmount, setBetAmount] = useState('');
  const [betChoice, setBetChoice] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [txHash, setTxHash] = useState('');
  const [error, setError] = useState('');

  const handleBet = async (e) => {
    e.preventDefault();
    //console.log("🎯 handleBet called", { betAmount, betChoice, account, signer });
    setIsLoading(true);
    setError('');

    try {
      const casinoContract = new ethers.Contract(
        contractAddress.casino,
        contractABI.casino,
        signer
      );

      const tx = await casinoContract.placeBet(betChoice, {
        value: ethers.parseEther(betAmount)
      });

      await tx.wait();
      setTxHash(tx.hash);
      setBetAmount('');
      setBetChoice(0);

      // 🔁 Rafraîchir les composants
      if (onBetPlaced) onBetPlaced();
    } catch (err) {
      setError(err.message || 'Transaction failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="p-6 border rounded-xl bg-white shadow-md max-w-md mx-auto my-8">
      <h2 className="text-xl font-semibold mb-4">🎯 Place Your Bet</h2>
      {error && <div className="text-red-600 mb-3">{error}</div>}
      {txHash && (
        <div className="text-green-600 mb-3">
          Transaction sent! <a href={`https://goerli.etherscan.io/tx/${txHash}`} target="_blank" rel="noopener noreferrer" className="underline">View on Etherscan</a>
        </div>
      )}
      <form onSubmit={handleBet} className="space-y-4">
        <div>
          <label className="block mb-1">Amount (ETH):</label>
          <input
            type="number"
            step="0.01"
            min="0.01"
            max="10"
            value={betAmount}
            onChange={(e) => setBetAmount(e.target.value)}
            required
            className="w-full border px-3 py-2 rounded"
          />
        </div>
        <div>
          <label className="block mb-1">Choice:</label>
          <div className="flex gap-6">
            <label>
              <input
                type="radio"
                checked={betChoice === 0}
                onChange={() => setBetChoice(0)}
              /> Even
            </label>
            <label>
              <input
                type="radio"
                checked={betChoice === 1}
                onChange={() => setBetChoice(1)}
              /> Odd
            </label>
          </div>
        </div>
        <button
          type="submit"
          disabled={isLoading || !account}
          className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:bg-gray-400"
        >
          {isLoading ? 'Processing...' : 'Place Bet'}
        </button>
      </form>
    </div>
  );
}
