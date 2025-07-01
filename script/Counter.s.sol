// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Import des dépendances nécessaires
import {Script} from "forge-std/Script.sol"; // Pour les scripts de déploiement
import {Counter} from "../src/Counter.sol"; // Le contrat à déployer
import {console} from "forge-std/console.sol"; // Pour les logs

/**
 * @title Counter Deployment Script
 * @dev Script Foundry pour déployer le contrat Counter
 * @notice Ce script permet de déployer une instance du contrat Counter
 * et d'afficher son adresse de déploiement
 */

contract CounterScript is Script {
     /// @notice Instance du contrat Counter qui sera déployée
    Counter public counter;

    /*
     * @notice Fonction principale exécutée par le script
     * @dev Déploie une nouvelle instance de Counter et log son adresse
     * @return counter L'instance déployée du contrat Counter
     */

    function run() public {
        // Déploiement du contrat Counter
        counter = new Counter();
        // Affichage de l'adresse de déploiement dans la console
        
        console.log("Counter deployed at:", address(counter));
    }
}