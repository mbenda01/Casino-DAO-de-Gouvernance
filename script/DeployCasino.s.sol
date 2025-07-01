// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Casino} from "../src/Casino.sol";
import {HouseToken} from "../src/HouseToken.sol";


/**
 * @title DeployCasino
 * @dev Script de déploiement pour le contrat Casino et son token associé
 * @notice Ce script est utilisé pour déployer les contrats Casino et HouseToken
 * et configurer leurs interdépendances
 */
contract DeployCasino is Script {
    /// @notice Instance du token HouseToken
    HouseToken public token;

    /// @notice Instance du contrat Casino
    Casino public casino;


    /*
     * @dev Déploie les contrats Casino et HouseToken et les configure
     * @param subId L'ID d'abonnement Chainlink VRF à utiliser pour le Casino
     * @return (address, address payable) Tuple contenant:
     *         - L'adresse du contrat HouseToken
     *         - L'adresse payable du contrat Casino
     */
    function deployCasino(uint64 subId) public returns (address, address payable) {
        // Déploiement du token HouseToken
        token = new HouseToken();

        // Déploiement du Casino avec les paramètres:
        // - Coordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625 (adresse VRF)
        // - KeyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
        // - Subscription ID: subId (passé en paramètre)
        // - Adresse du token HouseToken
        casino = new Casino(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId,
            address(token)
        );
        
        // Configuration du Casino dans le token HouseToken
        token.setCasino(address(casino));
        
        // Retourne les adresses des contrats déployés
        // Conversion explicite de l'adresse du casino en payable
        return (address(token), payable(address(casino)));
    }


     /*
     * @dev Fonction principale exécutée par Forge
     * @notice Lit l'ID d'abonnement VRF depuis les variables d'environnement
     * et déploie les contrats en utilisant vm.broadcast
     */
    function run() external {
        // Récupération de l'ID d'abonnement VRF depuis les variables d'environnement
        uint64 subId = uint64(vm.envUint("VRF_SUB_ID"));
        
        // Démarre une transaction broadcastée (pour le déploiement)
        vm.startBroadcast();
        deployCasino(subId);
        vm.stopBroadcast();
    }
}