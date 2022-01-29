import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {
  Land__factory,
  Land,
  LandV2,
} from "../typechain-types";


describe("Upgradeable", () => {
    let Land: Land;
    let LandV2: LandV2;
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addr2: SignerWithAddress;
    let addrs: SignerWithAddress[];
  
    const provider = ethers.provider;
    const landGeohash = "mygeohash";
  
    beforeEach(async () => {
      [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
  
      const BaseFactory = (await ethers.getContractFactory(
        "Land",
        owner
      )) as Land__factory;
      Land = (await upgrades.deployProxy(BaseFactory, ['my.first.uri'], {
        initializer: "initialize",
      })) as Land;
      await Land.deployed();

      await Land.createLand(addr1.address, landGeohash, ethers.utils.parseEther('0.02'));
    });
  
    it("Should execute a new function once the contract is upgraded", async () => {
      const upgradeableV2Factory = await ethers.getContractFactory(
        "LandV2",
        owner
      );
  
      await upgrades.upgradeProxy(Land.address, upgradeableV2Factory);
      LandV2 = upgradeableV2Factory.attach(
        Land.address
      ) as LandV2;
      expect(await LandV2.greet()).to.eq("Hello MasterZ");
    });
  
    it("Should get the same stored values after the contract is upgraded", async () => {
      const initialTokenUri = 'my.new.token.cool.uri';
      await Land.setURI(initialTokenUri);
      expect(await Land.geohashUri(landGeohash)).to.equal(initialTokenUri);
      const upgradeableV2Factory = await ethers.getContractFactory(
        "LandV2",
        owner
      );
  
      await upgrades.upgradeProxy(Land.address, upgradeableV2Factory);
      LandV2 = upgradeableV2Factory.attach(
        Land.address
      ) as LandV2;
      expect(await Land.owner()).to.equal(owner.address);
      expect(await Land.geohashUri(landGeohash)).to.equal(initialTokenUri);
    });
  });