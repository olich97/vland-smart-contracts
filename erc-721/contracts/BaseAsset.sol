//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    /**
     * @dev Mapping of addresses who are authorized to make calls on a special buy function 
     */
    mapping (address => bool) private _authorizedBuyers;

    /**
     * @dev mapping from tokentId to tokenUri
     */
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev mapping from tokentId to price
     */
    mapping (uint256 => uint256) private _tokenPrices;

    /**
     * @dev mapping from geohash to tokenId
     */
    mapping (string => uint256) private _geohashTokens;

    constructor(string memory _name, string memory _symbol) public ERC721(_name, _symbol) {}
    
    /**
     * @dev Throws then sender is not the owner of token
     */
    modifier onlyTokenOwner(string memory _geohash) 
    {
        require(msg.sender == ownerOfGeohash(_geohash), "Caller is not the owner of the geohash");
        _;
    }

    /**
     * @dev Throws then the sender is not an authorized buyer
     */
    modifier onlyAuthorizedBuyer() 
    {
        require(_authorizedBuyers[msg.sender], "Caller is not an authorized buyer");
        _;
    }
   
    /**
     * @dev Add an address to authorized buyers
     * @param contractAddress target address
     * @param isAuthorized  is authorized
     */
    function setAuthorizedBuyer(address contractAddress, bool isAuthorized)
        external 
        onlyOwner
    {            
        _authorizedBuyers[contractAddress] = isAuthorized;
    }

     /**
     * @dev Buy an asset
     * @param _geohash target token geohash
     */
    function buy(string memory _geohash) 
        public 
        payable
    {
        _buy(_geohash, msg.sender, msg.value);
    }

     /**
     * @dev Buy an asset (used from the land contract) on beahalf a new owner
     * @param _geohash target token geohash
     * @notice only authorized buyers (e.g. land cantract address) can call the function
     */
    function buy(string memory _geohash, address newOwner) 
        external 
        payable
        onlyAuthorizedBuyer
    {
        _buy(_geohash, newOwner, msg.value);
    }

     /**
     * @dev Buy an asset
     * @param _geohash target token geohash
     * @param newOwner new owner
     * @param amount price for the token
     * TODO: need to check if the caller is already a owner of token
     */
    function _buy(string memory _geohash, address newOwner, uint256 amount) 
        internal
    {
        uint256 price = priceOfGeohash(_geohash);
        require(amount == price, "Value does not match the token price");
        uint256 tokenId = tokenFromGeohash(_geohash);
        address tokenOwner = ownerOf(tokenId);
        // transfer nft to new owner (caller)
        // TODO: maybe need to use safeTransferFrom instead
        _transfer(tokenOwner, newOwner, tokenId);
        // send cash to the old owner
        Address.sendValue(payable(tokenOwner), amount);
    }


    /**
     * @dev Set the price for the token
     * @param _geohash target token geohash
     * @param price new price for the token
     * @notice only owner of the nft can modify the price
     */
    function setTokenPrice(string memory _geohash, uint256 price) 
        public 
        onlyTokenOwner(_geohash)
    {
        uint256 tokenId = tokenFromGeohash(_geohash);
        _setTokenPrice(tokenId, price);
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
     * @dev Effectively grabs the metadata uri of a geohash
     * @param _geohash asset geohash
     */
    function tokenURIofGeohash(string memory _geohash) 
        public 
        view 
        returns (string memory)
    {
        uint256 tokenId = tokenFromGeohash(_geohash);
        return tokenURI(tokenId);
    }

    /**
     * @dev Get token price
     * @param _geohash asset geohash
     */
    function priceOfGeohash(string memory _geohash) 
        public 
        view 
        returns (uint256)
    {
        uint256 tokenId = tokenFromGeohash(_geohash);
        return _tokenPrices[tokenId];
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
     * @dev Sets the price for the token
     * @param tokenId target token
     * @param price price in ethers
     */
    function _setTokenPrice(uint256 tokenId, uint256 price) 
        internal 
        virtual
    {
        require(_exists(tokenId), "Price set of nonexistent token");        
        _tokenPrices[tokenId] = price;
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
