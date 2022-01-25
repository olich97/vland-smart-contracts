
import {ethers, waffle} from 'hardhat';
import chai from 'chai';
import chaiAsPromised  from "chai-as-promised";

import buildingArtifact from '../artifacts/contracts/Building.sol/Building.json';
import {Building} from '../typechain-types/Building';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

import landArtifact from '../artifacts/contracts/Land.sol/Land.json';
import {Land} from '../typechain-types/Land';
import { Contract } from 'ethers';

const {deployContract} = waffle;
chai.use(chaiAsPromised);
const {expect} = chai;

describe('Building Contract', function () {
  let contractOwner: SignerWithAddress;
  let nftOwner1: SignerWithAddress;
  let nftOwner2: SignerWithAddress;
  let contractOperator: SignerWithAddress;

  let buildingContract: Building;

  let landContractOwner: SignerWithAddress;
  let landContractAddress: any;
  let landContract: Land;  
  let landNftOwner: SignerWithAddress;  

  beforeEach(async () => {
    // eslint-disable-next-line no-unused-vars
    [contractOwner, nftOwner1, nftOwner2, contractOperator, landContractOwner, landNftOwner] = await ethers.getSigners();

    const genericBuilding = (await deployContract(contractOwner, buildingArtifact)) as Contract; 
     // some hooks in order to get deployed contract address (because I am not using a ethers factory here)
    const buildingContractAddress = (await genericBuilding.deployed()).address;
    buildingContract = genericBuilding as unknown as Building;
    // approve operator for token transfers
    await buildingContract.connect(nftOwner1).setApprovalForAll(contractOperator.address, true);

    // deploy land contract
    const genericLand = (await deployContract(landContractOwner, landArtifact)) as Contract; 
    // some hooks in order to get deployed contract address (because I am not using a ethers factory here)
    landContractAddress = (await genericLand.deployed()).address;
    landContract = genericLand as unknown as Land;
    // link two contracts    
    buildingContract.setLandContract(landContractAddress);

    // authorize building contract to make calls on land contract    
    landContract.setAuthorizedContract(buildingContractAddress, true);
  });

  describe('Deployment', function () {
    it("should set the right contract owner", async () => {
      expect(await buildingContract.owner()).to.equal(contractOwner.address);
    });

    it("should set land contract address", async function () {
      const contractAddress = await buildingContract.landContractAddress();     
      expect(contractAddress).to.equal(landContractAddress);
    });
  }); 
  
  describe('Minting', function () { 
    const buildingNftGeohash = 'spyvvmnh';
    const buildingNftUrl = 'http://www.example.com/tokens/1/metadata.json';
    const buildingNftId = 1;  
    const landNftGeohash = 'spyvvmn';

    beforeEach(async () => {    
      expect(
        await buildingContract.connect(contractOwner).createBuilding(nftOwner1.address, buildingNftGeohash, buildingNftUrl)
      )
      .to.emit(buildingContract, "Transfer")
      .withArgs(ethers.constants.AddressZero, nftOwner1.address, buildingNftId);

      // create a land nft 
      await landContract.connect(landContractOwner).createLand(landNftOwner.address, landNftGeohash, 'landNftUrl');
    });
    
    it("should set metadata url", async function () {
      const tokenUri = await buildingContract.tokenURI(buildingNftId);     
      expect(tokenUri).to.equal(buildingNftUrl);    
    });

    it("should set token owner", async function () {
      const tokenOwner = await buildingContract.ownerOf(buildingNftId);
      expect(tokenOwner).to.equal(nftOwner1.address);
    });

    it("should set geohash", async function () {
      const geohashTokenId = await buildingContract.tokenFromGeohash(buildingNftGeohash);
      expect(geohashTokenId).to.equal(buildingNftId);
    });

    it("should set geohash owner", async function () {
       const tokenGeohashOwner = await buildingContract.ownerOfGeohash(buildingNftGeohash);
       expect(tokenGeohashOwner).to.equal(nftOwner1.address);
    });   

    it("should fail if create with the same geohash", async function () {      
      const tokenGeohash = 'spyvvmnh'; //https://www.movable-type.co.uk/scripts/geohash.html
      const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';

      await expect(
        buildingContract.createBuilding(nftOwner1.address, tokenGeohash, tokenMetadataUrl)
      ).to.eventually.be.rejectedWith('Geohash was already used, the building was already created');
    });
    
    it("should add land nft witch assets", async function () {
      await buildingContract.addBuildingToLand(buildingNftGeohash, landNftGeohash);
      const langGeohash = await buildingContract.landOf(buildingNftGeohash);
      expect(langGeohash).to.equal(landNftGeohash);
      // check land assets
      const assetsOfLand = await landContract.assetsOf(landNftGeohash);
      expect(assetsOfLand.length).to.equal(1);
      expect(assetsOfLand[0]).to.equal(buildingNftGeohash);
    });

    it("should create building on land", async function () {
     await buildingContract.createBuildingOnLand(nftOwner2.address, 'busd23', landNftGeohash, 'uri');
     const langGeohash = await buildingContract.landOf('busd23');
     expect(langGeohash).to.equal(landNftGeohash);
     // check land assets
     const assetsOfLand = await landContract.assetsOf(landNftGeohash);
     expect(assetsOfLand.length).to.equal(1);
     expect(assetsOfLand[0]).to.equal('busd23');
    });
  });

  describe('Transfer', function () {    
    it("should transfer token between accounts", async function () {
      const buildingOperations = await buildingContract.connect(contractOwner);      
      await buildingOperations.createBuilding(nftOwner1.address, 'sadsa2', 'http://www.example.com/tokens/1/metadata.json');
      const tokenId = await buildingOperations.tokenFromGeohash('sadsa2');   

      await buildingContract.connect(contractOperator)['safeTransferFrom(address,address,uint256)'](nftOwner1.address, nftOwner2.address, tokenId);
      
      // check new owner
      const newOwner = await buildingOperations.ownerOfGeohash('sadsa2');
      expect(newOwner).to.equal(nftOwner2.address);
      expect(await buildingOperations.balanceOf(nftOwner1.address)).to.be.equal(0);
    });
  });
});