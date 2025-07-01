import CasinoABI from './abi/Casino.json';
import GovernanceABI from './abi/Governance.json';
import HouseTokenABI from './abi/HouseToken.json';

export const contractAddress = {
  casino: '0xf9c9eEb3C57Af50436a1F26B186E45aFB6a01845',
  governance: '0x9c96f397AF99891a0Ab1B6A7d48602EfD75850Bd',
  token: '0x7C13805C177c62b0520F24d657eDE884e274cb9b'
};

export const contractABI = {
  casino: CasinoABI.abi,
  governance: GovernanceABI.abi,
  token: HouseTokenABI.abi
};
