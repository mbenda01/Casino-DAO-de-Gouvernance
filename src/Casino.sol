// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importations des dépendances
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./HouseToken.sol";
import "chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title Casino Smart Contract
 * @dev Contrat principal du casino décentralisé avec système de paris et récompenses
 * @notice Permet aux utilisateurs de parier et gagne des tokens HOUSE en bonus
 * Intègre Chainlink VRF pour l'aléatoire vérifiable
 */

contract Casino is VRFConsumerBaseV2, ReentrancyGuard, Pausable, Ownable {
    /// @notice Structure stockant les informations d'un pari
    /// @dev Utilisée pour suivre les paris en attente/résolus

    struct Bet {
        address player;     // Adresse du parieur
        uint256 amount;     // Montant du pari en ETH
        uint8 choice;       // Choix du joueur (0 ou 1)
        bool fulfilled;     // Si le pari a été résolu
    }

    // Événements
    event BetPlaced(uint256 indexed requestId, address indexed player, uint256 amount, uint8 choice);
    event BetResolved(uint256 indexed requestId, address indexed player, bool win, uint256 payout, uint256 bonus);

    // Error 
    error IncorrectChoice();
    error InvalidBetAmount(uint256 min, uint256 max);

    // Configuration Chainlink VRF
    VRFCoordinatorV2Interface public vrfCoordinator;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public constant requestConfirmations = 3;
    uint32 public constant numWords = 1;

    // Token maison et paramètres
    HouseToken public houseToken;
    uint256 public mintRate = 1;    // Taux de bonus en tokens (1%)
    uint256 public minBet = 0.01 ether;
    uint256 public maxBet = 10 ether;

    // Stockage des paris
    mapping(uint256 => Bet) public bets;

    /**
     * @dev Initialise le contrat avec les paramètres Chainlink VRF
     * @param _vrfCoordinator Adresse du coordinateur VRF
     * @param _keyHash Hash de la clé pour la requête aléatoire
     * @param _subscriptionId ID d'abonnement Chainlink
     * @param _houseToken Adresse du token HOUSE
     */

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _houseToken
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        houseToken = HouseToken(_houseToken);
    }

     /*
     * @notice Place un nouveau pari
     * @dev Fonction payable qui initie une requête VRF
     * @param choice Choix du joueur (0 ou 1)
     * @return requestId ID de la requête VRF générée
     */

    function placeBet(uint8 choice) external payable whenNotPaused nonReentrant {
        require(msg.value >= minBet && msg.value <= maxBet, InvalidBetAmount(minBet, maxBet));
        require(choice == 0 || choice == 1, IncorrectChoice());

        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        bets[requestId] = Bet({
            player: msg.sender,
            amount: msg.value,
            choice: choice,
            fulfilled: false
        });

        emit BetPlaced(requestId, msg.sender, msg.value, choice);
    }
    
    /**
     * @dev Callback VRF qui résout les paris
     * @notice Interne - seul le coordinateur VRF peut appeler
     * @param requestId ID de la requête VRF
     * @param randomWords Tableau des valeurs aléatoires générées
     */

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        Bet storage bet = bets[requestId];
        require(!bet.fulfilled, "Already fulfilled");

        if (randomWords[0] % 2 == bet.choice) {
            uint256 payout = bet.amount * 2;
            
            // Modification cruciale ici
            (bool success, ) = bet.player.call{value: payout}("");
            if (!success) {
                revert("Transfer failed"); // Revert explicite
            }
            
            uint256 bonus = (payout * mintRate) / 100;
            houseToken.mint(bet.player, bonus);
        }
        bet.fulfilled = true;
    }

    /**
     * @dev Fonction de test pour simuler la réponse VRF
     * @notice Seul le coordinateur VRF peut appeler cette fonction
     * @param requestId ID de la requête à remplir
     * @param randomWords Valeurs aléatoires à utiliser
     */

    function testFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        require(msg.sender == address(vrfCoordinator), "Only VRF coordinator");
        fulfillRandomWords(requestId, randomWords);
    }

    /**
     * @notice Récupère les détails d'un pari
     * @param requestId ID de la requête VRF associée au pari
     * @return Bet Structure contenant les informations du pari
     */

    function getBet(uint256 requestId) public view returns (Bet memory) {
        return bets[requestId];
    }

    // ========== Fonctions Administratives ==========

    /**
     * @notice Modifie le taux de bonus en tokens
     * @dev Seul le propriétaire peut appeler
     * @param _rate Nouveau taux (en pourcentage)
     */

    function setMintRate(uint256 _rate) external onlyOwner {
        mintRate = _rate;
    }

    /**
     * @notice Modifie les limites de pari
     * @dev Seul le propriétaire peut appeler
     * @param _min Nouveau montant minimum
     * @param _max Nouveau montant maximum
     */
    function setBetLimits(uint256 _min, uint256 _max) external onlyOwner {
        require(_min < _max, "Invalid limits");
        minBet = _min;
        maxBet = _max;
    }

    /**
     * @notice Retire les fonds du contrat
     * @dev Seul le propriétaire peut appeler
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Met en pause les paris
     * @dev Seul le propriétaire peut appeler
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Reprend les paris
     * @dev Seul le propriétaire peut appeler
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Fallback pour recevoir des ETH
     */
    receive() external payable {}
}
