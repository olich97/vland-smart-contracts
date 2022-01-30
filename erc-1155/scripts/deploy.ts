// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  const contractsOwner = process.env.CONTRACTS_OWNER_ADDRESS || null;

  //deploy land with proxy
  const Land = await ethers.getContractFactory("Land");
  const land = await upgrades.deployProxy(Land, ["https://gateway.pinata.cloud/ipfs/QmRKAiFn57HhMqxT3hu4FPHiB7aJitygaZeX7KGbjPcped/{id}.json"]);
  await land.deployed();
  console.log("Land deployed to:", land.address);

  // deploy Building with proxy 
  const Building = await ethers.getContractFactory("Land");
  const building = await upgrades.deployProxy(Building, ["https://gateway.pinata.cloud/ipfs/QmPkRra3s54jiSENAf36hXfDkk9FDbWbbH1qih3k7jmxgG/{id}.json"]);
  await building.deployed();
  console.log("Building deployed to:", building.address);

  // approve land contract for buying operations from building
  await building.setApprovalForAll(land.address, true);
  console.log("Approved contract:", land.address);

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
