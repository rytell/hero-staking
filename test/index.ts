import { expect } from "chai";
import { ethers } from "hardhat";

describe("Staking Hero", function () {
  let stakeHero: any;
  let stakerAccount: any;
  let anotherStakerAccount: any;
  let heros: any;
  let herosCollectionAdmin: any;
  this.beforeEach(async function () {
    // addresses
    [herosCollectionAdmin, stakerAccount, anotherStakerAccount] =
      await ethers.getSigners();

    // deploy heros collection and mint some
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

    await heros
      .connect(anotherStakerAccount)
      .mint(4, { value: ethers.utils.parseEther("10") });

    // deploy hero staking
    const StakeHero = await ethers.getContractFactory("StakeHero");
    stakeHero = await StakeHero.deploy(heros.address);
    await stakeHero.deployed();

    // Approve for all
    await heros
      .connect(stakerAccount)
      .setApprovalForAll(stakeHero.address, true);
    await heros
      .connect(anotherStakerAccount)
      .setApprovalForAll(stakeHero.address, true);
  });

  it("Should let a person stake a couple heros", async function () {
    const mintedHeros = await heros.walletOfOwner(stakerAccount.address);
    expect(mintedHeros.length).to.be.greaterThan(0);
    await expect(stakeHero.connect(stakerAccount).stake(mintedHeros[0])).not.to
      .be.reverted;

    // Stake another hero
    await expect(stakeHero.connect(stakerAccount).stake(mintedHeros[1])).not.to
      .be.reverted;
  });

  it("After staking, the contract should be the owner of the hero", async function () {
    const mintedHeros = await heros.walletOfOwner(stakerAccount.address);
    await stakeHero.connect(stakerAccount).stake(mintedHeros[0]);
    const stakedHeros = await heros.walletOfOwner(stakeHero.address);
    expect(stakedHeros[0].toString()).to.equal(mintedHeros[0].toString());
  });

  it("A user should not be able to stake a hero they don't own", async function () {
    const mintedHeros = await heros.walletOfOwner(stakerAccount.address);
    expect(mintedHeros.length).to.be.greaterThan(0);
    await expect(
      stakeHero.connect(anotherStakerAccount).stake(mintedHeros[0])
    ).to.be.revertedWith("Rytell: you don't own this hero");
  });

  it("A user should be able to unstake and recover their hero back", async function () {
    // stake
    const mintedHeros = await heros.walletOfOwner(stakerAccount.address);
    await stakeHero.connect(stakerAccount).stake(mintedHeros[0]);

    // verify ownership
    const stakedHeros = await heros.walletOfOwner(stakeHero.address);
    expect(stakedHeros[0].toString()).to.equal(mintedHeros[0].toString());

    // unstake
    await stakeHero.connect(stakerAccount).unstake(mintedHeros[0]);

    // verify ownership
    const currentStakedHeros = await heros.walletOfOwner(stakeHero.address);
    expect(currentStakedHeros.length).to.equal(0);

    // verify last unstake date different than 0
    const stakerAccountHerosInfo = await stakeHero.getStakedHeros(
      stakerAccount.address
    );
    expect(stakerAccountHerosInfo[0].lastUnstaked.toString()).not.to.equal("0");
  });

  it("Should revert if user intends to unstake something unstaked", async function () {
    // stake
    const mintedHeros = await heros.walletOfOwner(stakerAccount.address);
    await stakeHero.connect(stakerAccount).stake(mintedHeros[0]);

    // unstake
    await stakeHero.connect(stakerAccount).unstake(mintedHeros[0]);

    // unstake again
    await expect(
      stakeHero.connect(stakerAccount).unstake(mintedHeros[0])
    ).to.be.revertedWith("Rytell: this hero is not currently staked");
  });
});
