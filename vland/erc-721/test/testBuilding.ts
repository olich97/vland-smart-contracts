
import {ethers, waffle} from 'hardhat';
import chai from 'chai';
import chaiAsPromised  from "chai-as-promised";

import buildingArtifact from '../artifacts/contracts/Building.sol/Building.json';
import {Building} from '../typechain-types/Building';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

const {deployContract} = waffle;
chai.use(chaiAsPromised);
const {expect} = chai;

describe('Building Contract', function () {
  let contractOwner: SignerWithAddress;
  let nftOwner1: SignerWithAddress;
  let nftOwner2: SignerWithAddress;
  let contractOperator: SignerWithAddress;

  let buildingContract: Building;

  beforeEach(async () => {
    // eslint-disable-next-line no-unused-vars
    [contractOwner, nftOwner1, nftOwner2, contractOperator] = await ethers.getSigners();

    buildingContract= (await deployContract(contractOwner, buildingArtifact)) as unknown as Building;

    await buildingContract.connect(nftOwner1).setApprovalForAll(contractOperator.address, true);
  });

  describe('Deployment', function () {
    it("should set the right contract owner", async () => {
      expect(await buildingContract.owner()).to.equal(contractOwner.address);
    });
  }); 
  
  describe('Minting', function () { 
    const buildingNftGeohash = 'spyvvmnh';
    const buildingNftUrl = 'http://www.example.com/tokens/1/metadata.json';
    const buildingNftId = 1;  
    const buildingNftPrice = ethers.utils.parseEther('0.002'); 

    beforeEach(async () => {    
      expect(
        await buildingContract.connect(contractOwner).createBuilding(nftOwner1.address, buildingNftGeohash, buildingNftPrice, buildingNftUrl)
      )
      .to.emit(buildingContract, "Transfer")
      .withArgs(ethers.constants.AddressZero, nftOwner1.address, buildingNftId);
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

    it("should set price", async function () {
      const geohashPrice= await buildingContract.priceOfGeohash(buildingNftGeohash);
      expect(geohashPrice).to.equal(buildingNftPrice);
    });

    it("should fail if create with the same geohash", async function () {      
      const tokenGeohash = 'spyvvmnh'; //https://www.movable-type.co.uk/scripts/geohash.html
      const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';

      await expect(
        buildingContract.createBuilding(nftOwner1.address, tokenGeohash,buildingNftPrice, tokenMetadataUrl)
      ).to.eventually.be.rejectedWith('Geohash was already used, the building was already created');
    });
  });

  describe('Transfer', function () {    
    it("should transfer token between accounts", async function () {
      const buildingOperations = await buildingContract.connect(contractOwner);      
      await buildingOperations.createBuilding(nftOwner1.address, 'sadsa2', ethers.utils.parseEther('0.002'), 'http://www.example.com/tokens/1/metadata.json');
      const tokenId = await buildingOperations.tokenFromGeohash('sadsa2');   

      await buildingContract.connect(contractOperator)['safeTransferFrom(address,address,uint256)'](nftOwner1.address, nftOwner2.address, tokenId);
      
      // check new owner
      const newOwner = await buildingOperations.ownerOfGeohash('sadsa2');
      expect(newOwner).to.equal(nftOwner2.address);
      expect(await buildingOperations.balanceOf(nftOwner1.address)).to.be.equal(0);
    });
  });
});