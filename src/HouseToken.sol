// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Importations des dépendances
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title House Token
 * @dev Token de gouvernance pour le système Casino
 * @notice Token ERC20 avec fonctionnalités de vote et minting contrôlé
 * Ce token donne des droits de gouvernance et peut être minté comme bonus
 */
contract HouseToken is ERC20Votes, Ownable {
    /// @notice Adresse du contrat Casino autorisé à mint des tokens
    address public casino;

    /// @notice Erreur émise quand une opération est tentée par un non-casino
    error NotCasino();

    /// @notice Événement émis quand l'adresse du casino est mise à jour
    event CasinoSet(address indexed casino);

    /// @notice Événement émis quand de nouveaux tokens sont mintés
    event TokenMinted(address indexed to, uint256 amount);

    /**
     * @dev Constructeur initialisant le token
     * @notice Crée un token ERC20 avec le nom "HouseToken" et symbole "HOUSE"
     * Initialise également le système de permissions ERC20Permit
     */
    constructor()
        ERC20("HouseToken", "HOUSE")
        ERC20Permit("HouseToken")
    {}


    /**
     * @notice Définit l'adresse du contrat Casino autorisé
     * @dev Seul le owner peut appeler cette fonction
     * @param _casino Adresse du contrat Casino
     * 
     * Emits:
     * - CasinoSet avec la nouvelle adresse
     * 
     * Requirements:
     * - L'appelant doit être le owner
     * - L'adresse ne peut pas être zero
     */
    function setCasino(address _casino) external onlyOwner {
        require(_casino != address(0), "Invalid casino address");
        casino = _casino;
        emit CasinoSet(_casino);
    }


    /**
     * @notice Mint de nouveaux tokens
     * @dev Seul le contrat Casino peut appeler cette fonction
     * @param to Adresse recevant les tokens
     * @param amount Montant de tokens à mint
     * 
     * Emits:
     * - TokenMinted avec l'adresse du receveur et le montant
     * - Transfer event (hérité d'ERC20)
     * 
     * Requirements:
     * - L'appelant doit être le contrat Casino enregistré
     */
    function mint(address to, uint256 amount) external {
        if (msg.sender != casino) revert NotCasino();
        _mint(to, amount);
        emit TokenMinted(to, amount);
    }


    // ========== Overrides requis pour ERC20Votes ==========

    /**
     * @dev Hook appelé après chaque transfert de tokens
     * @notice Met à jour les snapshots de voting
     */
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Mint interne override pour supporter ERC20Votes
     */
    function _mint(address to, uint256 amount)
        internal
        override(ERC20Votes)
    {
        super._mint(to, amount);
    }


    /**
     * @dev Burn interne override pour supporter ERC20Votes
     */
    function _burn(address account, uint256 amount)
        internal
        override(ERC20Votes)
    {
        super._burn(account, amount);
    }


    /**
     * @notice Permet à un utilisateur de brûler des tokens approuvés
     * @dev Fonction utilitaire pour brûler via une allocation
     * @param account Adresse dont les tokens seront brûlés
     * @param amount Montant de tokens à brûler
     * 
     * Emits:
     * - Transfer event (vers l'adresse zero)
     * 
     * Requirements:
     * - L'appelant doit avoir une allocation suffisante
     */
    function burnFrom(address account, uint256 amount) public {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
}