
import {ethers, waffle} from 'hardhat';
import chai from 'chai';
import chaiAsPromised  from "chai-as-promised";

import landArtifact from '../artifacts/contracts/Land.sol/Land.json';
import {Land} from '../typechain-types/Land';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

import buildingArtifact from '../artifacts/contracts/Building.sol/Building.json';
import {Building} from '../typechain-types/Building';
import { Contract } from 'ethers';

const {deployContract} = waffle;
chai.use(chaiAsPromised);
const {expect} = chai;

describe('Land Contract', function () {
  let contractOwner: SignerWithAddress;
  let nftOwner1: SignerWithAddress;
  let nftOwner2: SignerWithAddress;
  let nftBuyer: SignerWithAddress;
  let contractOperator: SignerWithAddress;
  let landContract: Land;
  let landContractAddress: any;

  let buildingContractAddress: any;
  let buildingContract: Building;
  let buildingContractOwner: SignerWithAddress;
  let buildingNftOwner: SignerWithAddress;

  beforeEach(async () => {
    // eslint-disable-next-line no-unused-vars
    [contractOwner, nftOwner1, nftOwner2, contractOperator, buildingContractOwner, buildingNftOwner, nftBuyer] = await ethers.getSigners();

     // deploy land contract
     const genericLand = (await deployContract(contractOwner, landArtifact)) as Contract; 
     // some hooks in order to get deployed contract address (because I am not using a ethers factory here)
     landContractAddress = (await genericLand.deployed()).address;
     landContract = genericLand as unknown as Land;

     // deploy building contract
     const genericBuilding= (await deployContract(buildingContractOwner, buildingArtifact)) as Contract; 
     // some hooks in order to get deployed contract address (because I am not using a ethers factory here)
     buildingContractAddress = (await genericBuilding.deployed()).address;
     buildingContract = genericBuilding as unknown as Building;     
  });

  describe('Deployment', function () {
    it("should set the right contract owner", async () => {
      expect(await landContract.owner()).to.equal(contractOwner.address);
    });
  });
  
  describe('Minting', function () {  
    const landNftGeohash = 'spyvvmnh';
    const landNftUrl = 'http://www.example.com/tokens/1/metadata.json';
    const landNftId = 1;
    const landNftPrice = ethers.utils.parseEther('0.03'); 
    const buildingNftPrice = ethers.utils.parseEther('0.02'); 
    const buildingNftGeohash = 'builds324';

    beforeEach(async () => {    
      expect(
        await landContract.connect(contractOwner).createLand(nftOwner1.address, landNftGeohash, landNftPrice, landNftUrl)
      )
      .to.emit(landContract, "Transfer")
      .withArgs(ethers.constants.AddressZero, nftOwner1.address, landNftId);

      // create a building nft 
      await buildingContract.connect(buildingContractOwner)
                            .createBuilding(buildingNftOwner.address, buildingNftGeohash, buildingNftPrice, 'buildingNftUrl');
    });

    it("should set metadata url", async function () {
      const tokenUri = await landContract.tokenURI(landNftId);
      expect(tokenUri).to.equal(landNftUrl);
    });

    it("should set token owner", async function () { 
      const tokenOwner = await landContract.ownerOf(landNftId);
      expect(tokenOwner).to.equal(nftOwner1.address);
    });

    it("should set geohash", async function () {
      const geohashTokenId = await landContract.tokenFromGeohash(landNftGeohash);
      expect(geohashTokenId).to.equal(landNftId);
    });

    it("should set geohash owner", async function () {
       const tokenGeohashOwner = await landContract.ownerOfGeohash(landNftGeohash);
       expect(tokenGeohashOwner).to.equal(nftOwner1.address);
    });   

    it("should set price", async function () {
      const geohashPrice= await landContract.priceOfGeohash(landNftGeohash);
      expect(geohashPrice).to.equal(landNftPrice);
    });

    it("should set price with assets", async function () {
      await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      const geohashPrice = await landContract.priceWithAssetsOfGeohash(landNftGeohash);
      expect(geohashPrice).to.equal(landNftPrice.add(buildingNftPrice));
    });

    it("should fail if create with the same geohash", async function () {      
      const tokenGeohash = 'spyvvmnh'; //https://www.movable-type.co.uk/scripts/geohash.html
      const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';

      await expect(
        landContract.createLand(nftOwner1.address, tokenGeohash, landNftPrice, tokenMetadataUrl)
      ).to.eventually.be.rejectedWith('Geohash was already used, the land was already created');
    });

    it("should set asset", async function () {      
      await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      const assets = await landContract.assetsOf(landNftGeohash);
      expect(assets.length).to.equal(1);
      expect(assets[0]).to.equal(buildingNftGeohash);
    });

    it("should fail if set same asset twice", async function () {    
      // first one  
      await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      
      await expect(
         landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress)
      ).to.eventually.be.rejectedWith('Asset has already been added');
    });

    it("should remove asset", async function () {     
      // need to add one first 
      await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      const assets = await landContract.assetsOf(landNftGeohash);
      expect(assets.length).to.equal(1);
      expect(assets[0]).to.equal(buildingNftGeohash);
      // removing and check
      await landContract.removeAsset(landNftGeohash, buildingNftGeohash);
      const assetsLater = await landContract.assetsOf(landNftGeohash);
      expect(assetsLater.length).to.equal(0);
    });
    
  });

  describe('Transfer', function () {  
    const landNftGeohash = 'spyvvmnh';
    const landNftUrl = 'http://www.example.com/tokens/1/metadata.json';
    const landNftId = 1;
    const landNftPrice = ethers.utils.parseEther('0.03'); 
    const buildingNftPrice = ethers.utils.parseEther('0.01'); 
    const buildingNftGeohash = 'builds324';

    beforeEach(async () => {    
      expect(
        await landContract.connect(contractOwner).createLand(nftOwner1.address, landNftGeohash, landNftPrice, landNftUrl)
      )
      .to.emit(landContract, "Transfer")
      .withArgs(ethers.constants.AddressZero, nftOwner1.address, landNftId);

      // create a building nft 
      await buildingContract.connect(buildingContractOwner)
                            .createBuilding(buildingNftOwner.address, buildingNftGeohash, buildingNftPrice, 'buildingNftUrl');

      await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);

      // set land contract as authorized buyer on asset contract (building)
      await buildingContract.setAuthorizedBuyer(landContractAddress, true);
    });

    it("should buy the land", async function () {
      // prepare
      const currentBalance = await nftOwner1.getBalance();
      const finalBalance = currentBalance.add(landNftPrice);
      // perform buying
      await landContract.connect(nftOwner2)['buy(string)'](landNftGeohash,  {
        value: landNftPrice,
      });
      // check new owner
      const newOwner = await landContract.ownerOfGeohash(landNftGeohash);
      expect(newOwner).to.equal(nftOwner2.address);
      expect(await landContract.balanceOf(nftOwner1.address)).to.be.equal(0);
      expect(await landContract.balanceOf(nftOwner2.address)).to.be.equal(1);
      // check if money transfer worked
      expect(await nftOwner1.getBalance()).to.be.equal(finalBalance);
    });

    it("should buy the land with assets", async function () {

      // Actors:
      // nftOwner1: a owner of a land
      // buildingNftOwner: a owner of a building associated to the land
      // nftBuyer:  a guy who want to buy all the staff

       // prepare
      const landOwnerBalance = await nftOwner1.getBalance();
      const endLandOwnerBalance = landOwnerBalance.add(landNftPrice);
      const buildingOwnerBalance = await buildingNftOwner.getBalance();
      const endBuildingOwnerBalance = buildingOwnerBalance.add(buildingNftPrice);

      // perform buying
      const totalPrice = landNftPrice.add(buildingNftPrice);
      await landContract.connect(nftBuyer).buyLandWithAssets(landNftGeohash,  {
        value: totalPrice,
      });
      // check new owner
      const newOwner = await landContract.ownerOfGeohash(landNftGeohash);
      expect(newOwner).to.equal(nftBuyer.address);
      expect(await landContract.balanceOf(nftOwner1.address)).to.be.equal(0);
      expect(await landContract.balanceOf(nftBuyer.address)).to.be.equal(1);

      const newBuildingOwner = await buildingContract.ownerOfGeohash(buildingNftGeohash);
      expect(newBuildingOwner).to.equal(nftBuyer.address);
      expect(await buildingContract.balanceOf(nftOwner1.address)).to.be.equal(0);
      expect(await buildingContract.balanceOf(nftBuyer.address)).to.be.equal(1);

      // check if money transfer worked
      expect(await nftOwner1.getBalance()).to.be.equal(endLandOwnerBalance);
      expect(await buildingNftOwner.getBalance()).to.be.equal(endBuildingOwnerBalance);
    });
  });
});