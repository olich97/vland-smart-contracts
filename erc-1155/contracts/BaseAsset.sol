//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @title Base non fungible token contract for assets
 * @author Oleh Andrushko (https://olich.me)
 * @dev The contract implement custom base functions in order to handle base functionalities with ERC1155 standard for non fungible assets (es: lands, buildings, roads etc.)
 * @notice Use a UUPS oz proxy pattern for upgradable feature: https://docs.openzeppelin.com/contracts/api/proxy#transparent-vs-uups
 */
abstract contract BaseAsset is Initializable, ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

    /**
     * @dev Geohashes of assets: for public view
     */
    string[] public geohashes;

    /**
     * @dev Mapping from geohash to NFT token ID
     */
    mapping (string => uint256) private _geohashTokens;

    /**
     * @dev mapping from tokentId to price
     */
    mapping (uint256 => uint256) private _tokenPrices;

     /**
     * @dev mapping from tokenId to an token owner
     */
    mapping (uint256 => address) private _tokenOwners;

    /**
     * @dev Mint one nft
     * @param to address for a receiver of newly created nft 
     * @param _geohash geohash
     * @param basePrice associated price
     */
    function _createAsset(address to, string memory _geohash, uint256 basePrice)
        internal 
    {        
        require(!_geohashExists(_geohash), "The asset was already created for geohash");
        require(basePrice > _getTokenPrice(), "Incorrect base price for the asset");
        // generating token id
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        // 
        _mint(to, newItemId, 1, '');
        // keeping track of geohashes
        geohashes.push(_geohash);
        _geohashTokens[_geohash] = newItemId;
        _tokenPrices[newItemId] = basePrice;
        _tokenOwners[newItemId] = to;
    }

    /**
     * @dev Mint many assets nft
     * @param to address for a receiver of newly created nfts
     * @param _geohashes geohashes array
     * @param _basePrices associated prices with geohashes
     */
    function _createManyAssets(address to, string[] memory _geohashes, uint256[] memory _basePrices)
        internal 
    {        
        uint256[] memory newItemIds;
        uint[] memory amounts;
        for (uint256 i = 0; i < _geohashes.length; i++) 
        {
            require(!_geohashExists(_geohashes[i]), "The asset was already created for one of  geohashes");
            require(_basePrices[i] > _getTokenPrice(), "Incorrect base price for one of assets");
            //generating id
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            //newItemIds.push(tokenId);
            newItemIds[i] = tokenId;
            // always 1 per token
            //amounts.push(1);
            amounts[i] = 1;
        } 
        // ERC 1155 mint function: many unique nft of fixed amount 1
        _mintBatch(to, newItemIds, amounts, '');
        // keeping track of prices and token geohashes
         for (uint256 i = 0; i < _geohashes.length; i++) 
         {
            _geohashTokens[_geohashes[i]] = newItemIds[i];
            _tokenPrices[newItemIds[i]] = _basePrices[i];
            geohashes.push(_geohashes[i]);
            _tokenOwners[newItemIds[i]] = to;
        }
    }

    /**
     * @dev Buy an asset
     * @param buyer new owner
     * @param _geohash target token geohash     
     * @param price price for the token
     */
    function _buyAsset(address buyer, string memory _geohash, uint256 price) 
        internal
    {
        uint256 tokenId = tokenOfGeohash(_geohash);        
        uint256 tokenPrice = _tokenPrices[tokenId];
        require(price == tokenPrice, "Value does not match the token price");
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == buyer, "Buyer is already a owner of this token");
        // need to aprove the buyer first?
        setApprovalForAll(buyer, true);
        // transfer nft to new owner (caller, buyer)
        safeTransferFrom(tokenOwner, buyer, tokenId, 1, '');
        // send cash to the old owner
        AddressUpgradeable.sendValue(payable(tokenOwner), price);
    }

     /**
     * @dev Buy many assets
     * @param buyer new owner
     * @param _geohashes target token geohashes   
     * @param amount total price for geohashes
     * @notice would be great to use safeBatchTransferFrom here, but need to figured out how handle _from, because by standard need to be only one (no trasfer of multiple assets with different owners)
     */
    function _buyManyAssets(address buyer, string[] memory _geohashes, uint256 amount) 
        internal
    {
        require(priceOfGeohashes(_geohashes) == amount, "Total amount is not equal to the total price of assets");
        setApprovalForAll(buyer, true);
        for (uint256 i = 0; i < _geohashes.length; i++)
        {
            uint256 tokenId = tokenOfGeohash(_geohashes[i]);
            address tokenOwner = ownerOf(tokenId);
            // if buyer already has this token, escude from transfer?
            if(tokenOwner != buyer) 
            {
                safeTransferFrom(tokenOwner, buyer, tokenId, 1, '');
                AddressUpgradeable.sendValue(payable(tokenOwner), _tokenPrices[tokenId]);
            }
        }
    }

    /**
     * @dev Return total price of many geohashes
     * @param _geohashes a list of geohashe to kwno price of
     */
    function priceOfGeohashes(string[] memory _geohashes)
        public 
        view
        returns (uint256)
    {     
        uint256 totalPrice;
        for (uint256 i = 0; i < _geohashes.length; i++)
        {
            uint256 tokenId = tokenOfGeohash(_geohashes[i]);
            totalPrice = SafeMathUpgradeable.add(totalPrice, _tokenPrices[tokenId]);
        }
        return totalPrice;
    }

    /**
     * @dev Return price of geohash
     * @param _geohash target
     */
    function priceOfGeohash(string memory _geohash)
        public 
        view
        returns (uint256)
    {     
        uint256 tokenId = tokenOfGeohash(_geohash);
        return _tokenPrices[tokenId];
    }

    /**
     * @dev Return owner of geohash
     * @param _geohash target geohash
     */
    function ownerOfGeohash(string memory _geohash)
        public 
        view
        returns (address)
    {
       uint256 tokenId = tokenOfGeohash(_geohash);
       return _tokenOwners[tokenId];
    }

    /**
     * @dev Return owner of token id
     * @param tokenId target token
     */
    function ownerOf(uint256 tokenId)
        public 
        view
        returns (address)
    {
       return _tokenOwners[tokenId];
    }

    /**
     * @dev Sets a new uri metadata for the token
     * @param _newuri target token
     */
    function setURI(string memory _newuri) 
        public 
        onlyOwner 
    {
        _setURI(_newuri);
    }

    /**
    * @dev returns the metadata uri for a given geohash
    * @param _geohash the geohahs to return metadata for
    */
    function geohashUri(string memory _geohash)
        public 
        view
        returns (string memory)
    {
        uint256 tokenId = tokenOfGeohash(_geohash);
        return uri(tokenId);
        //return string(abi.encodePacked(super.uri(tokenId), StringsUpgradeable.toString(tokenId)));
    }

    /**
     * @dev Retrive tokenId associated with geohash
     * @param _geohash target geohash
     */
    function tokenOfGeohash(string memory _geohash) 
        public 
        view 
        returns (uint256)
    {
        require(_geohashExists(_geohash), "Geohash query of nonexistent geohash");
        return _geohashTokens[_geohash];
    }

    /**
     * @dev Returns whether `geohash` exists
     * @param _geohash geohash string
     */
    function _geohashExists(string memory _geohash) 
        internal
        view 
        returns (bool)
    {        
        return _geohashTokens[_geohash] != 0;
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

    /**
     * @dev Return a base price for the token type
     * @notice need to by overriden in main contracts
     */
    function _getTokenPrice() internal virtual returns(uint256);
}