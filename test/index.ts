import { ethers } from "hardhat";

describe("Staking Hero", function () {
  it("Should deploy", async function () {
    const StakeHero = await ethers.getContractFactory("StakeHero");
    const stakeHero = await StakeHero.deploy();

    await stakeHero.deployed();
  });
});
