
import {ethers, waffle} from 'hardhat';
import chai from 'chai';

import landArtifact from '../artifacts/contracts/Land.sol/Land.json';
import {Land} from '../typechain-types/Land';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

const {deployContract} = waffle;
const {expect} = chai;

describe('Land', function () {
  let contractOwner: SignerWithAddress;
  let nftOwner1: SignerWithAddress;
  let nftOwner2: SignerWithAddress;
  let addrs: SignerWithAddress[];

  let land: Land;

  beforeEach(async () => {
    // eslint-disable-next-line no-unused-vars
    [contractOwner, nftOwner1, nftOwner2, ...addrs] = await ethers.getSigners();

    land = (await deployContract(contractOwner, landArtifact)) as unknown as Land;
  });
 
  it("Should set the right contract owner", async () => {
    expect(await land.owner()).to.equal(contractOwner.address);
  });

  it("Should correctly mint land nft", async function () {
    const landContract = await land.connect(contractOwner);
    const tokenMetadataUrl = 'http://www.example.com/tokens/1/metadata.json';
    const tokenId = 1;
    
    expect(
      await landContract.mintLand(nftOwner1.address, tokenMetadataUrl)
    )
    .to.emit(land, "Transfer")
    .withArgs(ethers.constants.AddressZero, nftOwner1.address, tokenId);
    // check nft metadata 
    const tokenUri = await landContract.tokenURI(tokenId);
    expect(tokenUri).to.equal(tokenMetadataUrl);
    // check nft owner
    const tokenOwner = await landContract.ownerOf(tokenId);
    expect(tokenOwner).to.equal(nftOwner1.address);
  });
});