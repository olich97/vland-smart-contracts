
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

  let building: Building;

  beforeEach(async () => {
    // eslint-disable-next-line no-unused-vars
    [contractOwner, nftOwner1, nftOwner2, contractOperator] = await ethers.getSigners();

    building = (await deployContract(contractOwner, buildingArtifact)) as unknown as Building;
    // approve operator for token transfers
    await building.connect(nftOwner1).setApprovalForAll(contractOperator.address, true);
  });

  describe('Deployment', function () {
    it("should set the right contract owner", async () => {
      expect(await building.owner()).to.equal(contractOwner.address);
    });
  });
  
  describe('Minting', function () {  
    it("should create correct nft", async function () {
      const buildingContract = await building.connect(contractOwner);
      const tokenGeohash = 'dr5revd'; //https://www.movable-type.co.uk/scripts/geohash.html
      const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';
      const tokenId = 1;
      
      expect(
        await buildingContract.createBuilding(nftOwner1.address, tokenGeohash, tokenMetadataUrl)
      )
      .to.emit(building, "Transfer")
      .withArgs(ethers.constants.AddressZero, nftOwner1.address, tokenId);

      // check nft metadata 
      const tokenUri = await buildingContract.tokenURI(tokenId);
      const geohashTokenId = await buildingContract.tokenFromGeohash(tokenGeohash);
      expect(tokenUri).to.equal(tokenMetadataUrl);
      expect(geohashTokenId).to.equal(tokenId);

      // check nft owner
      const tokenOwner = await buildingContract.ownerOf(tokenId);
      expect(tokenOwner).to.equal(nftOwner1.address);

      // check geohash owner
      const tokenGeohashOwner = await buildingContract.ownerOfGeohash(tokenGeohash);
      expect(tokenGeohashOwner).to.equal(nftOwner1.address);
    });

    it("should fail if same geohash", async function () {      
      const buildingContract = await building.connect(contractOwner);
      const tokenGeohash = 'dr5revd23'; //https://www.movable-type.co.uk/scripts/geohash.html
      const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';

      await buildingContract.createBuilding(nftOwner1.address, tokenGeohash, tokenMetadataUrl);
 
      await expect(
        buildingContract.createBuilding(nftOwner1.address, tokenGeohash, tokenMetadataUrl)
      ).to.eventually.be.rejectedWith('Geohash was already used, the building was already created');
    });
  });

  describe('Transfer', function () {    
    it("should transfer token between accounts", async function () {
      const buildingContract = await building.connect(contractOwner);      
      await buildingContract.createBuilding(nftOwner1.address, 'sadsa2', 'http://www.example.com/tokens/1/metadata.json');
      const tokenId = await buildingContract.tokenFromGeohash('sadsa2');   

      await building.connect(contractOperator)['safeTransferFrom(address,address,uint256)'](nftOwner1.address, nftOwner2.address, tokenId);
      
      // check new owner
      const newOwner = await buildingContract.ownerOfGeohash('sadsa2');
      expect(newOwner).to.equal(nftOwner2.address);
      expect(await buildingContract.balanceOf(nftOwner1.address)).to.be.equal(0);
    });
  });
});