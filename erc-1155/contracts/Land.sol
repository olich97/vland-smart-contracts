//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseAsset.sol";


/**
 * @title Contract for Land non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract Land is BaseAsset {

    uint256 public constant MIN_TOKEN_PRICE = 10000000000000000; // wei - 0.01 ether

    /**
     * @dev mapping from land geohash to assets geohash
     * @notice is one to many mapping, meaning that a single land could have more that one asset
     */
    mapping (string => string[]) private _landAssets;

    /**
     * @dev mapping from asset geohash to a contract address (es: building geohash -> contract xxxx)
     * @notice is one to one mapping, meaning that for a single asset we can have only one contract address
     */
    mapping (string => address) private _assetAddresses;  

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
    function createLand(address to, string memory _geohash, uint256 basePrice)
        public 
        onlyOwner
    {        
        _createAsset(to, _geohash, basePrice);
    }

    /**
     * @dev Used create a new land nfts with unique geohashes
     * @param to address for a receiver of newly created nft 
     * @param _geohashes geohash string
     * @param basePrices starting price for the nft in wei
     */
    function createManyLands(address to, string[] memory _geohashes, uint256[] memory basePrices)
        public 
        onlyOwner
    {        
        _createManyAssets(to, _geohashes, basePrices);
    }

    /**
     * @dev Buy a land
     * @param _geohash target token geohash
     */
    function buyLand(string memory _geohash) 
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
