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

    constructor() public ERC721("VLand", "LND") {}

    /// @dev Used create a new land nft with token url metadata
    /// @param to address for a receiver of newly created nft 
    /// @param _tokenURI url for token metadata
    function mintLand(address to, string memory _tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();          
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);          
        return newItemId;
    }

    /// @dev Sets the metadata associated with the token.
    /// @param tokenId target token id
    /// @param _tokenURI uri of metadata
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual
    {
        require(_exists(tokenId), "ERC721 Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    /// @dev Effectively grabs the token metadata uri
    /// @param tokenId target token
    function tokenURI(uint256 tokenId) public view virtual override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721 Metadata: URI query of nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }
}
