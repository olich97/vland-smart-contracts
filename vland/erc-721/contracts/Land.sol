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

contract Land is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // tokentId -> tokenUri
    mapping (uint256 => string) private _tokenURIs;

    // in order to have more uniqueness for tokens
    // geohash -> tokentId: https://en.wikipedia.org/wiki/Geohash
    mapping (string => uint256) private _geohashTokens;

    constructor() public ERC721("VLand", "LND") {}

    /**
     * @dev Used create a new land nft with token url metadata
     * @param to address for a receiver of newly created nft 
     * @param _geohash url for token metadata
     * @param _tokenURI url for token metadata
     */
    function mintLand(address to, string memory _geohash, string memory _tokenURI)
        public 
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();          
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI); 
        _setGeohashToken(_geohash, newItemId);            
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
     * @dev Sets the metadata associated with the token.
     * @param tokenId target token
     * @param _tokenURI uri of metadata
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
    function _setGeohashToken(string memory _geohash, uint256 tokenId) 
        internal
    {
        require(_exists(tokenId), "Geohash set of nonexistent token");
        require(_geohashExists(_geohash), "Geohash was already used, the land was already minted");
        _geohashTokens[_geohash] = tokenId;
    }

    function _geohashExists(string memory _geohash) 
        internal
        view 
        returns (bool)
    {        
        if(_geohashTokens[_geohash] == 0) {
            return false;
        }
        
        return true;
    }

}
