//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseAsset.sol";
// only for debbuging
import "hardhat/console.sol";

/**
 * @title Contract for a building asset non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract Building is BaseAsset {

    uint256 private MIN_TOKEN_PRICE = 1000000000000000; // wei - 0.001 ether

    constructor() public BaseAsset("VBuilding ERC721", "BLD721") {}

    /**
     * @dev Create a new unique building nft with token url metadata and unique geohash
     * @param to address for a receiver of newly created nft 
     * @param _geohash geohash string
     * @param basePrice starting price for the nft in ethers (min 0.001 ether)
     * @param _tokenURI url for token metadata
     */
    function createBuilding(address to, string memory _geohash, uint256 basePrice, string memory _tokenURI)
        public 
        onlyOwner
        returns (uint256)
    {        
        require(!_geohashExists(_geohash), "Geohash was already used, the building was already created");
        require(basePrice > MIN_TOKEN_PRICE, "Base price for the building should be grether than 0.001 ether");
       
        uint256 newItemId = _generateTokenId();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _setTokenGeohash(newItemId, _geohash);
        _setTokenPrice(newItemId, basePrice);
        return newItemId;
    }
}
