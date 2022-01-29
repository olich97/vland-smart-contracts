//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title A contract for handle base security functionalities for an asset that could have a bayer with contract address
 * @author Oleh Andrushko (https://olich.me)
 */
abstract contract AssetWithContractBuyer is OwnableUpgradeable {
    /**
     * @dev Mapping of addresses who are authorized to make calls on a special buy function 
     */
    mapping (address => bool) private _authorizedBuyers;

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
}
