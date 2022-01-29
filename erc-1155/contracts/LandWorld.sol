//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract LandWorld is Initializable, ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // Geohashes of all assets (land and buildings)
    string[] public geohashes;
    // Mapping for enforcing unique geohashes TODo maybe do not need this
    mapping(string => bool) _geohasheExists;
    // Mapping from geohash to NFT token ID
    mapping (string => address) private _geohashToken;

    /*
        Leggendo la documentazione dello standard 1155 sezione "Non-Fungible Tokens"
        i token non fungile si possono rappresentare come con la modalita di Split ID bits in un singolo contratto
        cioe i primi 128 bits rappresentano il base token ID (cioe token type: LAND, BUILDING ecc) e altri 128 alla fine
        rappresentano indice del token nft (cioe LAND 1, LAND 2, LAND 3 ... BUILDING 1, BUILDING 2 BULDING 3) rendendoli univoci
        pero cosi e come se fossero fungibili? 
        Natural Non-Fungible token e dire che il max valore e sempre uno per ogni tipo
    */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        // here goes uri of the metadata
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
    * @dev returns the metadata uri for a given id
    * @param _id the token id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");

            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    /**
     * @dev Function that revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     * @notice in this case only a owner can upgrade the contract
     * @param newImplementation address for new the implementation
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}