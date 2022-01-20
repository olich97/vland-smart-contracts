
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

  let land: Land;

  beforeEach(async () => {
    // eslint-disable-next-line no-unused-vars
    [contractOwner, nftOwner1, nftOwner2, contractOperator] = await ethers.getSigners();

    land = (await deployContract(contractOwner, landArtifact)) as unknown as Land;
    // approve operator for token transfers
    await land.connect(nftOwner1).setApprovalForAll(contractOperator.address, true);
  });

  describe('Deployment', function () {
    it("should set the right contract owner", async () => {
      expect(await land.owner()).to.equal(contractOwner.address);
    });
  });
  
  describe('Minting', function () {  
    it("should create correct nft", async function () {
      const landContract = await land.connect(contractOwner);
      const tokenGeohash = 'dr5revd'; //https://www.movable-type.co.uk/scripts/geohash.html
      const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';
      const tokenId = 1;
      
      expect(
        await landContract.mintLand(nftOwner1.address, tokenGeohash, tokenMetadataUrl)
      )
      .to.emit(land, "Transfer")
      .withArgs(ethers.constants.AddressZero, nftOwner1.address, tokenId);

      // check nft metadata 
      const tokenUri = await landContract.tokenURI(tokenId);
      const geohashTokenId = await landContract.tokenFromGeohash(tokenGeohash);
      expect(tokenUri).to.equal(tokenMetadataUrl);
      expect(geohashTokenId).to.equal(tokenId);

      // check nft owner
      const tokenOwner = await landContract.ownerOf(tokenId);
      expect(tokenOwner).to.equal(nftOwner1.address);

      // check geohash owner
      const tokenGeohashOwner = await landContract.ownerOfGeohash(tokenGeohash);
      expect(tokenGeohashOwner).to.equal(nftOwner1.address);
    });

    it("should fail if same geohash", async function () {      
      const landContract = await land.connect(contractOwner);
      const tokenGeohash = 'dr5revd23'; //https://www.movable-type.co.uk/scripts/geohash.html
      const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';

      await landContract.mintLand(nftOwner1.address, tokenGeohash, tokenMetadataUrl);
 
      await expect(
        landContract.mintLand(nftOwner1.address, tokenGeohash, tokenMetadataUrl)
      ).to.eventually.be.rejectedWith('Geohash was already used, the land was already minted');
    });
  });

  describe('Transfer', function () {    
    it("should transfer token between accounts", async function () {
      const landContract = await land.connect(contractOwner);      
      await landContract.mintLand(nftOwner1.address, 'sadsa2', 'http://www.example.com/tokens/1/metadata.json');
      const tokenId = await landContract.tokenFromGeohash('sadsa2');   

      await land.connect(contractOperator)['safeTransferFrom(address,address,uint256)'](nftOwner1.address, nftOwner2.address, tokenId);
      
      // check new owner
      const newOwner = await landContract.ownerOfGeohash('sadsa2');
      expect(newOwner).to.equal(nftOwner2.address);
      expect(await landContract.balanceOf(nftOwner1.address)).to.be.equal(0);
    });
  });
});