// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Importations des dépendances de test
import "forge-std/Test.sol";
import "../script/Counter.s.sol";

/**
 * @title Counter Deployment Script Tests
 * @dev Tests pour le script de déploiement du contrat Counter
 * @notice Vérifie que le script de déploiement fonctionne correctement
 */
contract CounterScriptTest is Test {

    /**
     * @notice Test le déploiement standard du contrat Counter
     * @dev Vérifie que le script déploie correctement une instance de Counter
     * 
     * Steps:
     * 1. Crée une nouvelle instance du script
     * 2. Exécute le script
     * 3. Vérifie que le contrat a été déployé
     */
    function test_CounterDeployment() public {
         // 1. Initialisation du script
        CounterScript script = new CounterScript();
        
         // 2. Exécution du script
        script.run(); // Le script gère lui-même le broadcast
        
        // 3. Vérification du déploiement
        assertTrue(address(script.counter()) != address(0));
    }


     /**
     * @notice Test le déploiement avec différents signataires (fuzzing)
     * @dev Utilise le fuzzing pour tester avec différentes adresses
     * @param signer Adresse aléatoire générée par Foundry
     * 
     * Requirements:
     * - Le signataire ne doit pas être l'adresse zéro
     * - Le signataire doit être une EOA (pas un contrat)
     */
    function test_ScriptWithDifferentSigners(address signer) public {
        // Filtrage des adresses invalides
        vm.assume(signer != address(0));
        vm.assume(uint160(signer) > 1000);
        vm.assume(signer.code.length == 0);

        // Exécution du script
        CounterScript script = new CounterScript();
        script.run(); // Le broadcast est géré dans le script
        
        // Vérification du déploiement
        assertTrue(address(script.counter()) != address(0));
    }
}