
import {ethers, waffle, upgrades} from 'hardhat';
import chai from 'chai';
import chaiAsPromised  from "chai-as-promised";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import {
    Land__factory,
    Land,
    LandV2,
    Building__factory,
    Building,
  } from "../typechain-types";

const {deployContract} = waffle;
chai.use(chaiAsPromised);
const {expect} = chai;

describe('Land Contract', function () {
  let contractOwner: SignerWithAddress;
  let nftOwner1: SignerWithAddress;
  let nftOwner2: SignerWithAddress;
  let nftBuyer: SignerWithAddress;
  let buildingNftOwner: SignerWithAddress;
  let Land: Land;
  let Building: Building;
  let buildingContractAddress: string;
  let landContractAddress: string;

  const landNftUrl = 'http://www.example.com/tokens/1/metadata.json';

  beforeEach(async () => {
    [contractOwner, nftOwner1, nftOwner2, nftBuyer, buildingNftOwner] = await ethers.getSigners();

    const BaseFactory = (await ethers.getContractFactory(
      "Land",
      contractOwner
    )) as Land__factory;
    Land = (await upgrades.deployProxy(BaseFactory, [landNftUrl], {
      initializer: "initialize",
    })) as Land;
    await Land.deployed();

    landContractAddress = (await Land.deployed()).address;

    const buildingFactory = (await ethers.getContractFactory(
        "Building",
        contractOwner
    )) as Building__factory;
    Building = (await upgrades.deployProxy(buildingFactory, ['buildingNftUrl'], {
      initializer: "initialize",
    })) as Building;
    buildingContractAddress = (await Building.deployed()).address;

    // The owners of nfts need to approve their buyers or an external operator
    await Land.connect(nftOwner1).setApprovalForAll(nftOwner2.address, true);
    await Land.connect(nftOwner1).setApprovalForAll(nftBuyer.address, true);  
  });


  describe('Deployment', function () {
    it("should set the right contract owner", async () => {
      expect(await Land.owner()).to.equal(contractOwner.address);
    });
  });
  
  describe('Minting & Buying', function () {  
    const landNftGeohash = 'spyvvmnh';
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
      await Building.connect(contractOwner)
                    .createBuilding(buildingNftOwner.address, buildingNftGeohash, buildingNftPrice);

      // Also need to approve land contract address for building
      await Building.connect(buildingNftOwner).setApprovalForAll(landContractAddress, true);
      // and buyer
      await Building.connect(buildingNftOwner).setApprovalForAll(nftBuyer.address, true);
    });

    it("should set metadata url", async function () {
      const tokenUri = await Land.uri(landNftId);
      expect(tokenUri).to.equal(landNftUrl);
    });

    it("should set geohash", async function () {
      const geohashTokenId = await Land.tokenOfGeohash(landNftGeohash);
      expect(geohashTokenId).to.equal(landNftId);
    });

    it("should set geohash owner", async function () {
       const tokenGeohashOwner = await Land.ownerOfGeohash(landNftGeohash);
       expect(tokenGeohashOwner).to.equal(nftOwner1.address);
    });   

    it("should set price", async function () {
      const geohashPrice= await Land.priceOfGeohash(landNftGeohash);
      expect(geohashPrice).to.equal(landNftPrice);
    });

    it("should create many lands", async function () {
        await expect(
          await Land.connect(contractOwner).createManyLands(nftOwner2.address, 
            ['geo1', 'geo2', 'geo3'], [ethers.utils.parseEther('0.015'), ethers.utils.parseEther('0.02'), ethers.utils.parseEther('0.03')])
        )
        .to.emit(Land, "TransferBatch")
        .withArgs(contractOwner.address, ethers.constants.AddressZero, nftOwner2.address, [2, 3, 4], [1, 1, 1]);
        const geohashesPrice= await Land.priceOfGeohashes(['geo1', 'geo2', 'geo3']);
        expect(geohashesPrice).to.equal(ethers.utils.parseEther('0.065'));
        expect(await Land.balanceOf(nftOwner2.address, 2)).to.be.equal(1);
        expect(await Land.balanceOf(nftOwner2.address, 3)).to.be.equal(1);
        expect(await Land.balanceOf(nftOwner2.address, 4)).to.be.equal(1);
    });

    it("should set price with assets", async function () {
      await Land.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      const geohashPrice = await Land.priceWithAssetsOfGeohash(landNftGeohash);
      expect(geohashPrice).to.equal(landNftPrice.add(buildingNftPrice));
    });

    it("should fail if create with the same geohash", async function () {      
      const tokenGeohash = 'spyvvmnh'; //https://www.movable-type.co.uk/scripts/geohash.html
      await expect(
        Land.createLand(nftOwner1.address, tokenGeohash, landNftPrice)
      ).to.eventually.be.rejectedWith('The asset was already created for geohash');
    });

    it("should set asset", async function () {      
      await Land.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      const assets = await Land.assetsOf(landNftGeohash);
      expect(assets.length).to.equal(1);
      expect(assets[0]).to.equal(buildingNftGeohash);
    });

    it("should fail if set same asset twice", async function () {    
      // first one  
      await Land.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      
      await expect(
        Land.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress)
      ).to.eventually.be.rejectedWith('Asset has already been added');
    });

    it("should remove asset", async function () {     
      // need to add one first 
      await Land.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      const assets = await Land.assetsOf(landNftGeohash);
      expect(assets.length).to.equal(1);
      expect(assets[0]).to.equal(buildingNftGeohash);
      // removing and check
      await Land.removeAsset(landNftGeohash, buildingNftGeohash);
      const assetsLater = await Land.assetsOf(landNftGeohash);
      expect(assetsLater.length).to.equal(0);
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

    it("should fail buy if incorrect price", async function () {
      // perform buying
      await expect(
        Land.connect(nftOwner2).buyLand(landNftGeohash,  {
          value: ethers.utils.parseEther('1'),
        })
      ).to.be.eventually.rejectedWith('Value does not match the token price');
      
      // check new owner
      const newOwner = await Land.ownerOfGeohash(landNftGeohash);
      expect(newOwner).to.equal(nftOwner1.address);
      expect(await Land.balanceOf(nftOwner1.address, landNftId)).to.be.equal(1);
    });

    it("should buy the land with assets", async function () {

      // Actors:
      // nftOwner1: a owner of a land
      // buildingNftOwner: a owner of a building associated to the land
      // nftBuyer:  a guy who want to buy all the staff

      // link asset to the land
      await Land.setAsset(landNftGeohash, buildingNftGeohash, buildingContractAddress);
      // prepare
      const landOwnerBalance = await nftOwner1.getBalance();
      const endLandOwnerBalance = landOwnerBalance.add(landNftPrice);
      const buildingOwnerBalance = await buildingNftOwner.getBalance();
      const endBuildingOwnerBalance = buildingOwnerBalance.add(buildingNftPrice);

      // perform buying
      const totalPrice = landNftPrice.add(buildingNftPrice);
      await Land.connect(nftBuyer).buyLandWithAssets(landNftGeohash,  {
        value: totalPrice,
      });
      // check new owner
      const newOwner = await Land.ownerOfGeohash(landNftGeohash);
      expect(newOwner).to.equal(nftBuyer.address);
      expect(await Land.balanceOf(nftOwner1.address, 1)).to.be.equal(0);
      expect(await Land.balanceOf(nftBuyer.address, 1)).to.be.equal(1);

      const newBuildingOwner = await Building.ownerOfGeohash(buildingNftGeohash);
      expect(newBuildingOwner).to.equal(nftBuyer.address);
      expect(await Building.balanceOf(nftOwner1.address, 1)).to.be.equal(0);
      expect(await Building.balanceOf(nftBuyer.address, 1)).to.be.equal(1);

      // check if money transfer worked
      expect(await nftOwner1.getBalance()).to.be.equal(endLandOwnerBalance);
      expect(await buildingNftOwner.getBalance()).to.be.equal(endBuildingOwnerBalance);
    });
  });
});