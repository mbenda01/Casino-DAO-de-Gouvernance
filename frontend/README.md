# Casino DAO

Un jeu de casino décentralisé avec DAO de gouvernance, jeton ERC20, intégration Chainlink VRF, et interface React/Tailwind.

## Objectif
Les joueurs parient des ETH. En cas de victoire (via un tirage aléatoire Chainlink VRF), ils reçoivent :
- un gain doublé,
- des jetons de gouvernance (HouseToken),
qu'ils peuvent utiliser pour participer à la DAO et proposer/voter des modifications.

---

## Architecture

### Smart Contracts
- `Casino.sol`: gestion des paris + intégration Chainlink VRF.
- `HouseToken.sol`: jeton ERC20 avec gouvernance (ERC20Votes).
- `CasinoGovernance.sol`: système de vote décentralisé.
- `TimelockController.sol`: exécution différée des décisions DAO.

### Déploiement (Foundry)
- `DeployCasino.s.sol`: déploiement de base.
- `DeployFullSystem.s.sol`: déploiement complet avec DAO + Timelock.

### Frontend (React)
- WalletConnector
- BetForm, GainDisplay, BetHistory
- DaoProposals
- StatsDashboard

---

## Sécurité
- ✅ Chainlink VRF pour l'aléatoire vérifiable.
- ✅ `call` sécurisé pour les paiements.
- ✅ Pausable, Ownable, TimelockController.
- ✅ DAO pour contrôler les paramètres critiques.

---

## Tokenomics
- Jeton : `HouseToken` (ERC20Votes)
- Mint : automatique par `Casino.sol` (1% des gains)
- Utilisation : droit de vote (DAO)
- Modifiable : taux ajustable via DAO

---

## Test Coverage

✅ Couverture globale : supérieure à 90%
L’essentiel de la logique métier est testé à 100%. Seul le script de déploiement complet (DeployFullSystem.s.sol) reste à finaliser pour atteindre 100% total.

---

##  Commandes

```bash
# Lancer les tests
forge test

# Déploiement local
anvil
forge script script/DeployFullSystem.s.sol:DeployFullSystem --broadcast --rpc-url http://localhost:8545

# Lancer le frontend
cd frontend
npm install
npm run dev
