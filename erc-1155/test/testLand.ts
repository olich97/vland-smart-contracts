
import {ethers, waffle, upgrades} from 'hardhat';
import chai from 'chai';
import chaiAsPromised  from "chai-as-promised";
import { Contract } from 'ethers';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import {
    Land__factory,
    Land,
    LandV2,
  } from "../typechain-types";

const {deployContract} = waffle;
chai.use(chaiAsPromised);
const {expect} = chai;

describe('Land Contract', function () {
  let contractOwner: SignerWithAddress;
  let nftOwner1: SignerWithAddress;
  let nftOwner2: SignerWithAddress;
  let nftBuyer: SignerWithAddress;
  let Land: Land;

  const landGeohash = "geo2sds";

  beforeEach(async () => {
    [contractOwner, nftOwner1, nftOwner2, nftBuyer] = await ethers.getSigners();

    const BaseFactory = (await ethers.getContractFactory(
      "Land",
      contractOwner
    )) as Land__factory;
    Land = (await upgrades.deployProxy(BaseFactory, ['my.first.uri'], {
      initializer: "initialize",
    })) as Land;
    await Land.deployed();

    await Land.createLand(nftOwner1.address, landGeohash, ethers.utils.parseEther('0.02'));
  });


  describe('Deployment', function () {
    it("should set the right contract owner", async () => {
      expect(await Land.owner()).to.equal(contractOwner.address);
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
      await expect(
        await Land.connect(contractOwner).createLand(nftOwner1.address, landNftGeohash, landNftPrice)
      )
      .to.emit(Land, "TransferSingle")
      .withArgs(contractOwner.address, ethers.constants.AddressZero, nftOwner1.address, landNftId, 1);

      // create a building nft 
      //await buildingContract.connect(buildingContractOwner)
      //                      .createBuilding(buildingNftOwner.address, buildingNftGeohash, buildingNftPrice, 'buildingNftUrl');
    });

    it("should set metadata url", async function () {
      const tokenUri = await Land.uri(landNftId);
      expect(tokenUri).to.equal(landNftUrl);
    });

    it("should set geohash", async function () {
      const geohashTokenId = await Land.tokenOfGeohash(landNftGeohash);
      expect(geohashTokenId).to.equal(landNftId);
    });

    //it("should set geohash owner", async function () {
    //   const tokenGeohashOwner = await Land.ownerOfGeohash(landNftGeohash);
    //   expect(tokenGeohashOwner).to.equal(nftOwner1.address);
    //});   

    it("should set price", async function () {
      const geohashPrice= await Land.priceOfGeohash(landNftGeohash);
      expect(geohashPrice).to.equal(landNftPrice);
    });

    //it("should set price with assets", async function () {
    //  await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
    //  const geohashPrice = await landContract.priceWithAssetsOfGeohash(landNftGeohash);
    //  expect(geohashPrice).to.equal(landNftPrice.add(buildingNftPrice));
    //});

    it("should fail if create with the same geohash", async function () {      
      const tokenGeohash = 'spyvvmnh'; //https://www.movable-type.co.uk/scripts/geohash.html
      await expect(
        Land.createLand(nftOwner1.address, tokenGeohash, landNftPrice)
      ).to.eventually.be.rejectedWith('The asset was already created for geohash');
    });

    //it("should set asset", async function () {      
    //  await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
    //  const assets = await landContract.assetsOf(landNftGeohash);
    //  expect(assets.length).to.equal(1);
    //  expect(assets[0]).to.equal(buildingNftGeohash);
    //});

    //it("should fail if set same asset twice", async function () {    
    //  // first one  
    //  await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
    //  
    //  await expect(
    //     landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress)
    //  ).to.eventually.be.rejectedWith('Asset has already been added');
    //});

    //it("should remove asset", async function () {     
    //  // need to add one first 
    //  await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
    //  const assets = await landContract.assetsOf(landNftGeohash);
    //  expect(assets.length).to.equal(1);
    //  expect(assets[0]).to.equal(buildingNftGeohash);
    //  // removing and check
    //  await landContract.removeAsset(landNftGeohash, buildingNftGeohash);
    //  const assetsLater = await landContract.assetsOf(landNftGeohash);
    //  expect(assetsLater.length).to.equal(0);
    //});
    
  });

  describe('Transfer', function () {  
    const landNftGeohash = 'spyvvmnh';
    const landNftUrl = 'http://www.example.com/tokens/1/metadata.json';
    const landNftId = 1;
    const landNftPrice = ethers.utils.parseEther('0.03'); 
    const buildingNftPrice = ethers.utils.parseEther('0.01'); 
    const buildingNftGeohash = 'builds324';

    beforeEach(async () => {    
      await expect(
        await Land.connect(contractOwner).createLand(nftOwner1.address, landNftGeohash, landNftPrice)
      )
      .to.emit(Land, "TransferSingle")
      .withArgs(contractOwner.address, ethers.constants.AddressZero, nftOwner1.address, landNftId, 1);

      // create a building nft 
      //await buildingContract.connect(buildingContractOwner)
      //                      .createBuilding(buildingNftOwner.address, buildingNftGeohash, buildingNftPrice, 'buildingNftUrl');
//
      //await landContract.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
//
      //// set land contract as authorized buyer on asset contract (building)
      //await buildingContract.setAuthorizedBuyer(landContractAddress, true);
    });

    it("should buy the land", async function () {
      // prepare
      const currentBalance = await nftOwner1.getBalance();
      const finalBalance = currentBalance.add(landNftPrice);
      // perform buying
      await Land.connect(nftOwner2).buyLand(landNftGeohash,  {
        value: landNftPrice,
      });
      // check new owner
      const newOwner = await Land.ownerOfGeohash(landNftGeohash);
      expect(newOwner).to.equal(nftOwner2.address);
      expect(await Land.balanceOf(nftOwner1.address, landNftId)).to.be.equal(0);
      expect(await Land.balanceOf(nftOwner2.address, landNftId)).to.be.equal(1);
      // check if money transfer worked
      expect(await nftOwner1.getBalance()).to.be.equal(finalBalance);
    });
/*
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
*/
  });
});