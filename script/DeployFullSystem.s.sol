// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {CasinoGovernance} from "../src/Governance.sol";
import {HouseToken} from "../src/HouseToken.sol";
import {Casino} from "../src/Casino.sol";


/**
 * @title DeployFullSystem
 * @dev Script de déploiement complet du système Casino avec gouvernance
 * @notice Ce script déploie l'ensemble des contrats du système :
 * - HouseToken (token natif du casino)
 * - Casino (contrat principal)
 * - TimelockController (contrat de délai pour les propositions)
 * - CasinoGovernance (système de gouvernance)
 */
contract DeployFullSystem is Script {

    /**
     * @dev Fonction principale exécutée par Forge
     * @notice Déploie l'ensemble du système en utilisant la clé privée et l'ID d'abonnement VRF
     * depuis les variables d'environnement
     * @return Tuple contenant :
     *         - token: Adresse du contrat HouseToken
     *         - casino: Adresse payable du contrat Casino
     *         - timelock: Adresse payable du contrat TimelockController
     *         - governance: Adresse payable du contrat CasinoGovernance
     */
    function run() external returns (
        address,          // token
        address payable,  // casino
        address payable,  // timelock 
        address payable   // governance
    ) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        uint64 subId = uint64(vm.envUint("VRF_SUB_ID"));

        vm.startBroadcast(deployerPrivateKey);
        (address token, address casino, address timelock, address gov) = _deploySystem(subId, admin);
        vm.stopBroadcast();

        return (
            token,
            payable(casino),
            payable(timelock),
            payable(gov)
        );
    }


    /**
     * @dev Déploie l'ensemble du système de contrats
     * @param subId ID d'abonnement Chainlink VRF
     * @param admin Adresse de l'administrateur initial
     * @return Tuple contenant les adresses des contrats déployés :
     *         - token: Adresse du HouseToken
     *         - casino: Adresse du Casino
     *         - timelock: Adresse du TimelockController
     *         - gov: Adresse du CasinoGovernance
     */
    function _deploySystem(uint64 subId, address admin) internal returns (
        address,
        address,
        address,
        address
    ) {
        // Déploiement du token natif
        HouseToken token = new HouseToken();
        
        // Déploiement du contrat Casino avec configuration VRF
        Casino casino = new Casino(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId,  // ID d'abonnement VRF
            address(token)  // Adresse du token natif
        );

        // Configuration du Casino dans le token
        token.setCasino(address(casino));

        // Déploiement du TimelockController avec un délai de 1 jour
        TimelockController timelock = new TimelockController(
            1 days,                  // Délai minimum pour les propositions
            new address[](0),        // Proposers initiaux (vide)
            new address[](0),        // Executors initiaux (vide)
            address(this)            // Admin initial (ce contrat)
        );

        // Transfert de la propriété du Casino au Timelock
        casino.transferOwnership(address(timelock));

        CasinoGovernance governance = new CasinoGovernance(
            token,
            timelock,
            casino
        );

        // Configuration des rôles dans le Timelock
        _setupRoles(timelock, address(governance), admin);

        return (
            address(token),
            address(casino),
            address(timelock),
            address(governance)
        );
    }


    /**
     * @dev Version publique de la fonction de déploiement pour les tests
     * @param subId ID d'abonnement Chainlink VRF
     * @param admin Adresse de l'administrateur initial
     * @return Tuple contenant les adresses payables des contrats déployés
     */
    function deployForTest(uint64 subId, address admin) public returns (
        address,
        address payable,
        address payable,
        address payable
    ) {
        (address token, address casino, address timelock, address gov) = _deploySystem(subId, admin);
        return (
            token,
            payable(casino),
            payable(timelock),
            payable(gov)
        );
    }


    /**
     * @dev Configure les rôles dans le TimelockController
     * @param timelock Instance du TimelockController
     * @param governance Adresse du contrat de gouvernance
     * @param admin Adresse de l'administrateur
     * @notice Donne les rôles appropriés à la gouvernance et à l'admin,
     * et retire le rôle admin temporaire de ce contrat
     */
    function _setupRoles(
        TimelockController timelock,
        address governance,
        address admin
    ) internal {
        // Donne le rôle admin temporaire à ce contrat
        timelock.grantRole(timelock.TIMELOCK_ADMIN_ROLE(), address(this));
        
        // Configure les rôles principaux
        timelock.grantRole(timelock.PROPOSER_ROLE(), governance);
        
        // La gouvernance peut faire des propositions
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        
        // Tout le monde peut exécuter (adresse 0)
        timelock.grantRole(timelock.CANCELLER_ROLE(), admin); // L'admin peut annuler
        
        
        timelock.grantRole(timelock.TIMELOCK_ADMIN_ROLE(), admin); // Donne le rôle admin permanent
        
        // Révoque le rôle admin temporaire de ce contrat
        timelock.revokeRole(timelock.TIMELOCK_ADMIN_ROLE(), address(this));
    }
}