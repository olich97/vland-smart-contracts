import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Land', function () {
  it("Should return a new land token", async function () {
    const LandFactory = await ethers.getContractFactory('Land');
    const landContract = await LandFactory.deploy();
    await landContract.deployed();

    //expect(await landContract.createLand()).to.equal('Hello, world!');

    const setGreetingTx = await landContract.mintLand('','');

    // wait until the transaction is mined
    await setGreetingTx.wait();

    //expect(await greeter.greet()).to.equal('Hola, mundo!');
  });
});