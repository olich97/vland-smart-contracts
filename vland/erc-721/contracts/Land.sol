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
// ERC721 standard extension for token metadata storage
// @notice A more flexible but more expensive way of storing metadata
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Land is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() public ERC721("VLand", "LND") {}

    /// @dev Used create a new land nft with token url metadata
    /// @param to address for a receiver of newly created nft 
    /// @param tokenURI url for token metadata
    function mintLand(address to, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();          
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);          
        return newItemId;
    }
}
