//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./BaseAsset.sol";

/**
 * @title UNUSED Contract: needed only for TESTING upgradability in unit tests
 * @author Oleh Andrushko (https://olich.me)
 */
contract LandV2 is BaseAsset {
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

    string private greeting;
    
     /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory _uri) initializer public {        
        console.log("Deploying a LandV2 with uri:", _uri);
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
     * @dev a new function added in order to test upgradability
     */
    function greet() public pure returns (string memory) {
        return "Hello MasterZ";
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
        return 10000000000000000000;
    }
}
