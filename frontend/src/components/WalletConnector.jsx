import { useState, useEffect } from 'react';
//import { ethers } from 'ethers';
import { BrowserProvider } from 'ethers';


export default function WalletConnector({ setProvider, setSigner, setAccount }) {
  const [error, setError] = useState('');

  const connectWallet = async () => {
    setError('');
    try {
      if (!window.ethereum) throw new Error('Please install Metamask');

      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      //const provider = new ethers.providers.Web3Provider(window.ethereum);
      const provider = new BrowserProvider(window.ethereum);

      //const signer = provider.getSigner();
      const signer = await provider.getSigner();
      setProvider(provider);
      setSigner(signer);
      setAccount(accounts[0]);

      window.ethereum.on('accountsChanged', accounts => setAccount(accounts[0]));
      window.ethereum.on('chainChanged', () => window.location.reload());
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="fixed top-4 right-4 z-50">
      <button onClick={connectWallet} className="bg-purple-600 text-white px-4 py-2 rounded">
        Connect Wallet
      </button>
      {error && <p className="text-red-600 mt-2">{error}</p>}
    </div>
  );
}
