//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseAsset.sol";
import "hardhat/console.sol";

/**
 * @title Contract for Building non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract Building is BaseAsset {

    // kust to give some

    uint256 public constant MIN_TOKEN_PRICE = 1000000000000000; // wei - 0.001 ether

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory _uri) initializer public {        
        __ERC1155_init(_uri);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Used create a new land nft with unique geohash
     * @param to address for a receiver of newly created nft 
     * @param _geohash geohash string
     * @param basePrice starting price for the nft in wei
     */
    function createBuilding(address to, string memory _geohash, uint256 basePrice)
        public 
        onlyOwner
    {        
        _createAsset(to, _geohash, basePrice);
    }

    /**
     * @dev Create many buiuldings with unique geohashes
     * @param to address for a receiver of newly created nft 
     * @param _geohashes geohash string
     * @param basePrices starting price for the nft in wei
     */
    function createManyBuildings(address to, string[] memory _geohashes, uint256[] memory basePrices)
        public 
        onlyOwner
    {        
        _createManyAssets(to, _geohashes, basePrices);
    }

    /**
     * @dev Buy a building
     * @param _geohash target token geohash
     */
    function buyBuilding(string memory _geohash) 
        public 
        payable
    {       
        _buyAsset(msg.sender, _geohash, msg.value);
    }


    /**
     * @dev return base price for lands
     */
    function _getTokenPrice() 
        internal 
        virtual
        override 
        returns(uint256)
    {
        return MIN_TOKEN_PRICE;
    }
}
