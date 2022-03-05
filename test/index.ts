import { expect } from "chai";
import { ethers } from "hardhat";

describe("Staking Hero", function () {
  let stakeHero: any;
  let stakerAccount: any;
  let anotherStakerAccount: any;
  let heros: any;
  let herosCollectionAdmin: any;
  this.beforeEach(async function () {
    [herosCollectionAdmin, stakerAccount, anotherStakerAccount] =
      await ethers.getSigners();
    const StakeHero = await ethers.getContractFactory("StakeHero");
    stakeHero = await StakeHero.deploy();
    await stakeHero.deployed();

    const Heros = await ethers.getContractFactory("Rytell");
    heros = await Heros.deploy(
      "ipfs://QmXHJfoMaDiRuzgkVSMkEsMgQNAtSKr13rtw5s59QoHJAm/",
      "ipfs://Qmdg8GAFvo2BFNiXA3oCTH34cLojQUrbLL6yGYZHaKFSHm/hidden.json",
      herosCollectionAdmin.address
    );
    await heros.deployed();
    await heros.pause(false);
    await heros.reveal();
    await heros
      .connect(stakerAccount)
      .mint(6, { value: ethers.utils.parseEther("15") });
  });

  it("Should let a person stake a couple heros", async function () {
    const mintedHeros = await heros.walletOfOwner(stakerAccount.address);
    expect(mintedHeros.length).to.be.greaterThan(0);
    await expect(stakeHero.connect(stakerAccount).stake(mintedHeros[0])).not.to
      .be.reverted;
    await expect(
      stakeHero.connect(stakerAccount).stake(mintedHeros[0])
    ).to.be.revertedWith("Rytell: hero is already staked");
    await expect(stakeHero.connect(stakerAccount).stake(mintedHeros[1])).not.to
      .be.reverted;
  });

  it("A user should not be able to stake a hero they dont own", async function () {
    const mintedHeros = await heros.walletOfOwner(stakerAccount.address);
    expect(mintedHeros.length).to.be.greaterThan(0);
    await expect(stakeHero.connect(anotherStakerAccount).stake(mintedHeros[0]))
      .to.be.reverted;
  });
});
