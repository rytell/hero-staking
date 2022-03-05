//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "hardhat/console.sol";

contract StakeHero {
  struct HeroStatus {
    bool staked;
    uint256 lastStaked;
    uint256 lastUnstaked;
    uint256 heroId;
  }

  mapping(address => HeroStatus[]) stakedHeros;

  event StakedAHero(address who, uint256 heroNumber);

  function stake(uint256 heroNumber) public {
    HeroStatus[] storage herosOfAccount = stakedHeros[msg.sender];

    if (herosOfAccount.length > 0) {
      bool foundHero = false;
      for (uint256 index = 0; index < herosOfAccount.length; index++) {
        if (herosOfAccount[index].heroId == heroNumber) {
          require(
            herosOfAccount[index].staked == false,
            "Rytell: hero is already staked"
          );
          herosOfAccount[index].lastStaked = block.timestamp;
          herosOfAccount[index].staked = true;
          foundHero = true;
          return;
        }
      }

      if (foundHero == false) {
        stakedHeros[msg.sender].push(
          HeroStatus({
            staked: true,
            lastStaked: block.timestamp,
            lastUnstaked: 0,
            heroId: heroNumber
          })
        );
      }
    } else {
      stakedHeros[msg.sender].push(
        HeroStatus({
          staked: true,
          lastStaked: block.timestamp,
          lastUnstaked: 0,
          heroId: heroNumber
        })
      );
    }
  }
}
