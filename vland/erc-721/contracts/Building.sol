//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseAsset.sol";

/**
 * @title Contract for building asset non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract Building is BaseAsset {

    address private _landContract;

    // building token id -> land geohash
    mapping (uint256 => string) private _tokenLands;

    constructor() public BaseAsset("VBuilding", "BLD") {}

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
        public 
        onlyOwner
        returns (uint256)
    {   
        
        //require(!_geohashExists(_buildingGeohash), "Geohash was already used, the building was already created");
  
        // mint a new building

        // need to check if land with the geohash exists - call to land contract? and revert minting if not exists
        // (additionally with the geohash it is possible to check even if building is inside a land or if it is conflicted with others assets)

        // add a land geohash to building

    }

    /**
     * @dev Assigns a land geohash to a building
     * @param tokenId target token
     * @param _landGeohash land
     */
    function addBuildingToLand(uint256 tokenId, string memory _landGeohash)
        public 
    {   
        // ensure that building exists
        require(_exists(tokenId), "Land set of nonexistent building token");
        // ensure that building is not part of any other lands
        require(_tokenLands[tokenId] != 0, "Building is already associated with a land");

        _tokenLands[tokenId] = _landGeohash;
    }
    
    /**
     * @dev Set the land (parent) contract address
     * @param landContract address for interacting with land contract
     */
    function setLandContract(address landContract)
        public 
        onlyOwner
    {            
        _landContract = landContract;
    }
}
