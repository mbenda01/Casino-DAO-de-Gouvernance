// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title Simple Counter Contract
 * @dev Contrat simple implémentant un compteur avec incrément et modification
 * @notice Ce contrat permet de stocker et manipuler une valeur numérique
 */
contract Counter {
    /// @notice La valeur actuelle du compteur
    /// @dev Stockée sous forme d'entier non signé 256 bits
    uint256 public number;

    /**
     * @notice Modifie la valeur du compteur
     * @dev Met à jour la variable d'état `number`
     * @param newNumber La nouvelle valeur à attribuer au compteur
     * 
     * Emits:
     * - Pas d'événement émis (contrat minimaliste)
     */
    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }


    /**
     * @notice Incrémente le compteur de 1
     * @dev Effectue une opération d'incrément sur la variable d'état `number`
     * 
     * Emits:
     * - Pas d'événement émis (contrat minimaliste)
     * 
     * Requirements:
     * - Le compteur ne peut pas dépasser le maximum uint256 (overflow impossible en Solidity 0.8+)
     */
    function increment() public {
        number++;
    }
}
