
import {ethers, waffle} from 'hardhat';
import chai from 'chai';
import chaiAsPromised  from "chai-as-promised";

import landArtifact from '../artifacts/contracts/Land.sol/Land.json';
import {Land} from '../typechain-types/Land';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

const {deployContract} = waffle;
chai.use(chaiAsPromised);
const {expect} = chai;

describe('Land Contract', function () {
  let contractOwner: SignerWithAddress;
  let nftOwner1: SignerWithAddress;
  let nftOwner2: SignerWithAddress;
  let contractOperator: SignerWithAddress;

  let landContract: Land;

  beforeEach(async () => {
    // eslint-disable-next-line no-unused-vars
    [contractOwner, nftOwner1, nftOwner2, contractOperator] = await ethers.getSigners();

    landContract = (await deployContract(contractOwner, landArtifact)) as unknown as Land;
    // approve operator for token transfers
    await landContract.connect(nftOwner1).setApprovalForAll(contractOperator.address, true);
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

    beforeEach(async () => {    
      expect(
        await landContract.connect(contractOwner).createLand(nftOwner1.address, landNftGeohash, landNftUrl)
      )
      .to.emit(landContract, "Transfer")
      .withArgs(ethers.constants.AddressZero, nftOwner1.address, landNftId);
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

    it("should fail if create with the same geohash", async function () {      
      const tokenGeohash = 'spyvvmnh'; //https://www.movable-type.co.uk/scripts/geohash.html
      const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';

      await expect(
        landContract.createLand(nftOwner1.address, tokenGeohash, tokenMetadataUrl)
      ).to.eventually.be.rejectedWith('Geohash was already used, the land was already created');
    });
  });

  describe('Transfer', function () {    
    it("should transfer token between accounts", async function () {
      const landOperations = await landContract.connect(contractOwner);      
      await landOperations.createLand(nftOwner1.address, 'sadsa2', 'http://www.example.com/tokens/1/metadata.json');
      const tokenId = await landOperations.tokenFromGeohash('sadsa2');   

      await landContract.connect(contractOperator)['safeTransferFrom(address,address,uint256)'](nftOwner1.address, nftOwner2.address, tokenId);
      
      // check new owner
      const newOwner = await landOperations.ownerOfGeohash('sadsa2');
      expect(newOwner).to.equal(nftOwner2.address);
      expect(await landOperations.balanceOf(nftOwner1.address)).to.be.equal(0);
    });
  });
});