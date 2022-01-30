//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseAsset.sol";
import "hardhat/console.sol";

/**
 * @title Contract for Land non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract Land is BaseAsset {

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

    uint256 public constant MIN_TOKEN_PRICE = 10000000000000000; // wei - 0.01 ether

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

    /****************************************|
    |   Assets Handling Functions            |
    |_______________________________________*/
    
    /**
     * @dev Buy a land with assets
     * @param _geohash target token geohash
     * TODO: too long and heavy function, need some refactoring here
     */
    function buyLandWithAssets(string memory _geohash) 
        public 
        payable
    {           
        // getting total price with assets
        uint mainLandPrice = priceOfGeohash(_geohash);
        uint256 totalPrice = mainLandPrice;

        string[] memory assets = assetsOf(_geohash);      
        uint256[] memory assetPrices = new uint256[](assets.length);
        for (uint i = 0; i < assets.length; i++) 
        {
            uint256 assetPrice = BaseAsset(_assetAddresses[assets[i]]).priceOfGeohash(assets[i]);
            totalPrice = SafeMathUpgradeable.add(totalPrice, assetPrice);
            assetPrices[i] = assetPrice;
        }
        require(msg.value == totalPrice, "Value does not match total price of land and it assets");

        // need to buy each asset throught asset contracts
        // batch buying associated items

        for (uint i = 0; i < assets.length; i++) 
        {
            BaseAsset(_assetAddresses[assets[i]]).buyAsset{ value: assetPrices[i] }(msg.sender, assets[i]);
        }
        // and finally buy the main land
        _buyAsset(msg.sender, _geohash, mainLandPrice);
    }

    /**
     * @dev Get assets
     * @param _landGeohash land geohash
     */
    function assetsOf(string memory _landGeohash)
        public
        view
        returns (string [] memory)
    {   
        require(_geohashExists(_landGeohash), "Asset query of nonexistent land"); 
        return _landAssets[_landGeohash];
    }
     /**
     * @dev Get complete price of land with assets
     * @param _geohash target token geohash
     */
    function priceWithAssetsOfGeohash(string memory _geohash) 
        public 
        view 
        returns (uint256)
    {
        uint256 totalPrice = priceOfGeohash(_geohash);
        string[] memory _assets = assetsOf(_geohash);
        for (uint i = 0; i < _assets.length; i++) 
        {
            uint256 assetPrice = BaseAsset(_assetAddresses[_assets[i]]).priceOfGeohash(_assets[i]);
            totalPrice = SafeMathUpgradeable.add(totalPrice, assetPrice);
        }

        return totalPrice;        
    }

    /**
     * @dev Add an asset to the land
     * @param _landGeohash land geohash
     * @param _assetGeohash asset geohash
     * @param _assetContractAddress the contract address of target asset geohash
     */
    function setAsset(string memory _landGeohash, string memory _assetGeohash, address _assetContractAddress)
        external 
        onlyOwner
    {   
        // ensure that the asset exist on target contract
        require(BaseAsset(_assetContractAddress).ownerOfGeohash(_assetGeohash) != address(0), "Asset does not exist on target contract");
        _setAsset(_landGeohash, _assetGeohash, _assetContractAddress);       
    }  

    /**
     * @dev Remove an asset from the land
     * @param _landGeohash land geohash
     * @param _assetGeohash asset geohash
     */
    function removeAsset(string memory _landGeohash, string memory _assetGeohash)
        external
        onlyOwner
    {   
        // ensure that land exists
        require(_geohashExists(_landGeohash), "Asset remove of nonexistent land");
        // ensure that the asset exists
        require(_assetAddresses[_assetGeohash] != address(0), "Asset remove of non existing asset");
        _removeAsset(_landGeohash, _assetGeohash);
        delete _assetAddresses[_assetGeohash];
    }

    /**
     * @dev Remove an asset from the land array
     * @param _landGeohash land geohash
     * @param _assetGeohash asset geohash
     * @notice another a little bit expensive function
     */
    function _removeAsset(string memory _landGeohash, string memory _assetGeohash) 
        private
    {
        for(uint i = _indexOfAsset(_landGeohash, _assetGeohash); i < _landAssets[_landGeohash].length-1; i++){
            _landAssets[_landGeohash][i] = _landAssets[_landGeohash][i+1];      
        }
        _landAssets[_landGeohash].pop();
    }

    /**
     * @dev Get index of land asset in a very bad way :)
     * @param _landGeohash land geohash code
     * @param _assetGeohash target asset geohash code
     */
    function _indexOfAsset(string memory _landGeohash, string memory _assetGeohash)
        private
        view
        returns (uint)
    {
        for (uint i = 0; i < _landAssets[_landGeohash].length; i++) 
        {
            string memory target = _landAssets[_landGeohash][i];
            if(keccak256(bytes(_assetGeohash)) == keccak256(bytes(target))) 
            {
                return i;
            }
        }
    }

     /**
     * @dev Add an asset to the land
     * @param _landGeohash land geohash
     * @param _assetGeohash asset geohash
     * @param _assetContractAddress the contract address of target asset geohash
     */
    function _setAsset(string memory _landGeohash, string memory _assetGeohash, address _assetContractAddress)
        private 
    {   
        // ensure that land exists
        require(_geohashExists(_landGeohash), "Asset set of nonexistent land");
        // ensure that the asset has NOT been already added to some land
        require(_assetAddresses[_assetGeohash] == address(0), "Asset has already been added");
       
        // add an asset to a land
        _landAssets[_landGeohash].push(_assetGeohash);
        // target contract for asset, may be needed for future uses
        _assetAddresses[_assetGeohash] = _assetContractAddress;
    }
}
