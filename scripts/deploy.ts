// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ChainId } from "@rytell/sdk";
import { ethers } from "hardhat";

// eslint-disable-next-line no-unused-vars
const HEROS: { [chainId in ChainId]: string } = {
  [ChainId.FUJI]: "0x6122F8cCFC196Eb2689a740d16c451a352740194",
  [ChainId.AVALANCHE]: "0x0ca68D5768BECA6FCF444C01FE1fb6d47C019b9f",
};

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const StakeHero = await ethers.getContractFactory("StakeHero");
  const stakeHero = await StakeHero.deploy(HEROS[ChainId.FUJI]);
  await stakeHero.deployed();

  console.log("Stake Hero deployed to:", stakeHero.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
