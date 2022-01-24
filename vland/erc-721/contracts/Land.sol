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
 * @title Contract for Land non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev In combination with land metadata, the contact store (on-chain) a geohash (https://en.wikipedia.org/wiki/Geohash) 
 *      unique string for each land. The geohash code could be useful for uniqueness of land tokens
 */
contract Land is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // tokentId -> tokenUri
    mapping (uint256 => string) private _tokenURIs;

    // geohash -> tokenId
    mapping (string => uint256) private _geohashTokens;

    constructor() public ERC721("VLand", "LND") {}

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
        _tokenIds.increment();          
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _setTokenGeohash(newItemId, _geohash);
        return newItemId;
    }
      
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
        uint256 tokenId = this.tokenFromGeohash(_geohash);        
        return super.ownerOf(tokenId);
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
