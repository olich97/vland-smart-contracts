// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from 'hardhat';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  
  const contractsOwner = process.env.CONTRACTS_OWNER_ADDRESS || null;

  // 1. Deploy land contract
  const Land = await ethers.getContractFactory('Land');
  const land = await Land.deploy();
  await land.deployed();
  console.log('Land deployed to:', land.address);

  // 2. Deploy building contract
  const Building = await ethers.getContractFactory('Building');
  const building = await Building.deploy();
  await building.deployed();
  console.log('Building deployed to:', building.address);

  // 3. Set land contract as authorized building buyer
  await building.setAuthorizedBuyer(land.address, true);
  console.log('The land address %s was set as authorized buyer...', land.address);

  if(contractsOwner) {
    // 4. Transfer ownership of the contracts
    await land.transferOwnership(contractsOwner);
    await building.transferOwnership(contractsOwner);
    const newOwner = await land.owner();
    console.log('Ownership of contracts was transferred to %s', newOwner);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });