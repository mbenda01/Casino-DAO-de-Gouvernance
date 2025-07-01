// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

// Importations des dépendances de test
import "forge-std/Test.sol";
import "../src/Casino.sol";
import "../src/HouseToken.sol";
import "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

/**
 * @title Casino Contract Tests
 * @dev Suite complète de tests pour le contrat Casino
 * @notice Teste toutes les fonctionnalités principales du casino
 */
contract CasinoTest is Test {
    // Instances des contrats
    Casino public casino;
    HouseToken public token;
    VRFCoordinatorV2Mock public vrfMock;

    // Adresses de test
    address public player = address(1);

    // Configuration VRF
    uint64 public subId;
    bytes32 public keyHash = bytes32("0xabc");

    // Constantes de test
    uint256 public constant MINT_RATE = 1; // 1%
    uint256 public constant BET_AMOUNT = 1 ether;


    /**
     * @dev Setup initial avant chaque test
     * - Configure l'environnement de test
     * - Déploie les contrats
     * - Initialise les fonds
     */
    function setUp() public {
        // // 1. Initialisation du joueur
        player = address(1);
        vm.deal(player, 10 ether); // Fund player with ETH

        // 2. Déploiement du token HOUSE
        token = new HouseToken();
        
        // 3. Configuration temporaire du casino
        token.setCasino(address(this));

        // 4.  Configuration Chainlink VRF
        vrfMock = new VRFCoordinatorV2Mock(0.1 ether, 1e9);
        subId = vrfMock.createSubscription();
        vrfMock.fundSubscription(subId, 10 ether);

        // 5. Déploiement du Casino
        casino = new Casino(
            address(vrfMock),
            keyHash,
            subId,
            address(token)
        );

        // 6. Mise à jour permissions
        token.setCasino(address(casino)); // Transfère les droits au vrai casino
        vrfMock.addConsumer(subId, address(casino));

        // 7. Approvisionnement des fonds
        vm.deal(address(casino), 10 ether); // 1. Fond ETH pour payer les gains
        vm.prank(address(casino));          // 2. Simule l'appel par le casino
        token.mint(address(casino), 100 ether); // Fond tokens pour les bonus

        // 8. Paramètres par défaut
        casino.setMintRate(MINT_RATE);
        casino.setBetLimits(0.1 ether, 5 ether);
    }

    // ========== TESTS DES PARIS ==========

    /**
     * @dev Test l'émission de l'événement BetPlaced
     * - Vérifie que l'événement est émis avec les bons paramètres
     */

    function testPlaceBetEmitsEvent() public {
        vm.prank(player);
        
        // Vérifier l'event complet avec tous les paramètres
        vm.expectEmit(true, true, true, true);
        emit Casino.BetPlaced(
            1,            
            player,
            BET_AMOUNT,
            1             
        );
        
        casino.placeBet{value: BET_AMOUNT}(1);
    }


     /**
     * @dev Test un pari trop faible
     * - Vérifie le rejet avec le bon message d'erreur
     */
    function testPlaceBetTooLow() public {
        vm.prank(player);
        vm.expectRevert("Invalid bet amount");
        casino.placeBet{value: 0.001 ether}(0);
    }


     /**
     * @dev Test un pari trop élevé
     * - Vérifie les limites de pari
     * - Test aussi le cas sans assez de fonds
     */
    function testPlaceBetTooHigh() public {
        casino.setBetLimits(0.1 ether, 5 ether);
        
        vm.deal(player, 100 ether);
        
        vm.prank(player);
        vm.expectRevert("Invalid bet amount");
        casino.placeBet{value: 5.1 ether}(0); // Juste au-dessus de maxBet
        
        // 4. Tester aussi le cas où le joueur n'a pas assez
        vm.prank(player);
        vm.expectRevert(); // Peut être "Invalid bet amount" ou "Insufficient funds"
        casino.placeBet{value: 100 ether}(0);
    }


    // ========== TESTS VRF ==========

    /**
     * @dev Test la résolution d'un pari gagnant
     * - Vérifie le paiement ETH
     * - Vérifie le bonus en tokens
     */
    function testFulfillRandomWords_PlayerWins() public {
        // 1. Setup
        vm.deal(address(casino), 100 ether);
        vm.prank(address(casino));
        token.mint(address(casino), 1000 ether);

        uint256 betAmount = 0.1 ether;
        vm.deal(player, 10 ether);
        vm.prank(player);
        casino.placeBet{value: betAmount}(0);

        uint256 requestId = 1;

        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0; // Force win

        vm.prank(address(vrfMock));
        casino.testFulfillRandomWords(requestId, randomWords);

        uint256 expectedBonus = (betAmount * 2 * MINT_RATE) / 100;
        assertEq(token.balanceOf(player), expectedBonus, "Bonus tokens not minted correctly");
        assertEq(player.balance, 10 ether - betAmount + (betAmount * 2), "ETH balance incorrect");
    }


    /**
     * @dev Test la résolution d'un pari perdant
     * - Vérifie qu'aucun paiement n'est effectué
     */
    function testFulfillRandomWords_PlayerLoses() public {
        // 1. Placer le pari
        vm.prank(player);
        casino.placeBet{value: BET_AMOUNT}(0);
        
        // 2. Simuler la réponse VRF
        uint256 requestId = 1;
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 1; // Nombre aléatoire = 1 (impair = perte)
        
        // 3. Appeler la fonction via le mock
        vm.prank(address(vrfMock));
        casino.rawFulfillRandomWords(requestId, randomWords);
        
        // 4. Vérifications
        assertEq(player.balance, 9 ether, "Should lose 1 ETH");
        assertEq(token.balanceOf(player), 0, "No tokens on loss");
    }

    // ========== TESTS ADMIN ==========

    /**
     * @dev Test la modification du taux de bonus
     */
    function testSetMintRate() public {
        casino.setMintRate(5);
        assertEq(casino.mintRate(), 5);
    }

    /**
     * @dev Test la modification des limites de pari
     */
    function testSetBetLimits() public {
        casino.setBetLimits(0.1 ether, 5 ether);
        assertEq(casino.minBet(), 0.1 ether);
        assertEq(casino.maxBet(), 5 ether);
    }

    /**
     * @dev Test les fonctionnalités de pause
     * - Vérifie que les paris sont bloqués quand pause
     * - Vérifie que les paris reprennent après unpause
     */
    function testPauseUnpause() public {
        casino.pause();
        vm.prank(player);
        vm.expectRevert("Pausable: paused");
        casino.placeBet{value: BET_AMOUNT}(0);

        casino.unpause();
        vm.prank(player);
        casino.placeBet{value: BET_AMOUNT}(0); // Should work
    }
    
    /**
     * @dev Test la réception de fonds
     * - Vérifie que le contrat peut recevoir des ETH
     */
    function testReceiveFunction() public {
        uint256 initialBalance = address(casino).balance;
        (bool success,) = address(casino).call{value: 1 ether}("");
        require(success, "Transfer failed");
        assertEq(address(casino).balance, initialBalance + 1 ether, "ETH not received");
    }


}