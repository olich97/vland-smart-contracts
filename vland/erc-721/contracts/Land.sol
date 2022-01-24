//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseAsset.sol";

/**
 * @title Contract for Land non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract Land is BaseAsset {   

    constructor() public BaseAsset("VLand", "LND") {}

    /**
     * @dev Used create a new land nft with token url metadata and unique geohash
     * @param to address for a receiver of newly created nft 
     * @param _geohash geohash string
     * @param _tokenURI url for token metadata
     */
    function createLand(address to, string memory _geohash, string memory _tokenURI)
        public 
        onlyOwner
        returns (uint256)
    {        
        require(!_geohashExists(_geohash), "Geohash was already used, the land was already created");
       
        uint256 newItemId = _generateTokenId();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _setTokenGeohash(newItemId, _geohash);
        return newItemId;
    }
}
