
import {ethers, waffle, upgrades} from 'hardhat';
import chai from 'chai';
import chaiAsPromised  from "chai-as-promised";
import { Contract } from 'ethers';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import {
    Land__factory,
    Land,
    Building__factory,
    Building,
  } from "../typechain-types";

const {deployContract} = waffle;
chai.use(chaiAsPromised);
const {expect} = chai;

describe('Building Contract', function () {
  let contractOwner: SignerWithAddress;
  let nftOwner1: SignerWithAddress;
  let nftOwner2: SignerWithAddress;
  let nftBuyer: SignerWithAddress;
  let Building: Building;
  let Land: Land;
  let landContractAddress: string;

  beforeEach(async () => {
    [contractOwner, nftOwner1, nftOwner2, nftBuyer] = await ethers.getSigners();

    const landFactory = (await ethers.getContractFactory(
      "Land",
      contractOwner
    )) as Land__factory;
    Land = (await upgrades.deployProxy(landFactory, ['landNftUrl'], {
      initializer: "initialize",
    })) as Land;
    landContractAddress = (await Land.deployed()).address;

    const buildingFactory = (await ethers.getContractFactory(
        "Building",
        contractOwner
      )) as Building__factory;
      Building = (await upgrades.deployProxy(buildingFactory, ['buildingNftUrl'], {
        initializer: "initialize",
      })) as Building;
      await Building.deployed();
  });


  describe('Deployment', function () {
    it("should set the right contract owner", async () => {
      expect(await Land.owner()).to.equal(contractOwner.address);
      expect(await Building.owner()).to.equal(contractOwner.address);
    });
  });
});