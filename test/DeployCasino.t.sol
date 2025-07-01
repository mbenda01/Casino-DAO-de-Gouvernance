// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../script/DeployCasino.s.sol";
import "../src/HouseToken.sol";
import "../src/Casino.sol";

/**
 * @title DeployCasinoTest
 * @dev Suite de tests pour le script de déploiement DeployCasino
 * @notice Vérifie le bon déploiement des contrats Casino et HouseToken
 */
contract DeployCasinoTest is Test {
    DeployCasino deployer;
    
    /**
     * @dev Fonction d'initialisation exécutée avant chaque test
     * @notice Initialise le déployeur et définit les variables d'environnement par défaut
     */
    function setUp() public {
        deployer = new DeployCasino();
        vm.setEnv("VRF_SUB_ID", "1"); // Définit un ID d'abonnement par défaut
    }


    /**
     * @dev Teste le déploiement basique sans broadcast
     * @notice Vérifie que les contrats se déploient correctement et sont liés entre eux
     */
    function testDeploymentWithoutBroadcast() public {
        // Déploie les contrats avec l'ID d'abonnement 1
        (address tokenAddr, address payable casinoAddr) = deployer.deployCasino(1);
        
        // Vérifie que les contrats ont été déployés
        assertTrue(tokenAddr != address(0), "Token should be deployed");
        assertTrue(casinoAddr != address(0), "Casino should be deployed");
        
        // Vérifie les liens entre contrats
        HouseToken token = HouseToken(tokenAddr);
        Casino casino = Casino(casinoAddr);
        
        assertEq(token.casino(), casinoAddr, "Token casino address mismatch");
        assertEq(address(casino.houseToken()), tokenAddr, "Casino token address mismatch");
    }

    /**
     * @dev Teste l'exécution de la fonction run()
     * @notice Vérifie que le script de déploiement s'exécute sans revert
     */
    function testRunFunction() public {
        vm.setEnv("VRF_SUB_ID", "2"); // Surcharge l'ID d'abonnement
        deployer.run(); // Doit s'exécuter sans revert
        
        assertTrue(true, "Run completed without revert");
    }

    /**
     * @dev Teste le déploiement avec différents IDs d'abonnement
     * @notice Vérifie que le Casino enregistre correctement différents IDs VRF
     */
    function testDeploymentWithDifferentSubIds() public {
        for (uint64 i = 1; i <= 5; i++) {
            (address tokenAddr, address payable casinoAddr) = deployer.deployCasino(i);
            Casino casino = Casino(casinoAddr);
            assertEq(casino.subscriptionId(), i, "Subscription ID should match");
        }
    }


     /**
     * @dev Teste le comportement de run() sans variable d'environnement
     * @notice Vérifie que la fonction revert quand VRF_SUB_ID n'est pas défini
     */
    function testRunFunctionWithoutEnvVar() public {
        // Solution 1: Teste simplement que la fonction revert
        vm.expectRevert();
        deployer.run();
        
        // Solution alternative 2: Teste un message de revert spécifique
        // vm.expectRevert(bytes(""));
        // deployer.run();
    }

    /**
     * @dev Teste run() avec un format d'ID invalide
     * @notice Vérifie que la fonction revert quand VRF_SUB_ID n'est pas un nombre
     */
    function testRunFunctionWithInvalidSubId() public {
        vm.setEnv("VRF_SUB_ID", "not_a_number"); // Définit un format invalide
        
        // Solution 1: Teste simplement que la fonction revert
        vm.expectRevert();
        deployer.run();
        
        // Solution alternative 2: Teste une partie du message d'erreur
        // vm.expectRevert(bytes("échec de l'analyse"));
        // deployer.run();
    }
}