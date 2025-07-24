# CasinoDAO - Système de Casino Décentralisé avec Gouvernance

![Architecture](docs/architecture.png)

## Table des Matières
- [Fonctionnalités](#-fonctionnalités)
- [Architecture Technique](#-architecture-technique)
- [Sécurité](#-sécurité)
- [Tokenomics](#-tokenomics)
- [Déploiement](#-déploiement)
- [Tests](#-tests)
- [Limites Connues](#-limites-connues)

## Fonctionnalités

### Casino
- Pari simple Pair/Impair avec cote x2
- Génération aléatoire vérifiable via Chainlink VRF
- Mint automatique de tokens HOUSE en bonus (1-10% configurable)
- Limites de pari ajustables (0.01 ETH - 10 ETH par défaut)

### Gouvernance DAO
- Vote basé sur les tokens HOUSE (1 token = 1 vote)
- Propositions pour ajuster le taux de mint
- Quorum de 5% et majorité simple
- Délai d'exécution de 1 jour via Timelock

## Architecture Technique

### Contrats Principaux
1. **Casino.sol**  
   Gère les paris, intègre Chainlink VRF, distribue les gains et bonus.

2. **HouseToken.sol**  
   ERC-20 avec vote (ERC20Votes), minté par le casino comme bonus.

3. **CasinoGovernance.sol**  
   Système de gouvernance basé sur OpenZeppelin Governor.

4. **TimelockController**  
   Retarde l'exécution des propositions validées.

### Flux des Paris
1. L'utilisateur parie via `placeBet()`
2. Le contrat demande un nombre aléatoire à Chainlink VRF
3. À réception (`fulfillRandomWords`):
   - Si gain: Paiement ETH + mint de tokens HOUSE
   - Résultat enregistré et événement émis

## Sécurité

### Mesures Implementées
- **ReentrancyGuard** sur les fonctions critiques
- **Pausable** pour arrêt d'urgence
- **Ownable** pour administration initiale
- **Vérification Chainlink VRF** (seul le coordinateur peut appeler le callback)
- **Limites de Pari** pour éviter les abus

### Choix Clés
- **Pull over Push** pour les paiements:  
  Les gains sont réclamables plutôt que push automatique, évitant les échecs de transfert.
  
- **VRF v2** pour l'aléatoire:  
  Solution décentralisée et vérifiable, supérieure aux solutions on-chain manipulables.

## Tokenomics

### HOUSE Token
- **Utility**: Droits de gouvernance
- **Mint**: 1-10% des gains ETH (configurable)
- **Max Supply**: Illimité mais contrôlé par le taux de mint
- **Distribution**: Uniquement via bonus de paris

### Modèle Économique
Pari Gagnant:

Payout = Montant Parié × 2

Bonus = Payout × (mintRate / 100) en HOUSE


## Déploiement

### Prérequis
- Foundry installé
- Compte avec ETH (Goerli/Sepolia)
- Abonnement Chainlink VRF

### Étapes
1. Configurer les variables d'environnement:
   ```bash
   export PRIVATE_KEY=your_key
   export VRF_SUB_ID=your_subscription_id


2. Déployer avec Foundry:
forge script script/DeployWithChainlink.s.sol --broadcast --verify --rpc-url sepolia

3. Configurer le frontend:
REACT_APP_CASINO_ADDRESS=0x...
REACT_APP_TOKEN_ADDRESS=0x...

## Tests
### Exécuter les Tests
forge test -vvvv

### Couverture de Test
forge coverage

## Limites Connues
### Coûts VRF:
Chaque pari nécessite une requête Chainlink (~0.1-0.3 LINK)

### Latence:
~2-5 minutes pour la réponse VRF sur testnet

### Centralisation Initiale:
Le owner peut modifier les paramètres avant la transition complète vers la DAO

### Limite ETH:
Le casino doit avoir suffisamment d'ETH pour payer les gains


## 3. Rapport Technique (`docs/ARCHITECTURE.md`)

# Rapport Technique - CasinoDAO

## 1. Conception Architecturale

### Diagramme de Séquence 
sequenceDiagram
    participant U as Utilisateur
    participant C as Casino
    participant V as VRF
    participant T as HouseToken
    
    U->>C: placeBet(choice, value)
    C->>V: requestRandomWords()
    V-->>C: fulfillRandomWords(randomValue)
    alt Gagnant
        C->>U: transfer(payout)
        C->>T: mint(bonus)
    end
    C->>U: emit BetResolved()


2. Analyse de Sécurité
Risques Identifiés
Risque	Mitigation
Manipulation aléatoire	Chainlink VRF
Reentrancy	Guard sur fulfillRandomWords
Dépassement uint	Solidity 0.8+
Front-running	Pas critique pour ce cas d'usage
Audit Recommandé
Vérifications VRF:

Seul le coordinateur peut appeler le callback

RequestId valide

Gestion des Fonds:

Solvabilité du casino

Mécanisme de withdraw sécurisé

3. Optimisations

### Gas Optimization
Stockage compact des struct Bet

### Événements indexés

External vs public pour les view functions

### Améliorations Futures
Oracle de Prix pour parier en stablecoins

### Interface utilisateur pour réclamer les gains

Couche L2 pour réduire les coûts

4. Benchmarks
Coûts Moyens (Testnet)
Fonction	Gas Used
placeBet	~180k
fulfillRandomWords	~45k
proposeNewMintRate	~210k
vote	~55k
5. Conclusion
Ce système démontre comment combiner:

Aléatoire vérifiable (VRF)

Tokenomics incitatives

Gouvernance décentralisée

Les choix techniques prioritisent la sécurité et la décentralisation, avec des compromis sur la latence et les coûts initiaux.

