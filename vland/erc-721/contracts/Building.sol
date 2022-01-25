//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseAsset.sol";
import "./ChildAsset.sol";
// only for debbuging
import "hardhat/console.sol";

/**
 * @title Contract for a building asset non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract Building is ChildAsset {

    constructor() public ChildAsset("VBuilding", "BLD") {}

    /**
     * @dev Create a new unique building nft with token url metadata and unique geohash
     * @param to address for a receiver of newly created nft 
     * @param _geohash geohash string
     * @param _tokenURI url for token metadata
     */
    function createBuilding(address to, string memory _geohash, string memory _tokenURI)
        public 
        onlyOwner
        returns (uint256)
    {        
        require(!_geohashExists(_geohash), "Geohash was already used, the building was already created");
       
        uint256 newItemId = _generateTokenId();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _setTokenGeohash(newItemId, _geohash);
        return newItemId;
    }

    /**
     * @dev Create a unique building on a land
     * @param to address for a receiver of newly created nft 
     * @param _buildingGeohash geohash of a building @notice need to be at least 8 characters in order to archive more precission on buildings position
     * @param _landGeohash geohash of land to associate with the building
     * @param _tokenURI url for token metadata
     */
    function createBuildingOnLand(address to, string memory _buildingGeohash, string memory _landGeohash,  string memory _tokenURI)
        external 
        onlyOwner
        returns (uint256)
    {           
        require(!_geohashExists(_buildingGeohash), "Geohash was already used, the building was already created");
        // mint a new building
        uint256 tokenId = createBuilding(to, _buildingGeohash, _tokenURI);
        // link a building to land
        _addAssetToLand(_buildingGeohash, _landGeohash);

        return tokenId;
    }

     /**
     * @dev Assigns a land to a building
     * @param _buildingGeohash building geohash
     * @param _landGeohash land geohash
     */
    function addBuildingToLand(string memory _buildingGeohash, string memory _landGeohash)
        external 
        onlyOwner
    {   
        _addAssetToLand(_buildingGeohash, _landGeohash);
    }
}
