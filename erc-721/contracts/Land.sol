//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseAsset.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Contract for Land non fungible token
 * @author Oleh Andrushko (https://olich.me)
 * @dev 
 */
contract Land is BaseAsset {
    using SafeMath for uint256;

    uint256 private MIN_TOKEN_PRICE = 10000000000000000; // wei - 0.01 ether

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

    constructor() public BaseAsset("VLand", "LND721") {}
  
    /**
     * @dev Used create a new land nft with token url metadata and unique geohash
     * @param to address for a receiver of newly created nft 
     * @param _geohash geohash string
     * @param basePrice starting price for the nft in wei
     * @param _tokenURI url for token metadata
     */
    function createLand(address to, string memory _geohash, uint256 basePrice, string memory _tokenURI)
        public 
        onlyOwner
        returns (uint256)
    {        
        require(!_geohashExists(_geohash), "Geohash was already used, the land was already created");
        require(basePrice > MIN_TOKEN_PRICE, "Base price for the land should be grether than 0.01 ether");
       
        uint256 newItemId = _generateTokenId();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _setTokenGeohash(newItemId, _geohash);
        _setTokenPrice(newItemId, basePrice);
        return newItemId;
    }

    /**
     * @dev Buy a land with assets
     * @param _geohash target token geohash
     * TODO: too long and heavy function, need some refactoring here
     * TODO: add checks in case the caller is already a owner of one of assets
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
            totalPrice = SafeMath.add(totalPrice, assetPrice);
            assetPrices[i] = assetPrice;
        }
        require(msg.value == totalPrice, "Value does not match total price of land and it assets");

        // need to buy each asset throught asset contracts
        for (uint i = 0; i < assets.length; i++) 
        {
            BaseAsset(_assetAddresses[assets[i]]).buy{ value: assetPrices[i] }(assets[i], msg.sender);
        }

        // and finally buy the main land
        _buy(_geohash, msg.sender, mainLandPrice);
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
            totalPrice = SafeMath.add(totalPrice, assetPrice);
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
        _removeLandAsset(_landGeohash, _assetGeohash);
        delete _assetAddresses[_assetGeohash];
    }

    /**
     * @dev Remove an asset from the land array
     * @param _landGeohash land geohash
     * @param _assetGeohash asset geohash
     * @notice another a little bit expensive function
     */
    function _removeLandAsset(string memory _landGeohash, string memory _assetGeohash) 
        private
    {
        for(uint i = _indexOfAsset(_landGeohash, _assetGeohash); i < _landAssets[_landGeohash].length-1; i++){
            _landAssets[_landGeohash][i] = _landAssets[_landGeohash][i+1];      
        }
        _landAssets[_landGeohash].pop();
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
