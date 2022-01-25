//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC721 standard implementation
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// To only allow the owner of the smart contract to mint NFTs we’ve imported
// https://docs.openzeppelin.com/contracts/4.x/access-control
import "@openzeppelin/contracts/access/Ownable.sol";
// needed as our smart contract needs a counter to keep track of the total number of NFTs minted 
// and assign the unique ID on our new NFT
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Base non fungible token contract for assets
 * @author Oleh Andrushko (https://olich.me)
 * @dev The contract implement custom base functions in order to handle base functionalities with ERC721 standard for non fungible assets (es: lands, buildings, roads etc.)
 *      In combination with token metadata, the contact store (on-chain) a geohash unique string for each asset. 
 *      A geohash (https://en.wikipedia.org/wiki/Geohash) is a convenient way of expressing a location (anywhere in the world) 
 *      using a short alphanumeric string, with greater precision obtained with longer strings.
 *      You can generate/check geohashes from here: https://www.movable-type.co.uk/scripts/geohash.html
 */
contract BaseAsset is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // tokentId -> tokenUri
    mapping (uint256 => string) private _tokenURIs;

    // TODO: check if should use more efficient data type for geohashes since the lenght of geohash string is max of 12 characters (with 37.2mm×18.6mm precision)
    // geohash -> tokenId
    mapping (string => uint256) private _geohashTokens;

    constructor(string memory _name, string memory _symbol) public ERC721(_name, _symbol) {}
    
    /**
     * @dev Effectively grabs the token metadata uri
     * @param tokenId target token
     */
    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query of nonexistent token");
        return  _tokenURIs[tokenId];
    }

   
    /**
     * @dev Retrive tokenId associated with geohash
     * @param _geohash target geohash
     */
    function tokenFromGeohash(string memory _geohash) 
        public 
        view 
        returns (uint256)
    {
        require(_geohashExists(_geohash), "Geohash query of nonexistent geohash");
        return _geohashTokens[_geohash];
    }

     /**
     * @dev Retrive owner of geohash
     * @param _geohash target geohash
     */
    function ownerOfGeohash(string memory _geohash) 
        public 
        view 
        returns (address)
    {
        require(_geohashExists(_geohash), "Geohash query of nonexistent geohash");
        uint256 tokenId = tokenFromGeohash(_geohash);        
        return ownerOf(tokenId);
    }

    /**
     * @dev Generate unique tokenId
     */
    function _generateTokenId() 
        internal 
        returns (uint256)
    {
         _tokenIds.increment();
         return _tokenIds.current();
    }

    /**
     * @dev Sets the metadata associated with the token.
     * @param tokenId target token
     * @param _tokenURI url of metadata
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) 
        internal 
        virtual
    {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Sets a token for geohash   
     * @param _geohash geohash string
     * @param tokenId target token id
     */
    function _setTokenGeohash(uint256 tokenId, string memory _geohash) 
        internal
    {  
        require(_exists(tokenId), "Geohash set of nonexistent token");
        _geohashTokens[_geohash] = tokenId;
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

}
