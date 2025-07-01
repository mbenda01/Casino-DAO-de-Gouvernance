// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/Governance.sol";
import "../src/HouseToken.sol";
import "../src/Casino.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";


/**
 * @title Casino Governance Test Suite
 * @dev Tests complets pour le système de gouvernance du Casino
 * @notice Vérifie toutes les fonctionnalités de gouvernance y compris :
 * - Le cycle de vie complet des propositions
 * - Les permissions et contrôles d'accès
 * - Les fonctions override du Governor
 */
contract GovernanceTest is Test {
    // Instances des contrats
    HouseToken public token;
    Casino public casino;
    TimelockController public timelock;
    CasinoGovernance public governance;
    
    address public admin = address(1);
    address public proposer = address(2);
    address public voter1 = address(3);
    address public voter2 = address(4);
    address public voter3 = address(5);

    /**
     * @dev Setup initial avant chaque test
     * 1. Déploie le token HOUSE
     * 2. Configure le mock VRF et le Casino
     * 3. Initialise le Timelock
     * 4. Déploie le système de gouvernance
     */
    function setUp() public {
        // 1. Déploiement du token HOUSE
        token = new HouseToken();
        
        // 2. Configuration du Casino avec mock VRF
        VRFCoordinatorV2Mock vrfMock = new VRFCoordinatorV2Mock(0.1 ether, 1e9);
        uint64 subId = vrfMock.createSubscription();
        vrfMock.fundSubscription(subId, 10 ether);
        
        casino = new Casino(
            address(vrfMock),
            bytes32("0xabc"),
            subId,
            address(token)
        );
        
        // Configuration initiale du token
        token.setCasino(address(casino));
        
        // Distribution des tokens aux testeurs
        vm.prank(address(casino));
        token.mint(proposer, 1000 ether);
        vm.prank(address(casino));
        token.mint(voter1, 500 ether);
        vm.prank(address(casino));
        token.mint(voter2, 300 ether);
        vm.prank(address(casino));
        token.mint(voter3, 200 ether);

        vrfMock.addConsumer(subId, address(casino));

        // 3. Déploiement du Timelock
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(this);
        executors[0] = address(0);
        timelock = new TimelockController(1 days, proposers, executors, admin);

        // 4. Déploiement du système de gouvernance
        governance = new CasinoGovernance(
            IVotes(address(token)),
            timelock,
            casino
        );
    }
    
    /**
     * @dev Test le cycle de vie complet d'une proposition
     * 1. Configure les permissions
     * 2. Soumet une proposition
     * 3. Vote sur la proposition
     * 4. Met en file d'attente et exécute
     */
    function testProposalLifecycle() public {
        uint256 newRate = 3;
        uint256 initialRate = casino.mintRate();
        
       // 1. Configure les permissions
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        vm.prank(admin);
        timelock.grantRole(proposerRole, address(governance));

         // 2. Transfère la propriété au Timelock
        vm.prank(address(this)); // Le test contract est le owner initial
        casino.transferOwnership(address(timelock));

        // Délégation des tokens
        vm.prank(proposer);
        token.delegate(proposer);
        
        vm.prank(voter1);
        token.delegate(voter1);
        
        vm.prank(voter2);
        token.delegate(voter2);
        
        vm.prank(voter3);
        token.delegate(voter3);

        // 3. Soumission de la proposition
        vm.prank(proposer);
        uint256 proposalId = governance.proposeNewMintRate(newRate);
        
         // Vérification des états
        assertEq(uint256(governance.state(proposalId)), 0, "Should be Pending");
        
       // Passage à la période de vote
        vm.roll(block.number + governance.votingDelay() + 1);
        assertEq(uint256(governance.state(proposalId)), 1, "Should be Active");
        
         // Votes
        vm.prank(proposer);
        governance.castVote(proposalId, 1);
        
        vm.prank(voter1);
        governance.castVote(proposalId, 1);
        
        vm.prank(voter2);
        governance.castVote(proposalId, 0);
        
        // Fin de la période de vote
        vm.roll(block.number + governance.votingPeriod() + 1);
        assertEq(uint256(governance.state(proposalId)), 4, "Should be Succeeded");
        
        // Mise en file d'attente
        address[] memory targets = new address[](1);
        targets[0] = address(casino);
        
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(Casino.setMintRate.selector, newRate);
        
        string memory description = string(abi.encodePacked("Change mint rate to ", toString(newRate), "%"));
        
        vm.prank(proposer);
        governance.queue(targets, values, calldatas, keccak256(bytes(description)));
        
        uint256 minDelay = timelock.getMinDelay();

        // Délai du Timelock
        vm.warp(block.timestamp + minDelay + 1);
        
         // Exécution
        vm.prank(proposer);
        governance.execute(targets, values, calldatas, keccak256(bytes(description)));
        
        // Vérifications finales
        assertEq(casino.mintRate(), newRate, "Mint rate should be updated");
        assertEq(uint256(governance.state(proposalId)), 7, "Should be Executed");
        assertTrue(initialRate != newRate, "Rates should differ");
    }

    // ========== FONCTIONS UTILITAIRES ==========
    
    /**
     * @dev Convertit un uint en string
     * @notice Utilisé pour générer les descriptions de proposition
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function proposalStateToString(uint256 state) internal pure returns (string memory) {
        if (state == 0) return "Pending";
        if (state == 1) return "Active";
        if (state == 2) return "Canceled";
        if (state == 3) return "Defeated";
        if (state == 4) return "Succeeded";
        if (state == 5) return "Queued";
        if (state == 6) return "Expired";
        return "Executed";
    }


    // ========== TESTS DES CONTRAINTES ==========
    
    /**
     * @dev Test les limites du taux de mint
     * @notice Vérifie qu'on ne peut pas proposer des taux invalides
     */
    function testCannotProposeInvalidMintRate() public {
        vm.prank(proposer);
        vm.expectRevert("Invalid mint rate");
        governance.proposeNewMintRate(0); // Trop bas
        
        vm.prank(proposer);
        vm.expectRevert("Invalid mint rate");
        governance.proposeNewMintRate(11); // Trop haut
    }


    // ========== TESTS DES FONCTIONS OVERRIDE ==========
    
    /**
     * @dev Test toutes les fonctions override
     * @notice Vérifie le bon fonctionnement des fonctions héritées
     */
    function testAllOverrideFunctions() public {
        // Test supportsInterface
        bytes4 governorInterfaceId = type(IGovernor).interfaceId;
        assertTrue(governance.supportsInterface(governorInterfaceId), "Should support IGovernor");
        
        // Test quorum calculation
        uint256 pastBlock = block.number - 1;
        uint256 totalSupply = token.getPastTotalSupply(pastBlock);
        uint256 calculatedQuorum = (totalSupply * governance.quorumNumerator()) / 100;
        uint256 actualQuorum = governance.quorum(pastBlock);
        assertEq(actualQuorum, calculatedQuorum, "Quorum calculation mismatch");
        
        // Test state avec ID invalide
        (bool success, ) = address(governance).call(
            abi.encodeWithSelector(Governor.state.selector, 999)
        );
        assertFalse(success, "Call to state() should revert for unknown proposal");
        
        // Test timelock address
        assertEq(governance.timelock(), address(timelock), "Timelock address mismatch");
    }


    // ========== TESTS COMPLEMENTAIRES ==========
    
    /**
     * @dev Test l'annulation d'une proposition
     * @notice Vérifie le bon fonctionnement de l'annulation
     */
    function testCancelProposal() public {
        // Configuration
        vm.prank(address(casino));
        token.mint(proposer, 10000 ether);
        vm.prank(proposer);
        token.delegate(proposer);
        
        // Donne les droits d'annulation
        bytes32 cancelRole = timelock.CANCELLER_ROLE();
        vm.prank(admin);
        timelock.grantRole(cancelRole, address(governance));
        
        // Soumet et annule
        vm.prank(proposer);
        uint256 proposalId = governance.proposeNewMintRate(3);
        vm.prank(proposer);
        governance.cancel(proposalId);
        
         // Vérification
        assertEq(uint256(governance.state(proposalId)), 2); // 2 = ProposalState.Canceled
    }

    /**
     * @dev Test l'échec d'exécution avec mauvais paramètres
     * @notice Vérifie le comportement avec des paramètres invalides
     */
    function testProposalExecutionFailsWithWrongParameters() public {
        
        address[] memory wrongTargets = new address[](1);
        wrongTargets[0] = address(0xdead);
        
        vm.prank(proposer);
        uint256 wrongProposalId = governance.propose(wrongTargets, new uint256[](1), new bytes[](1), "Wrong proposal");
        
        
        vm.expectRevert();
        governance.execute(wrongTargets, new uint256[](1), new bytes[](1), keccak256(bytes("Wrong proposal")));
    }
        // Test pour couvrir les fonctions supportsInterface()
    function testSupportsInterface() public {
        // Vérifie IGovernor
        assertTrue(governance.supportsInterface(type(IGovernor).interfaceId));
        
        // Vérifie d'autres interfaces (ex: IERC165)
        bytes4 invalidInterface = 0xffffffff;
        assertFalse(governance.supportsInterface(invalidInterface));
    }

    // Test pour couvrir les cas limites de cancel()
    function testCancelProposalAsNonOwner() public {
        // Crée une proposition
        vm.prank(proposer);
        uint256 proposalId = governance.proposeNewMintRate(3);
        
        // Tente d'annuler sans droits
        vm.prank(address(0xbad));
        vm.expectRevert();
        governance.cancel(proposalId);
    }

    function testFullCoverage() public {
        // Test toString()
        testToStringEdgeCases();
        
        // Test supportsInterface()
        testInterfaceSupport();
        
        // Test des fonctions avec paramètres invalides
        testInvalidParameters();
    }
    
    function testToStringEdgeCases() public {
        // Test valeur maximale
        uint256 maxUint = type(uint256).max;
        string memory result = governance.toString(maxUint);
        assertEq(
            result, 
            "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        );

        // Test valeur simple
        assertEq(governance.toString(9), "9");
    }

    function testInterfaceSupport() public {
        // Test interface non supportée
        bytes4 invalidInterface = 0xffffffff;
        assertFalse(governance.supportsInterface(invalidInterface));

        // Test interface vide
        assertFalse(governance.supportsInterface(0x00000000));
    }

    function testInvalidParameters() public {
        // Test cancel avec paramètres invalides
        address[] memory empty;
        vm.expectRevert();
        governance.cancel(empty, new uint256[](0), new bytes[](0), bytes32(0));

        // Test execute avec ID invalide
        vm.expectRevert();
        governance.execute(999);
    }
}
