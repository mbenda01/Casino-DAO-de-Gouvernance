// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Importations des dépendances
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./HouseToken.sol";
import "./Casino.sol";


/**
 * @title Casino Governance System
 * @dev Contrat de gouvernance pour gérer les paramètres du Casino via des propositions
 * @notice Permet aux détenteurs de tokens de voter sur les changements de paramètres
 * Combine les standards OpenZeppelin Governor avec des fonctionnalités customisées
 */
contract CasinoGovernance is 
    Governor,
    GovernorCompatibilityBravo,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /// @notice Instance du contrat Casino à gouverner
    Casino public immutable casino;

    /// @notice Taux de mint minimum (1%)
    uint256 public constant MIN_MINT_RATE = 1; 

    /// @notice Taux de mint maximum (10%)
    uint256 public constant MAX_MINT_RATE = 10; 


    /**
     * @dev Initialise le système de gouvernance
     * @param _token Token utilisé pour le voting (HouseToken)
     * @param _timelock Contrat Timelock pour exécution différée
     * @param _casino Instance du contrat Casino à gouverner
     */
    constructor(
        IVotes _token,
        TimelockController _timelock,
        Casino _casino
    )
        Governor("CasinoGovernance")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(5)  // Quorum à 5%
        GovernorTimelockControl(_timelock)
    {
        casino = _casino;
    }

    /**
     * @notice Délai avant le début du voting (en blocs)
     * @dev Court délai pour les tests (1 bloc)
     * @return Nombre de blocs avant début du vote
     */
    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 bloc au lieu de 1 jour pour les tests
    }

    /**
     * @notice Durée du voting (en blocs)
     * @dev Période courte pour les tests (50 blocs ~10min)
     * @return Nombre de blocs que dure la période de vote
     */
    function votingPeriod() public pure override returns (uint256) {
        return 50; // 50 blocs (~10 minutes) au lieu de 3 jours
    }

    /**
     * @notice Propose un nouveau taux de mint
     * @dev Crée une proposition pour modifier le taux de bonus
     * @param newRate Nouveau taux (entre 1 et 10)
     * @return proposalId ID de la proposition créée
     */
    function proposeNewMintRate(uint256 newRate) public returns (uint256) {
        require(newRate >= MIN_MINT_RATE && newRate <= MAX_MINT_RATE, "Invalid mint rate");
        
        address[] memory targets = new address[](1);
        targets[0] = address(casino);
        
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(Casino.setMintRate.selector, newRate);
        
        string memory description = string(abi.encodePacked("Change mint rate to ", toString(newRate), "%"));
        
        return propose(targets, values, calldatas, description);
    }

    // Fonctions override pour résoudre les conflits d'héritage

    /**
     * @notice Soumet une nouvelle proposition
     * @dev Override pour combiner les fonctionnalités des parents
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }


    /**
     * @notice Annule une proposition
     * @dev Override pour combiner les fonctionnalités des parents
     */
    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256) {
        return super.cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Convertit un uint en string
     * @notice Fonction utilitaire pour les descriptions de proposition
     * @param value Valeur à convertir
     * @return La valeur sous forme de string
     */
    function toString(uint256 value) public pure returns (string memory){
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


    // ========== Overrides requis ==========

    /**
     * @notice Calcule le quorum nécessaire
     * @dev Override combinant les parents
     */
    function quorum(uint256 blockNumber) 
        public 
        view 
        override(IGovernor, GovernorVotesQuorumFraction) 
        returns (uint256) 
    {
        return super.quorum(blockNumber);
    }

     /**
     * @notice Récupère l'état d'une proposition
     * @dev Override combinant les parents
     */
    function state(uint256 proposalId)
        public
        view
        override(Governor, IGovernor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @notice Exécute une proposition
     * @dev Override combinant les parents
     */
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Annule une proposition en interne
     * @dev Override combinant les parents
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

     /**
     * @notice Récupère l'adresse de l'exécuteur
     * @dev Override combinant les parents
     */
    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }


    /**
     * @notice Vérifie la prise en charge d'une interface
     * @dev Override combinant les parents
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl, IERC165)
        returns (bool)
    {
        return interfaceId == type(IGovernor).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    
}