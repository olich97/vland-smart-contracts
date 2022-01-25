//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseAsset.sol";

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

    /**
     * @dev Mapping of address of contracts that are authorized to make some calls  
     */
    mapping (address => bool) private _authorizedAddresses;

    constructor() public BaseAsset("VLand", "LND") {}

    /**
     * @dev Throws the address is not authorized
     */
    modifier OnlyAuthorizedContract() 
    {
        require(_authorizedAddresses[msg.sender], "Not allowed caller address");
        _;
    }

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
       
        uint256 newItemId = _generateTokenId();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _setTokenGeohash(newItemId, _geohash);
        return newItemId;
    }

    /**
     * @dev Set the land (parent) contract address
     * @param contractAddress target address
     * @param isAuthorized  is authorized
     */
    function setAuthorizedContract(address contractAddress, bool isAuthorized)
        external 
        onlyOwner
    {            
        _authorizedAddresses[contractAddress] = isAuthorized;
    }

    /**
     * @dev Add an asset to the land
     * @param _landGeohash land geohash
     * @param _assetGeohash asset geohash
     * @param _assetContractAddress the contract address of target asset geohash
     */
    function addAsset(string memory _landGeohash, string memory _assetGeohash, address _assetContractAddress)
        external 
        onlyOwner
    {   
        // ensure that the asset exist on target contract
        require(BaseAsset(_assetContractAddress).ownerOfGeohash(_assetGeohash) != address(0), "Asset does not exist on target contract");
        _addAsset(_landGeohash, _assetGeohash, _assetContractAddress);
    }  

    /**
     * @dev Add an asset to the land
     * @param _landGeohash land geohash
     * @param _assetGeohash asset geohash
     */
    function addAssetFromChild(string memory _landGeohash, string memory _assetGeohash)
        external 
        OnlyAuthorizedContract
    {   
       _addAsset(_landGeohash, _assetGeohash, msg.sender);
    }    

    /**
     * @dev Get assets
     * @param _landGeohash land geohash
     */
    function assetsOf(string memory _landGeohash)
        external
        view
        returns (string [] memory)
    {   
        require(_geohashExists(_landGeohash), "Asset query of nonexistent land"); 
        return _landAssets[_landGeohash];
    }

    /**
     * @dev Remove an asset from the land
     * @param _landGeohash land geohash
     * @param _assetGeohash asset geohash
     */
    function _removeAsset(string memory _landGeohash, string memory _assetGeohash)
        private
    {   
        // ensure that land exists
        require(_geohashExists(_landGeohash), "Asset remove of nonexistent land");
        // ensure that the asset exists
        require(_assetAddresses[_assetGeohash] != address(0), "Asset remove of non existing asset");
       
        // remove asset
        delete _landAssets[_landGeohash][_indexOfAsset(_landGeohash, _assetGeohash)];
        delete _assetAddresses[_assetGeohash];
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
    function _addAsset(string memory _landGeohash, string memory _assetGeohash, address _assetContractAddress)
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
