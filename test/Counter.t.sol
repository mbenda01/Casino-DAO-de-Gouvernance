// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Importations des dépendances de test
import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

/**
 * @title Counter Contract Tests
 * @dev Suite de tests pour le contrat Counter
 * @notice Teste toutes les fonctionnalités du contrat Counter
 */
contract CounterTest is Test {
    /// @notice Instance du contrat Counter à tester
    Counter public counter;

    /**
     * @dev Setup initial avant chaque test
     * @notice Déploie une nouvelle instance de Counter avant chaque test
     */
    function setUp() public {
        counter = new Counter();
    }


    // ========== TESTS DES VALEURS INITIALES ==========

    /**
     * @dev Test la valeur initiale du compteur
     * @notice Vérifie que le compteur est initialisé à 0
     */
    function test_InitialNumberIsZero() public view {
        assertEq(counter.number(), 0);
    }

    // ========== TESTS DES FONCTIONNALITÉS ==========

    /**
     * @dev Test la fonction d'incrémentation
     * @notice Vérifie que l'incrément fonctionne correctement
     * - Test un premier incrément
     * - Test un second incrément
     */
    function test_Increment() public {
        // Premier incrément
        counter.increment();
        assertEq(counter.number(), 1);
        
        // Second incrément
        counter.increment();
        assertEq(counter.number(), 2);
    }

    /*
     * @dev Test la fonction setNumber
     * @notice Vérifie qu'on peut définir une valeur spécifique
     * @param value Valeur spécifique à tester (42 dans ce cas)
     */
    function test_SetNumber() public {
        counter.setNumber(42);
        assertEq(counter.number(), 42);
    }

     // ========== TESTS FUZZING ==========

    /**
     * @dev Test fuzzing de setNumber
     * @notice Test aléatoire avec différentes valeurs
     * @param x Valeur aléatoire générée par Foundry
     */
    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}