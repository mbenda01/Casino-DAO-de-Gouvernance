import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { contractABI, contractAddress } from '../contracts';

export default function DaoProposals({ provider, signer, account }) {
  const [proposals, setProposals] = useState([]);
  const [newRate, setNewRate] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    if (!provider || !account) return;

    const fetchProposals = async () => {
      try {
        const governance = new ethers.Contract(
          contractAddress.governance,
          contractABI.governance,
          provider
        );

        const count = await governance.proposalCount();
        const list = [];

        for (let i = 0; i < count; i++) {
          const p = await governance.proposals(i);
          const status = await governance.state(i);
          list.push({
            id: i,
            description: p.description,
            mintRate: p.mintRate,
            status,
            forVotes: ethers.utils.formatEther(p.forVotes),
            againstVotes: ethers.utils.formatEther(p.againstVotes)
          });
        }

        setProposals(list);
      } catch (err) {
        setError('Error loading proposals');
      }
    };

    fetchProposals();
  }, [provider, account]);

  const createProposal = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const governance = new ethers.Contract(
        contractAddress.governance,
        contractABI.governance,
        signer
      );

      const tx = await governance.proposeNewMintRate(newRate);
      await tx.wait();

      setSuccess('Proposal created!');
      setNewRate('');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const vote = async (id, support) => {
    try {
      const governance = new ethers.Contract(
        contractAddress.governance,
        contractABI.governance,
        signer
      );
      const tx = await governance.castVote(id, support);
      await tx.wait();
      setSuccess(`Voted on proposal ${id}`);
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-6">
      <h2 className="text-xl font-bold mb-4">🗳️ DAO Proposals</h2>
      {error && <p className="text-red-600">{error}</p>}
      {success && <p className="text-green-600">{success}</p>}

      <form onSubmit={createProposal} className="mb-6">
        <label className="block mb-1">New Mint Rate (%):</label>
        <input
          type="number"
          value={newRate}
          onChange={(e) => setNewRate(e.target.value)}
          className="border px-3 py-2 mr-3 rounded"
        />
        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded">Create</button>
      </form>

      <div className="grid gap-4">
        {proposals.map(p => (
          <div key={p.id} className="border p-4 rounded bg-white shadow">
            <h3 className="font-semibold">#{p.id} - {p.description}</h3>
            <p>Status: {p.status}</p>
            <p>Mint Rate: {p.mintRate}%</p>
            <p>Votes For: {p.forVotes} | Against: {p.againstVotes}</p>
            {p.status === 1 && (
              <div className="mt-2 space-x-2">
                <button onClick={() => vote(p.id, 1)} className="bg-green-600 text-white px-3 py-1 rounded">Vote For</button>
                <button onClick={() => vote(p.id, 0)} className="bg-red-600 text-white px-3 py-1 rounded">Vote Against</button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
