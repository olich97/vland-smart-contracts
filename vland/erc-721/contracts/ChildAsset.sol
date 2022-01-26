//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseAsset.sol";
import "./Land.sol";
// only for debbuging
import "hardhat/console.sol";

/**
 * @title Contract for base operation on assets that could be inside the land
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract ChildAsset is BaseAsset {

    Land private _landContract;

    constructor(string memory _name, string memory _symbol) public BaseAsset(_name, _symbol) {}

    /**
     * @dev mapping from building geohash to land geohash
     * @notice is one to one mapping, meaning that a single tokenID of building nft could be associated to only one land
     */
    mapping (string => string) private _tokenLandGeohashes;

    /**
     * @dev Throws if land is invalid
     */
    modifier OnlyValidLand(string memory _landGeohash) 
    {
        require(address(_landContract) != address(0), "Invalid or empty land contract address"); // TODO: add check if it is a contract address?
        // ensure that the land with the geohash exists
        // (additionally with the geohash it is possible to check even if building is inside a land or if it is conflicted with others assets)
        require(_landContract.ownerOfGeohash(_landGeohash) != address(0), "Nonexistent lang geohash");
        _;
    }     
     
    /**
     * @dev Grabs the geohash of connected land
     */
    function landOf(string memory _assetGeohash) 
        public 
        view 
        returns (string memory)
    {        
        return _tokenLandGeohashes[_assetGeohash];
    }

    /**
     * @dev Grabs current land contract address
     */
    function landContractAddress() 
        external 
        view 
        returns (address)
    {
        return address(_landContract);
    }

    /**
     * @dev Set the land (parent) contract address
     * @param landContractAddress address for interacting with land contract
     */
    function setLandContract(address landContractAddress)
        external 
        onlyOwner
    {            
        _landContract = Land(landContractAddress);
    }    

    /**
     * @dev Assigns a land to a building (for land contract operation)
     * @param _assetGeohash target token
     * @param _landGeohash land
     * TODO: NEED TO ADD AUTHORIZATION LAND FROM CONTRACT CALLS
     */
    function addAssetToLandFromParent(string memory _assetGeohash, string memory _landGeohash)
        external 
    {   
        _setAssetLand(_assetGeohash, _landGeohash);
    }

    /**
     * @dev Assigns a land to a building
     * @param _assetGeohash target token
     * @param _landGeohash land
     */
    function _addAssetToLand(string memory _assetGeohash, string memory _landGeohash)
        internal         
        OnlyValidLand(_landGeohash)
    {   
        _setAssetLand(_assetGeohash, _landGeohash);
        // call land contract in order to add current building to the land
        _landContract.addAssetFromChild(_landGeohash, _assetGeohash);
    }

    /**
     * @dev Set a land to a an asset
     * @param _assetGeohash target token
     * @param _landGeohash land
     */
    function _setAssetLand(string memory _assetGeohash, string memory _landGeohash)
        private 
    {   
        // ensure that asset exists
        require(_geohashExists(_assetGeohash), "Land set of nonexistent asset token");
        // ensure that asset is not part of any other lands
        require(bytes(_tokenLandGeohashes[_assetGeohash]).length == 0, "Asset is already associated with a land");

        _tokenLandGeohashes[_assetGeohash] = _landGeohash;
    }
}
