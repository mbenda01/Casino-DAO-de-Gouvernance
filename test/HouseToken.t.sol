// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/HouseToken.sol";

error OwnableUnauthorizedAccount(address);

/**
 * @title HouseToken Test Suite
 * @dev Tests complets pour le token de gouvernance HOUSE
 * @notice Vérifie toutes les fonctionnalités du token incluant :
 * - Le contrôle d'accès et les permissions
 * - Les fonctionnalités de minting et burning
 * - Le système de votes et délégation
 */
contract TestHouseToken is Test {

     // Instances et adresses de test
    HouseToken public token;
    address public owner;
    address public casino;
    address public user;

    /**
     * @dev Setup initial avant chaque test
     * @notice Déploie une nouvelle instance de HouseToken
     * et initialise les adresses de test
     */
    function setUp() public {
        owner = address(this);  // Le contrat de test est le owner initial
        casino = address(1);    // Adresse simulée du casino
        user = address(2);      // Adresse simulée d'un utilisateur

        token = new HouseToken();
    }


    // ========== TESTS DES VALEURS INITIALES ==========

    /**
     * @dev Test les valeurs initiales du token
     * @notice Vérifie que le token est correctement initialisé
     */
    function testInitialValues() public view {
        assertEq(token.name(), "HouseToken");
        assertEq(token.symbol(), "HOUSE");
        assertEq(token.totalSupply(), 0);
    }


    // ========== TESTS DES PERMISSIONS ==========

    /**
     * @dev Test les permissions du owner
     * @notice Vérifie que seul le owner peut configurer l'adresse du casino
     */
    function testOnlyOwnerCanSetCasino() public {
        // 1. Test que le owner peut modifier l'adresse
        address newCasino = address(123);
        token.setCasino(newCasino);
        assertEq(token.casino(), newCasino);

        // 2. Test qu'un non-owner ne peut pas modifier
        address attacker = address(666);
        vm.prank(attacker);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.setCasino(attacker);

         // 3. Vérifie que l'adresse n'a pas changé
        assertEq(token.casino(), newCasino);
    }

    /**
     * @dev Test la protection contre l'adresse zéro
     * @notice Vérifie qu'on ne peut pas configurer une adresse de casino invalide
     */
    function testCannotSetCasinoToZero() public {
        vm.expectRevert(bytes("Invalid casino address"));
        token.setCasino(address(0));
    }

    // ========== TESTS DES FONCTIONS DE MINT ==========

    /**
     * @dev Test les permissions de mint
     * @notice Vérifie que seul le casino peut mint des tokens
     */
    function testOnlyCasinoCanMint() public {
        token.setCasino(casino);

        // Test qu'un utilisateur normal ne peut pas mint
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(HouseToken.NotCasino.selector)
        );
        token.mint(user, 100 ether);

        // Test que le casino peut mint correctement
        vm.prank(casino);
        vm.expectEmit(true, true, false, true);
        emit HouseToken.TokenMinted(user, 100 ether);
        token.mint(user, 100 ether);

        // Vérifications finales
        assertEq(token.balanceOf(user), 100 ether);
        assertEq(token.totalSupply(), 100 ether);
    }


    
    // ========== TESTS DES FONCTIONNALITÉS DE VOTE ==========

    /**
     * @dev Test l'impact des transferts sur le voting power
     * @notice Vérifie que le pouvoir de vote est correctement mis à jour
     */
    function testTokenTransfersAffectVotingPower() public {
        token.setCasino(casino);
        vm.prank(casino);
        token.mint(user, 100 ether);
        
        uint256 initialVotes = token.getVotes(user);
        // Vérifie l'initialisation
        assertEq(initialVotes, 0, "Initial votes should be 0");
        
        // Délégation
        vm.prank(user);
        token.delegate(user);
        assertEq(token.getVotes(user), 100 ether, "Voting power should match balance");
        
        // Transfert et vérification
        vm.prank(user);
        token.transfer(address(3), 50 ether);
        assertEq(token.getVotes(user), 50 ether, "Voting power should update after transfer");
    }


     // ========== TESTS DES FONCTIONS OVERRIDE ==========

    /**
     * @dev Test les fonctions override
     * @notice Vérifie que les fonctions surchargées fonctionnent correctement
     */
    function testOverrideFunctions() public {
        token.setCasino(casino);
        
        // Test _mint override
        vm.prank(casino);
        token.mint(user, 100 ether);
        assertEq(token.balanceOf(user), 100 ether);
        
        // Test _burn override via burnFrom
        vm.prank(user);
        token.approve(address(this), 100 ether);
        token.burnFrom(user, 50 ether);
        assertEq(token.balanceOf(user), 50 ether);
    }
}
