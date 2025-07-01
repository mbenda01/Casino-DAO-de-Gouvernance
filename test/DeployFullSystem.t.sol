// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../script/DeployFullSystem.s.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "../src/HouseToken.sol";
import "../src/Casino.sol";
import "../src/Governance.sol";

/**
 * @title DeployFullSystemTest
 * @dev Suite de tests pour le déploiement complet du système Casino
 * @notice Vérifie le bon fonctionnement du script de déploiement et la configuration des contrats
 */
contract DeployFullSystemTest is Test {
    DeployFullSystem public deployer;
    
     /// @notice Adresse du déployeur par défaut pour les tests
    address constant DEFAULT_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    
    /// @notice Clé privée du déployeur pour les tests (comme sur Anvil)
    uint256 constant DEFAULT_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    
    /// @notice ID d'abonnement VRF par défaut pour les tests
    uint64 constant SUB_ID = 1;

     /**
     * @dev Initialise l'environnement de test avant chaque test
     * @notice Configure le déployeur et les variables d'environnement nécessaires
     */
    function setUp() public {
        deployer = new DeployFullSystem();
        vm.setEnv("VRF_SUB_ID", "1");
        vm.setEnv("PRIVATE_KEY", vm.toString(DEFAULT_PRIVATE_KEY));
        vm.deal(DEFAULT_DEPLOYER, 100 ether);  // Donne des fonds au déployeur
    }


    /**
     * @dev Test le déploiement direct via deployForTest
     * @notice Vérifie que tous les contrats sont correctement déployés
     */
    function testRunFunctionDirectly() public {
        // Solution alternative utilisant deployForTest au lieu de run()
        (address tokenAddr, address payable casinoAddr, address payable timelockAddr, address payable govAddr) = 
            deployer.deployForTest(SUB_ID, DEFAULT_DEPLOYER);
            
         // Vérifications des déploiements
        assertTrue(tokenAddr != address(0), "Token not deployed");
        assertTrue(casinoAddr != address(0), "Casino not deployed");
        assertTrue(timelockAddr != address(0), "Timelock not deployed");
        assertTrue(govAddr != address(0), "Governance not deployed");
    }


    /**
     * @dev Test la configuration complète des rôles
     * @notice Vérifie que tous les rôles sont correctement attribués dans le Timelock
     */
    function testRoleSetupCompletely() public {
        // Test détaillé de _setupRoles
        (,, address payable timelockAddr, address payable govAddr) = 
            deployer.deployForTest(SUB_ID, DEFAULT_DEPLOYER);
            
        TimelockController timelock = TimelockController(timelockAddr);
        
        // Vérification des rôles
        assertTrue(timelock.hasRole(timelock.TIMELOCK_ADMIN_ROLE(), DEFAULT_DEPLOYER));
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), govAddr));
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), DEFAULT_DEPLOYER));
        assertFalse(timelock.hasRole(timelock.TIMELOCK_ADMIN_ROLE(), address(deployer)));
        
        // Vérification spécifique du rôle EXECUTOR (ouvert à tous)
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)));
    }


     /**
     * @dev Test la conversion des adresses en payable
     * @notice Vérifie que les adresses des contrats peuvent recevoir des fonds
     */
    function testPayableAddressConversion() public {
        // Test spécifique des conversions payable
        (address tokenAddr, address payable casinoAddr,,) = deployer.deployForTest(SUB_ID, DEFAULT_DEPLOYER);
        
        // Test que le casino peut recevoir des fonds
        Casino casino = Casino(casinoAddr);
        (bool success,) = casinoAddr.call{value: 1 ether}("");
        assertTrue(success, "Should be payable");
        
        // Test de transfert d'ETH
        uint256 initialBalance = casinoAddr.balance;
        payable(casinoAddr).transfer(1 ether);
        assertEq(casinoAddr.balance, initialBalance + 1 ether, "Balance should increase");
    }


    /**
     * @dev Test le déploiement avec un admin différent
     * @notice Vérifie que les rôles sont correctement attribués au nouvel admin
     */
    function testDeployWithDifferentAdmin() public {
        // Test avec un admin différent
        address newAdmin = address(0x123);
        (,, address payable timelockAddr,) = deployer.deployForTest(SUB_ID, newAdmin);
        
        TimelockController timelock = TimelockController(timelockAddr);
        assertTrue(timelock.hasRole(timelock.TIMELOCK_ADMIN_ROLE(), newAdmin));
    }


    /**
     * @dev Test le déploiement avec différents IDs d'abonnement
     * @notice Vérifie que le Casino enregistre correctement chaque ID VRF
     */
    function testDeployWithDifferentSubId() public {
        // Test avec différents subIds
        for (uint64 i = 1; i <= 3; i++) {
            (address tokenAddr, address payable casinoAddr,,) = deployer.deployForTest(i, DEFAULT_DEPLOYER);
            Casino casino = Casino(casinoAddr);
            assertEq(casino.subscriptionId(), i, "Subscription ID should match");
        }
    }


    /**
     * @dev Test spécifique de la révocation du rôle admin
     * @notice Vérifie que le déployeur n'a plus le rôle admin après configuration
     */
    function testRevokeAdminRole() public {
        // Test spécifique de la révocation du rôle admin
        (,, address payable timelockAddr,) = deployer.deployForTest(SUB_ID, DEFAULT_DEPLOYER);
        TimelockController timelock = TimelockController(timelockAddr);
        
        // Vérifie que le déployeur n'a plus le rôle admin
        assertFalse(timelock.hasRole(timelock.TIMELOCK_ADMIN_ROLE(), address(deployer)));
    }
}